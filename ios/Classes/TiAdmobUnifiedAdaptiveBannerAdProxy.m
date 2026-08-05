/**
 * ti.admob.unified - Adaptive Banner Ad Proxy implementation (iOS)
 *
 * Mirrors the Banner Proxy but uses GADLargeAnchoredAdaptiveBannerAdSizeWithWidth
 * for dynamic full-width sizing. Paridad with Android's
 * TiAdmobUnifiedAdaptiveBannerAdProxy (getLargeAnchoredAdaptiveBannerAdSize).
 *
 * Copyright (c) 2025 César Estrada
 *
 */

#import "TiAdmobUnifiedAdaptiveBannerAdProxy.h"
#import "TiApp.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiViewProxy.h"
#import "TiUIView.h"

@interface TiAdmobUnifiedAdaptiveBannerAdView : TiUIView
{
    GADBannerView *bannerView;
    BOOL isAdLoaded;
    BOOL isLoading;
    BOOL isPaused;
    BOOL isDestroyed;
    BOOL pendingLoad;
}

@property (nonatomic, weak) TiAdmobUnifiedAdaptiveBannerAdProxy *proxy;

- (void)createBannerView;
- (void)loadAd;
- (void)destroyAd;
- (void)pauseAd;
- (void)resumeAd;
- (BOOL)isAdLoaded;
- (void)adDidLoad;
- (void)adDidFailToLoad;
- (void)setAdUnitId:(NSString *)adUnitId;

@end

@interface TiAdmobUnifiedAdaptiveBannerAdProxy ()
@property (nonatomic, assign) BOOL pendingLoad;
// Two independent pause causes. The application pauses a placement it owns but
// no longer shows; the application lifecycle pauses everything while the app is
// in the background. Either one holds the banner paused, so neither may resume
// the other's. `isPaused` stays readable as the combined state.
@property (nonatomic, assign) BOOL pausedByApp;
@property (nonatomic, assign) BOOL pausedByLifecycle;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) BOOL destroyedEventFired;
@property (nonatomic, assign) BOOL lifecycleObserved;
- (BOOL)isPaused;
@end

@implementation TiAdmobUnifiedAdaptiveBannerAdProxy

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        // Same defaults as the Android view: anchored, and 50 for inline.
        // Assign the ivars directly; property setters reach [self view], which
        // is not wired yet during init.
        _adaptiveType = @"adaptive_anchored";
        _maxHeight = 50;
        [self startObservingLifecycle];
    }
    return self;
}

- (BOOL)isInlineAdaptive
{
    return [self.adaptiveType isEqualToString:@"adaptive_inline"];
}

- (void)_initWithProperties:(NSDictionary *)properties
{
    [super _initWithProperties:properties];
}

- (void)dealloc
{
    [self stopObservingLifecycle];
    DebugLog(@"[DEBUG] AdaptiveBanner proxy deallocated");
}

#pragma mark - Application lifecycle

// Android pauses every banner its activity hosts. iOS has no equivalent hook,
// so the proxy observes the application itself and both platforms behave alike.
//
// These are background/foreground rather than resign/become-active on purpose:
// a Control Center pull or an incoming-call banner resigns active while the ad
// is still on screen and still viewable. Pausing there would blank a visible
// banner for a transient interruption.
- (void)startObservingLifecycle
{
    if (self.lifecycleObserved) {
        return;
    }
    self.lifecycleObserved = YES;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(applicationWillEnterForeground:)
                   name:UIApplicationWillEnterForegroundNotification
                 object:nil];
}

- (void)stopObservingLifecycle
{
    if (!self.lifecycleObserved) {
        return;
    }
    self.lifecycleObserved = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    if (self.isDestroyed || self.pausedByLifecycle) {
        return;
    }
    self.pausedByLifecycle = YES;
    DebugLog(@"[DEBUG] Application backgrounded, pausing adaptive banner");
    [self applyPause];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    if (self.isDestroyed || !self.pausedByLifecycle) {
        return;
    }
    self.pausedByLifecycle = NO;
    DebugLog(@"[DEBUG] Application foregrounded, resuming adaptive banner");
    [self applyResume];
}

- (void)windowWillClose
{
    [self destroy:nil];
    [super windowWillClose];
}

- (void)viewWillDetach
{
    [self destroy:nil];
    [super viewWillDetach];
}

- (void)_destroy
{
    [self destroy:nil];
    [super _destroy];
}

#pragma mark - TiViewProxy override (newView, NOT createView — TitaniumKit 13.x)

- (TiUIView *)newView
{
    TiAdmobUnifiedAdaptiveBannerAdView *v = [[TiAdmobUnifiedAdaptiveBannerAdView alloc] init];
    v.proxy = self;
    if (self.isDestroyed) {
        [v destroyAd];
        return v;
    }
    [v createBannerView];
    if (self.isPaused) {
        [v pauseAd];
    }
    if (self.pendingLoad) {
        self.pendingLoad = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isDestroyed && !self.isPaused) {
                [v loadAd];
            } else if (!self.isDestroyed) {
                self.pendingLoad = YES;
            }
        });
    }
    return v;
}

#pragma mark - Public Methods

- (void)load:(id)args
{
    if (self.isDestroyed) {
        [self fireAdEvent:@"failed_to_load"
                 withData:@{
                     @"error": @"Banner has been destroyed",
                     @"code": @(1)
                 }];
        return;
    }
    if (self.isPaused) {
        self.pendingLoad = YES;
        return;
    }

    TiThreadPerformOnMainThread(^{
        TiUIView *tiView = [self view];
        if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
            [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView loadAd];
        } else {
            self.pendingLoad = YES;
        }
    }, NO);
}

- (void)destroy:(id)args
{
    if (self.isDestroyed) {
        return;
    }
    self.isDestroyed = YES;
    self.pendingLoad = NO;
    [self stopObservingLifecycle];

    TiThreadPerformOnMainThread(^{
        if ([self viewInitialized]) {
            TiUIView *tiView = [self view];
            if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
                [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView destroyAd];
            }
        }
    }, YES);

    if (!self.destroyedEventFired) {
        self.destroyedEventFired = YES;
        [self fireAdEvent:@"destroyed" withData:nil];
    }
}

- (BOOL)isPaused
{
    return self.pausedByApp || self.pausedByLifecycle;
}

- (void)pause:(id)args
{
    if (self.isDestroyed || self.pausedByApp) {
        return;
    }
    self.pausedByApp = YES;
    [self applyPause];
}

- (void)resume:(id)args
{
    if (self.isDestroyed || !self.pausedByApp) {
        return;
    }
    self.pausedByApp = NO;
    [self applyResume];
}

- (void)applyPause
{
    TiThreadPerformOnMainThread(^{
        if ([self viewInitialized]) {
            TiUIView *tiView = [self view];
            if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
                [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView pauseAd];
            }
        }
    }, NO);
}

// Resumes only once every pause cause is gone. A banner the application paused
// stays paused while the app returns from the background, and vice versa, so a
// deferred load never fires into a placement nobody is looking at.
- (void)applyResume
{
    if (self.isDestroyed || self.isPaused) {
        return;
    }

    TiThreadPerformOnMainThread(^{
        if ([self viewInitialized]) {
            TiUIView *tiView = [self view];
            if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
                [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView resumeAd];
            }
        }
        if (self.pendingLoad) {
            self.pendingLoad = NO;
            [self load:nil];
        }
    }, NO);
}

- (NSNumber *)isLoaded:(id)args
{
    if (self.isDestroyed || ![self viewInitialized]) {
        return @(NO);
    }

    __block BOOL loaded = NO;
    TiThreadPerformOnMainThread(^{
        TiUIView *tiView = [self view];
        if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
            loaded = [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView isAdLoaded];
        }
    }, YES);
    return @(loaded);
}

- (void)destroyAdViewAndCancelRequest:(id)args
{
    [self destroy:args];
}

- (void)destoyAdViewAndCancelRequest:(id)args
{
    NSLog(@"[WARN] destoyAdViewAndCancelRequest() is deprecated; use destroyAdViewAndCancelRequest() or destroy()");
    [self destroy:args];
}

#pragma mark - Property Setters (ivar-only, no view forwarding to avoid init deadlock)

- (void)setAdUnitId:(NSString *)adUnitId
{
    _adUnitId = adUnitId;
}

#pragma mark - GADBannerViewDelegate

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView
{
    if (self.isDestroyed) {
        return;
    }
    TiUIView *tiView = [self view];
    if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
        [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView adDidLoad];
        dispatch_async(dispatch_get_main_queue(), ^{
            [tiView setNeedsLayout];
            [tiView layoutIfNeeded];
        });
    }
    [self fireAdEvent:@"loaded" withData:@{
        @"adUnitId": self.adUnitId ?: @"",
        @"height": @(bannerView.adSize.size.height),
        @"heightUnit": @"dp"
    }];
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error
{
    if (self.isDestroyed) {
        return;
    }
    NSLog(@"[ERROR] Adaptive banner failed to load: %@", error.localizedDescription);
    if ([self viewInitialized]) {
        TiUIView *tiView = [self view];
        if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
            [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView adDidFailToLoad];
        }
    }
    [self fireAdEvent:@"failed_to_load"
             withData:@{@"error": error.localizedDescription,
                        @"code": @(error.code),
                        @"adUnitId": self.adUnitId ?: @""}];
}

- (void)bannerViewDidRecordImpression:(GADBannerView *)bannerView
{
    [self fireAdEvent:@"impression" withData:@{@"adUnitId": self.adUnitId ?: @""}];
}

- (void)bannerViewDidRecordClick:(GADBannerView *)bannerView
{
    [self fireAdEvent:@"clicked" withData:@{@"adUnitId": self.adUnitId ?: @""}];
}

- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView
{
    [self fireAdEvent:@"opened" withData:@{@"adUnitId": self.adUnitId ?: @""}];
}

- (void)bannerViewDidDismissScreen:(GADBannerView *)bannerView
{
    [self fireAdEvent:@"closed" withData:@{@"adUnitId": self.adUnitId ?: @""}];
}

#pragma mark - Internal

- (void)fireAdEvent:(NSString *)eventName withData:(NSDictionary *)data
{
    NSMutableDictionary *payload = [@{
        @"adUnitId": self.adUnitId ?: @"",
        @"adType": @"banner",
        @"isAdaptive": @YES,
        // The constant the caller passed, not a shortened label. Android already
        // echoed the constant back, so comparing against ADAPTIVE_ANCHORED now
        // works the same on both platforms.
        @"adaptiveType": [self isInlineAdaptive] ? @"adaptive_inline" : @"adaptive_anchored"
    } mutableCopy];
    if (data != nil) {
        [payload addEntriesFromDictionary:data];
    }
    if ([self _hasListeners:eventName]) {
        [self fireEvent:eventName withObject:payload];
    }
}

@end

#pragma mark - Adaptive Banner Ad View Implementation

@implementation TiAdmobUnifiedAdaptiveBannerAdView

- (id)init
{
    if (self = [super init]) {
        isAdLoaded = NO;
        isLoading = NO;
        isPaused = NO;
        isDestroyed = NO;
        pendingLoad = NO;
    }
    return self;
}

- (void)dealloc
{
    [self destroyAd];
}

- (void)createBannerView
{
    if (isDestroyed || bannerView != nil) {
        return;
    }
    if (!self.proxy.adUnitId) {
        NSLog(@"[ERROR] Cannot create adaptive banner view - no adUnitId");
        return;
    }

    // GADBannerView is created with a placeholder size; the actual adaptive size
    // is set in loadAd just before the ad request, when we know the on-screen width.
    bannerView = [[GADBannerView alloc] initWithAdSize:GADAdSizeBanner];
    bannerView.adUnitID = self.proxy.adUnitId;
    bannerView.delegate = self.proxy;

    UIViewController *rootViewController = [TiApp app].controller;
    if (rootViewController) {
        bannerView.rootViewController = rootViewController;
    }

    [self addSubview:bannerView];
    bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [bannerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [bannerView.topAnchor constraintEqualToAnchor:self.topAnchor]
    ]];
}

- (void)loadAd
{
    if (isDestroyed) {
        return;
    }
    if (isPaused) {
        pendingLoad = YES;
        return;
    }
    if (isLoading) {
        DebugLog(@"[DEBUG] Adaptive banner load ignored; a request is already active");
        return;
    }
    if (!bannerView) {
        NSLog(@"[ERROR] Adaptive banner view not initialized");
        [self.proxy fireAdEvent:@"failed_to_load"
                      withData:@{
                          @"error": @"Banner view is not initialized",
                          @"code": @(1)
                      }];
        return;
    }

    // Compute current container width in points. Fall back to screen width if
    // self.bounds hasn't been laid out yet.
    CGFloat width = self.bounds.size.width;
    if (width <= 0.0) {
        width = [UIScreen mainScreen].bounds.size.width;
    }

    // Anchored sits at a screen edge and Google fixes its height. Inline scrolls
    // with the content and the app caps it, which is why only inline reads
    // maxHeight — same split as AdSize.getInlineAdaptiveBannerAdSize on Android.
    GADAdSize adaptiveSize;
    if ([self.proxy isInlineAdaptive]) {
        CGFloat maxHeight = (CGFloat)self.proxy.maxHeight;
        if (maxHeight <= 0) {
            maxHeight = 50;
        }
        adaptiveSize = GADInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(width, maxHeight);
        DebugLog(@"[DEBUG] Creating inline adaptive banner with max height: %.0f", maxHeight);
    } else {
        // Large, not plain: Google deprecated the plain anchored functions.
        adaptiveSize = GADLargeAnchoredAdaptiveBannerAdSizeWithWidth(width);
    }
    bannerView.adSize = adaptiveSize;

    // Targeting is part of the placement contract, not of the banner type: the
    // Android adaptive view already forwarded all three, and this one sent a
    // bare request, so the same JavaScript produced differently targeted ads.
    GADRequest *request = [GADRequest request];

    if (self.proxy.keywords && [self.proxy.keywords count] > 0) {
        request.keywords = self.proxy.keywords;
        DebugLog(@"[DEBUG] Added keywords: %@", self.proxy.keywords);
    }

    if (self.proxy.contentUrl && [self.proxy.contentUrl length] > 0) {
        request.contentURL = self.proxy.contentUrl;
        DebugLog(@"[DEBUG] Set content URL: %@", self.proxy.contentUrl);
    }

    if (self.proxy.requestAgent && [self.proxy.requestAgent length] > 0) {
        request.requestAgent = self.proxy.requestAgent;
    }

    if (self.proxy.extras) {
        GADExtras *extras = [[GADExtras alloc] init];
        extras.additionalParameters = self.proxy.extras;
        [request registerAdNetworkExtras:extras];
    }

    isLoading = YES;
    isAdLoaded = NO;
    [bannerView loadRequest:request];
    DebugLog(@"[DEBUG] Adaptive banner load request sent (width=%.0f)", width);
}

- (void)destroyAd
{
    if (isDestroyed) {
        return;
    }
    isDestroyed = YES;
    pendingLoad = NO;
    isLoading = NO;
    isAdLoaded = NO;
    if (bannerView) {
        bannerView.delegate = nil;
        bannerView.adSizeDelegate = nil;
        bannerView.rootViewController = nil;
        bannerView.paidEventHandler = nil;
        bannerView.autoloadEnabled = NO;
        [bannerView removeFromSuperview];
        bannerView = nil;
    }
}

- (void)pauseAd
{
    if (isDestroyed || isPaused) {
        return;
    }
    isPaused = YES;
    bannerView.hidden = YES;
    bannerView.autoloadEnabled = NO;
}

- (void)resumeAd
{
    if (isDestroyed || !isPaused) {
        return;
    }
    isPaused = NO;
    bannerView.hidden = NO;
    if (pendingLoad) {
        pendingLoad = NO;
        [self loadAd];
    }
}

- (BOOL)isAdLoaded
{
    return isAdLoaded;
}

- (void)adDidLoad
{
    if (!isDestroyed) {
        isLoading = NO;
        isAdLoaded = YES;
        bannerView.hidden = isPaused;
    }
}

- (void)adDidFailToLoad
{
    if (!isDestroyed) {
        isLoading = NO;
        isAdLoaded = NO;
    }
}

- (void)setAdUnitId:(NSString *)adUnitId
{
    if (bannerView && ![bannerView.adUnitID isEqualToString:adUnitId]) {
        bannerView.adUnitID = adUnitId;
    }
}

@end

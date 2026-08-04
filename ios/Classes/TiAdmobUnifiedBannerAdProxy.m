/**
 * ti.admob.unified - Unified AdMob Banner Ad Proxy for iOS
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "TiAdmobUnifiedBannerAdProxy.h"
#import "TiApp.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiViewProxy.h"
#import "TiUIView.h"

@interface TiAdmobUnifiedBannerAdView : TiUIView
{
    GADBannerView *bannerView;
    BOOL isAdLoaded;
    BOOL isLoading;
    BOOL isPaused;
    BOOL isDestroyed;
    BOOL pendingLoad;
}

@property (nonatomic, weak) TiAdmobUnifiedBannerAdProxy *proxy;

- (void)createBannerView;
- (void)loadAd;
- (void)destroyAd;
- (void)pauseAd;
- (void)resumeAd;
- (BOOL)isAdLoaded;
- (void)adDidLoad;
- (void)adDidFailToLoad;
- (void)setAdUnitId:(NSString *)adUnitId;
- (void)setAdSize:(NSString *)adSize;

@end

@interface TiAdmobUnifiedBannerAdProxy ()
// Set when load() is called before the view exists; newView will fire loadAd once ready.
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

@implementation TiAdmobUnifiedBannerAdProxy

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        _adSize = @"banner";
        [self startObservingLifecycle];
        DebugLog(@"[DEBUG] Banner ad proxy initialized");
    }
    return self;
}

- (void)_initWithProperties:(NSDictionary *)properties
{
    // Real TiProxy lifecycle hook (configurationSet does not exist in TitaniumKit 13.2).
    // super fires the property setters via KVC.
    [super _initWithProperties:properties];
    DebugLog(@"[DEBUG] Banner ad proxy configured with adUnitId: %@, adSize: %@", self.adUnitId, self.adSize);
}

- (void)dealloc
{
    [self stopObservingLifecycle];
    DebugLog(@"[DEBUG] Banner ad proxy deallocated");
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
    DebugLog(@"[DEBUG] Application backgrounded, pausing banner");
    [self applyPause];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    if (self.isDestroyed || !self.pausedByLifecycle) {
        return;
    }
    self.pausedByLifecycle = NO;
    DebugLog(@"[DEBUG] Application foregrounded, resuming banner");
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

#pragma mark - TiViewProxy overrides

- (TiUIView *)newView
{
    DebugLog(@"[DEBUG] Creating banner view (adUnitId: %@, adSize: %@)", self.adUnitId, self.adSize);
    TiAdmobUnifiedBannerAdView *bannerAdView = [[TiAdmobUnifiedBannerAdView alloc] init];
    bannerAdView.proxy = self;
    if (self.isDestroyed) {
        [bannerAdView destroyAd];
        return bannerAdView;
    }
    // createBannerView must run here, not in the view's init, where proxy is still nil.
    [bannerAdView createBannerView];
    if (self.isPaused) {
        [bannerAdView pauseAd];
    }
    if (self.pendingLoad) {
        self.pendingLoad = NO;
        DebugLog(@"[DEBUG] Firing deferred banner load");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isDestroyed && !self.isPaused) {
                [bannerAdView loadAd];
            } else if (!self.isDestroyed) {
                self.pendingLoad = YES;
            }
        });
    }
    return bannerAdView;
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

    DebugLog(@"[DEBUG] Loading banner ad (adUnitId: %@)", self.adUnitId);
    TiThreadPerformOnMainThread(^{
        TiUIView *tiView = [self view];
        if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
            [(TiAdmobUnifiedBannerAdView *)tiView loadAd];
        } else {
            self.pendingLoad = YES;
            DebugLog(@"[DEBUG] Banner view not ready, deferring load");
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
    DebugLog(@"[DEBUG] Destroying banner ad");

    TiThreadPerformOnMainThread(^{
        if ([self viewInitialized]) {
            TiUIView *tiView = [self view];
            if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
                [(TiAdmobUnifiedBannerAdView *)tiView destroyAd];
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
    DebugLog(@"[DEBUG] Pausing banner ad");
    [self applyPause];
}

- (void)resume:(id)args
{
    if (self.isDestroyed || !self.pausedByApp) {
        return;
    }
    self.pausedByApp = NO;
    DebugLog(@"[DEBUG] Resuming banner ad");
    [self applyResume];
}

- (void)applyPause
{
    TiThreadPerformOnMainThread(^{
        if ([self viewInitialized]) {
            TiUIView *tiView = [self view];
            if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
                [(TiAdmobUnifiedBannerAdView *)tiView pauseAd];
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
            if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
                [(TiAdmobUnifiedBannerAdView *)tiView resumeAd];
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
        if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
            loaded = [(TiAdmobUnifiedBannerAdView *)tiView isAdLoaded];
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

#pragma mark - Property Setters

- (void)setAdUnitId:(NSString *)adUnitId
{
    // Just store the ivar — do NOT call [self view] from a setter that may fire
    // during _initWithProperties:. Doing so caused a hang in the alloc/init chain
    // (TiViewProxy [self view] dispatch_sync to main thread deadlocking against the
    // Kroll-thread setter invocation).
    // The view, when it is created via newView, reads self.proxy.adUnitId.
    _adUnitId = adUnitId;
    DebugLog(@"[DEBUG] AdUnit ID set to: %@", adUnitId);
}

- (void)setAdSize:(NSString *)adSize
{
    _adSize = adSize;
    DebugLog(@"[DEBUG] Ad size set to: %@", adSize);
}

#pragma mark - GADBannerViewDelegate

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Banner ad loaded successfully");
    
    // Force layout refresh to make banner visible
    TiUIView *tiView = [self view];
    if (tiView && [tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
        TiAdmobUnifiedBannerAdView *bannerAdView = (TiAdmobUnifiedBannerAdView *)tiView;
        [bannerAdView adDidLoad];
        dispatch_async(dispatch_get_main_queue(), ^{
            [bannerAdView setNeedsLayout];
            [bannerAdView layoutIfNeeded];
        });
    }
    
    NSDictionary *event = @{
        @"adUnitId": self.adUnitId ?: @""
    };
    [self fireAdEvent:@"loaded" withData:event];
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error
{
    if (self.isDestroyed) {
        return;
    }
    NSLog(@"[ERROR] Banner ad failed to load: %@ (code: %ld)", error.localizedDescription, (long)error.code);

    if ([self viewInitialized]) {
        TiUIView *tiView = [self view];
        if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
            [(TiAdmobUnifiedBannerAdView *)tiView adDidFailToLoad];
        }
    }
    
    NSDictionary *event = @{
        @"error": error.localizedDescription,
        @"code": @(error.code),
        @"adUnitId": self.adUnitId ?: @""
    };
    [self fireAdEvent:@"failed_to_load" withData:event];
}

- (void)bannerViewDidRecordImpression:(GADBannerView *)bannerView
{
    DebugLog(@"[DEBUG] Banner ad impression");
    
    NSDictionary *event = @{
        @"adUnitId": self.adUnitId ?: @""
    };
    [self fireAdEvent:@"impression" withData:event];
}

- (void)bannerViewDidRecordClick:(GADBannerView *)bannerView
{
    DebugLog(@"[DEBUG] Banner ad clicked");
    
    NSDictionary *event = @{
        @"adUnitId": self.adUnitId ?: @""
    };
    [self fireAdEvent:@"clicked" withData:event];
}

- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView
{
    DebugLog(@"[DEBUG] Banner ad opened");
    
    NSDictionary *event = @{
        @"adUnitId": self.adUnitId ?: @""
    };
    [self fireAdEvent:@"opened" withData:event];
}

- (void)bannerViewWillDismissScreen:(GADBannerView *)bannerView
{
    DebugLog(@"[DEBUG] Banner ad will dismiss");
}

- (void)bannerViewDidDismissScreen:(GADBannerView *)bannerView
{
    DebugLog(@"[DEBUG] Banner ad closed");
    
    NSDictionary *event = @{
        @"adUnitId": self.adUnitId ?: @""
    };
    [self fireAdEvent:@"closed" withData:event];
}

#pragma mark - Internal Methods

- (void)fireAdEvent:(NSString *)eventName withData:(NSDictionary *)data
{
    NSMutableDictionary *payload = [@{
        @"adUnitId": self.adUnitId ?: @"",
        @"adType": @"banner",
        @"isAdaptive": @NO
    } mutableCopy];
    if (data != nil) {
        [payload addEntriesFromDictionary:data];
    }
    if ([self _hasListeners:eventName]) {
        [self fireEvent:eventName withObject:payload];
    }
}

+ (GADAdSize)getAdSizeFromString:(NSString *)sizeString
{
    if (!sizeString) {
        return GADAdSizeBanner;
    }
    
    NSString *lowerSize = [sizeString lowercaseString];
    
    if ([lowerSize isEqualToString:@"banner"]) {
        return GADAdSizeBanner;
    } else if ([lowerSize isEqualToString:@"large_banner"]) {
        return GADAdSizeLargeBanner;
    } else if ([lowerSize isEqualToString:@"medium_rectangle"]) {
        return GADAdSizeMediumRectangle;
    } else if ([lowerSize isEqualToString:@"fullbanner"]) {
        return GADAdSizeFullBanner;
    } else if ([lowerSize isEqualToString:@"leaderboard"]) {
        return GADAdSizeLeaderboard;
    } else if ([lowerSize isEqualToString:@"smart_banner"]) {
        return kGADAdSizeSmartBannerPortrait; // Default to portrait
    } else {
        NSLog(@"[WARN] Unknown ad size: %@, using default BANNER", sizeString);
        return GADAdSizeBanner;
    }
}

@end

#pragma mark - Banner Ad View Implementation

@implementation TiAdmobUnifiedBannerAdView

- (id)init
{
    if (self = [super init]) {
        isAdLoaded = NO;
        isLoading = NO;
        isPaused = NO;
        isDestroyed = NO;
        pendingLoad = NO;
        DebugLog(@"[DEBUG] Banner ad view initialized");
        // createBannerView NOT called here — self.proxy is nil at init time.
        // The proxy calls createBannerView from its own newView after wiring proxy.
    }
    return self;
}

- (void)dealloc
{
    [self destroyAd];
    DebugLog(@"[DEBUG] Banner ad view deallocated");
}

- (void)createBannerView
{
    if (isDestroyed || bannerView != nil) {
        return;
    }
    DebugLog(@"[DEBUG] Creating GADBannerView (adUnitId: %@)", self.proxy.adUnitId);
    if (!self.proxy.adUnitId) {
        NSLog(@"[ERROR] Cannot create banner view - no ad unit ID specified");
        return;
    }
    
    GADAdSize adSize = [TiAdmobUnifiedBannerAdProxy getAdSizeFromString:self.proxy.adSize];
    
    bannerView = [[GADBannerView alloc] initWithAdSize:adSize];
    bannerView.adUnitID = self.proxy.adUnitId;
    bannerView.delegate = self.proxy;
    
    // Set root view controller
    UIViewController *rootViewController = [TiApp app].controller;
    if (rootViewController) {
        bannerView.rootViewController = rootViewController;
    }
    
    [self addSubview:bannerView];
    
    // Set up constraints to center the banner
    bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [bannerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [bannerView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
    
    DebugLog(@"[DEBUG] Banner view created with ad unit: %@", self.proxy.adUnitId);
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
        DebugLog(@"[DEBUG] Banner load ignored; a request is already active");
        return;
    }
    if (!bannerView) {
        NSLog(@"[ERROR] Cannot load ad - banner view not initialized");
        [self.proxy fireAdEvent:@"failed_to_load"
                      withData:@{
                          @"error": @"Banner view is not initialized",
                          @"code": @(1)
                      }];
        return;
    }
    
    GADRequest *request = [GADRequest request];
    
    // Add keywords if specified
    if (self.proxy.keywords && [self.proxy.keywords count] > 0) {
        // Note: Keywords are not directly supported in GADRequest in newer versions
        // They should be handled through targeting or custom parameters if needed
        DebugLog(@"[DEBUG] Keywords specified but not applied (not supported in current GAD version)");
    }
    
    isLoading = YES;
    isAdLoaded = NO;
    [bannerView loadRequest:request];
    DebugLog(@"[DEBUG] Ad request sent for banner ad: %@", bannerView.adUnitID);
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
        DebugLog(@"[DEBUG] Banner ad destroyed");
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
    DebugLog(@"[DEBUG] Banner paused");
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
    DebugLog(@"[DEBUG] Banner resumed");
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
        DebugLog(@"[DEBUG] Banner view ad unit ID updated to: %@", adUnitId);
    }
}

- (void)setAdSize:(NSString *)adSize
{
    if (bannerView) {
        GADAdSize newAdSize = [TiAdmobUnifiedBannerAdProxy getAdSizeFromString:adSize];
        // Note: Changing ad size on existing banner view requires recreating it
        // For now, we'll log a warning
        NSLog(@"[WARN] Changing ad size on existing banner view not supported. Recreate the banner instead.");
    }
}

@end

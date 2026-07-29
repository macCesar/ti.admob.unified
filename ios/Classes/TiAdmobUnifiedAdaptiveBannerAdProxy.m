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
@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) BOOL destroyedEventFired;
@end

@implementation TiAdmobUnifiedAdaptiveBannerAdProxy

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    return self;
}

- (void)_initWithProperties:(NSDictionary *)properties
{
    [super _initWithProperties:properties];
}

- (void)dealloc
{
    DebugLog(@"[DEBUG] AdaptiveBanner proxy deallocated");
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

- (void)pause:(id)args
{
    if (self.isDestroyed || self.isPaused) {
        return;
    }
    self.isPaused = YES;

    TiThreadPerformOnMainThread(^{
        if ([self viewInitialized]) {
            TiUIView *tiView = [self view];
            if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
                [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView pauseAd];
            }
        }
    }, NO);
}

- (void)resume:(id)args
{
    if (self.isDestroyed || !self.isPaused) {
        return;
    }
    self.isPaused = NO;

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
        @"adaptiveType": @"anchored"
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

    GADAdSize adaptiveSize = GADLargeAnchoredAdaptiveBannerAdSizeWithWidth(width);
    bannerView.adSize = adaptiveSize;

    GADRequest *request = [GADRequest request];
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

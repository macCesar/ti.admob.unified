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
}

@property (nonatomic, weak) TiAdmobUnifiedAdaptiveBannerAdProxy *proxy;

- (void)createBannerView;
- (void)loadAd;
- (void)destroyAd;
- (BOOL)isAdLoaded;
- (void)setAdUnitId:(NSString *)adUnitId;

@end

@interface TiAdmobUnifiedAdaptiveBannerAdProxy ()
@property (nonatomic, assign) BOOL pendingLoad;
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

#pragma mark - TiViewProxy override (newView, NOT createView — TitaniumKit 13.x)

- (TiUIView *)newView
{
    TiAdmobUnifiedAdaptiveBannerAdView *v = [[TiAdmobUnifiedAdaptiveBannerAdView alloc] init];
    v.proxy = self;
    [v createBannerView];
    if (self.pendingLoad) {
        self.pendingLoad = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [v loadAd];
        });
    }
    return v;
}

#pragma mark - Public Methods

- (void)load:(id)args
{
    TiUIView *tiView = [self view];
    if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
        [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView loadAd];
    } else {
        self.pendingLoad = YES;
    }
}

- (void)destroy:(id)args
{
    TiUIView *tiView = [self view];
    if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
        [(TiAdmobUnifiedAdaptiveBannerAdView *)tiView destroyAd];
    }
}

- (NSNumber *)isLoaded:(id)args
{
    TiUIView *tiView = [self view];
    if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
        return @([(TiAdmobUnifiedAdaptiveBannerAdView *)tiView isAdLoaded]);
    }
    return @(NO);
}

#pragma mark - Property Setters (ivar-only, no view forwarding to avoid init deadlock)

- (void)setAdUnitId:(NSString *)adUnitId
{
    _adUnitId = adUnitId;
}

#pragma mark - GADBannerViewDelegate

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView
{
    TiUIView *tiView = [self view];
    if ([tiView isKindOfClass:[TiAdmobUnifiedAdaptiveBannerAdView class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [tiView setNeedsLayout];
            [tiView layoutIfNeeded];
        });
    }
    [self fireAdEvent:@"loaded" withData:@{@"adUnitId": self.adUnitId ?: @""}];
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"[ERROR] Adaptive banner failed to load: %@", error.localizedDescription);
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
    if ([self _hasListeners:eventName]) {
        [self fireEvent:eventName withObject:data];
    }
}

@end

#pragma mark - Adaptive Banner Ad View Implementation

@implementation TiAdmobUnifiedAdaptiveBannerAdView

- (id)init
{
    if (self = [super init]) {
        isAdLoaded = NO;
    }
    return self;
}

- (void)dealloc
{
    [self destroyAd];
}

- (void)createBannerView
{
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
    if (!bannerView) {
        NSLog(@"[ERROR] Adaptive banner view not initialized");
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
    [bannerView loadRequest:request];
    DebugLog(@"[DEBUG] Adaptive banner load request sent (width=%.0f)", width);
}

- (void)destroyAd
{
    if (bannerView) {
        bannerView.delegate = nil;
        [bannerView removeFromSuperview];
        bannerView = nil;
        isAdLoaded = NO;
    }
}

- (BOOL)isAdLoaded
{
    return isAdLoaded;
}

- (void)setAdUnitId:(NSString *)adUnitId
{
    if (bannerView && ![bannerView.adUnitID isEqualToString:adUnitId]) {
        bannerView.adUnitID = adUnitId;
    }
}

@end

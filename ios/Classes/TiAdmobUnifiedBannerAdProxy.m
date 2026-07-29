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
}

@property (nonatomic, weak) TiAdmobUnifiedBannerAdProxy *proxy;

- (void)createBannerView;
- (void)loadAd;
- (void)destroyAd;
- (void)pauseAd;
- (void)resumeAd;
- (BOOL)isAdLoaded;
- (void)setAdUnitId:(NSString *)adUnitId;
- (void)setAdSize:(NSString *)adSize;

@end

@interface TiAdmobUnifiedBannerAdProxy ()
// Set when load() is called before the view exists; createView will fire loadAd once ready.
@property (nonatomic, assign) BOOL pendingLoad;
@end

@implementation TiAdmobUnifiedBannerAdProxy

#pragma mark - Lifecycle

- (id)init
{
    NSLog(@"[BANNER-DBG] Proxy init: ENTRY");
    self = [super init];
    NSLog(@"[BANNER-DBG] Proxy init: super init returned self=%@", self);
    if (self) {
        _adSize = @"banner";
        NSLog(@"[BANNER-DBG] Proxy init: _adSize set, returning");
    }
    return self;
}

- (void)_initWithProperties:(NSDictionary *)properties
{
    NSLog(@"[BANNER-DBG] _initWithProperties: ENTRY (keys=%@)", [properties allKeys]);
    [super _initWithProperties:properties];
    NSLog(@"[BANNER-DBG] _initWithProperties: super returned (adUnitId=%@, adSize=%@)", self.adUnitId, self.adSize);
}

- (void)dealloc
{
    DebugLog(@"[DEBUG] Banner ad proxy deallocated");
}

#pragma mark - TiViewProxy overrides

- (TiUIView *)newView
{
    NSLog(@"[BANNER-DBG] newView invoked (adUnitId=%@, adSize=%@)", self.adUnitId, self.adSize);
    TiAdmobUnifiedBannerAdView *bannerAdView = [[TiAdmobUnifiedBannerAdView alloc] init];
    bannerAdView.proxy = self;
    NSLog(@"[BANNER-DBG] proxy wired, calling createBannerView");
    [bannerAdView createBannerView];
    NSLog(@"[BANNER-DBG] createBannerView returned; pendingLoad=%d", self.pendingLoad);
    if (self.pendingLoad) {
        self.pendingLoad = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[BANNER-DBG] firing deferred loadAd");
            [bannerAdView loadAd];
        });
    }
    return bannerAdView;
}

#pragma mark - Public Methods

- (void)load:(id)args
{
    NSLog(@"[BANNER-DBG] load() called (adUnitId=%@)", self.adUnitId);
    TiUIView *tiView = [self view];
    NSLog(@"[BANNER-DBG] [self view] returned %@ (class=%@)", tiView, NSStringFromClass([tiView class]));
    if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
        TiAdmobUnifiedBannerAdView *bannerAdView = (TiAdmobUnifiedBannerAdView *)tiView;
        NSLog(@"[BANNER-DBG] view is correct subclass, calling loadAd directly");
        [bannerAdView loadAd];
    } else {
        self.pendingLoad = YES;
        NSLog(@"[BANNER-DBG] view is NOT our subclass; setting pendingLoad=YES, waiting for createView");
    }
}

- (void)destroy:(id)args
{
    DebugLog(@"[DEBUG] Destroying banner ad");
    
    TiUIView *tiView = [self view];
    if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
        TiAdmobUnifiedBannerAdView *bannerAdView = (TiAdmobUnifiedBannerAdView *)tiView;
        [bannerAdView destroyAd];
    }
}

- (void)pause:(id)args
{
    DebugLog(@"[DEBUG] Pausing banner ad");
    
    TiUIView *tiView = [self view];
    if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
        TiAdmobUnifiedBannerAdView *bannerAdView = (TiAdmobUnifiedBannerAdView *)tiView;
        [bannerAdView pauseAd];
    }
}

- (void)resume:(id)args
{
    DebugLog(@"[DEBUG] Resuming banner ad");
    
    TiUIView *tiView = [self view];
    if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
        TiAdmobUnifiedBannerAdView *bannerAdView = (TiAdmobUnifiedBannerAdView *)tiView;
        [bannerAdView resumeAd];
    }
}

- (NSNumber *)isLoaded:(id)args
{
    TiUIView *tiView = [self view];
    if ([tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
        TiAdmobUnifiedBannerAdView *bannerAdView = (TiAdmobUnifiedBannerAdView *)tiView;
        return @([bannerAdView isAdLoaded]);
    }
    return @(NO);
}

#pragma mark - Property Setters

- (void)setAdUnitId:(NSString *)adUnitId
{
    // Just store the ivar — do NOT call [self view] from a setter that may fire
    // during _initWithProperties:. Doing so caused a hang in the alloc/init chain
    // (TiViewProxy [self view] dispatch_sync to main thread deadlocking against the
    // Kroll-thread setter invocation).
    // The view, when it is created via createView, reads self.proxy.adUnitId.
    _adUnitId = adUnitId;
    NSLog(@"[BANNER-DBG] setAdUnitId: stored ivar (no view forward) val=%@", adUnitId);
}

- (void)setAdSize:(NSString *)adSize
{
    _adSize = adSize;
    NSLog(@"[BANNER-DBG] setAdSize: stored ivar (no view forward) val=%@", adSize);
}

#pragma mark - GADBannerViewDelegate

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView
{
    NSLog(@"[BANNER-DBG] bannerViewDidReceiveAd FIRED (ad loaded successfully)");
    
    // Force layout refresh to make banner visible
    TiUIView *tiView = [self view];
    if (tiView && [tiView isKindOfClass:[TiAdmobUnifiedBannerAdView class]]) {
        TiAdmobUnifiedBannerAdView *bannerAdView = (TiAdmobUnifiedBannerAdView *)tiView;
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
    NSLog(@"[BANNER-DBG] bannerView:didFailToReceiveAdWithError FIRED: %@ (code=%ld)", error.localizedDescription, (long)error.code);
    
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
    if ([self _hasListeners:eventName]) {
        [self fireEvent:eventName withObject:data];
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
        DebugLog(@"[DEBUG] Banner ad view initialized");
        // createBannerView NOT called here — self.proxy is nil at init time.
        // The proxy calls createBannerView from its own createView after wiring proxy.
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
    NSLog(@"[BANNER-DBG] BannerAdView createBannerView; proxy=%@, adUnitId=%@", self.proxy, self.proxy.adUnitId);
    if (!self.proxy.adUnitId) {
        NSLog(@"[BANNER-DBG][ERROR] BAIL: no adUnitId on proxy");
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
    if (!bannerView) {
        NSLog(@"[ERROR] Cannot load ad - banner view not initialized");
        return;
    }
    
    GADRequest *request = [GADRequest request];
    
    // Add keywords if specified
    if (self.proxy.keywords && [self.proxy.keywords count] > 0) {
        // Note: Keywords are not directly supported in GADRequest in newer versions
        // They should be handled through targeting or custom parameters if needed
        DebugLog(@"[DEBUG] Keywords specified but not applied (not supported in current GAD version)");
    }
    
    [bannerView loadRequest:request];
    NSLog(@"[BANNER-DBG] loadRequest sent to GADBannerView for adUnit=%@", bannerView.adUnitID);
}

- (void)destroyAd
{
    if (bannerView) {
        bannerView.delegate = nil;
        [bannerView removeFromSuperview];
        bannerView = nil;
        isAdLoaded = NO;
        DebugLog(@"[DEBUG] Banner ad destroyed");
    }
}

- (void)pauseAd
{
    // GADBannerView lifecycle is handled by iOS/GMA automatically (view visibility +
    // app lifecycle notifications). This method is a no-op kept for paridad with the
    // Android API surface.
    DebugLog(@"[DEBUG] Banner pauseAd() is a no-op on iOS (handled by GADBannerView lifecycle)");
}

- (void)resumeAd
{
    // Companion no-op to pauseAd above.
    DebugLog(@"[DEBUG] Banner resumeAd() is a no-op on iOS (handled by GADBannerView lifecycle)");
}

- (BOOL)isAdLoaded
{
    return isAdLoaded;
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
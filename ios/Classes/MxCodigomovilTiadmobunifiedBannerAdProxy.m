/**
 * ti.admob.unified - Unified AdMob Banner Ad Proxy for iOS
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "MxCodigomovilTiadmobunifiedBannerAdProxy.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiViewProxy.h"
#import "TiUIView.h"

@interface MxCodigomovilTiadmobunifiedBannerAdView : TiUIView
{
    GADBannerView *bannerView;
    BOOL isAdLoaded;
}

@property (nonatomic, weak) MxCodigomovilTiadmobunifiedBannerAdProxy *proxy;

- (void)createBannerView;
- (void)loadAd;
- (void)destroyAd;
- (void)pauseAd;
- (void)resumeAd;
- (BOOL)isAdLoaded;
- (void)setAdUnitId:(NSString *)adUnitId;
- (void)setAdSize:(NSString *)adSize;

@end

@implementation MxCodigomovilTiadmobunifiedBannerAdProxy

#pragma mark - Lifecycle

- (id)init
{
    if (self = [super init]) {
        // Set default values
        self.adSize = @"banner";
        DebugLog(@"[DEBUG] Banner ad proxy initialized");
    }
    return self;
}

- (void)dealloc
{
    DebugLog(@"[DEBUG] Banner ad proxy deallocated");
}

#pragma mark - TiViewProxy overrides

- (TiUIView *)createView
{
    MxCodigomovilTiadmobunifiedBannerAdView *bannerAdView = [[MxCodigomovilTiadmobunifiedBannerAdView alloc] init];
    bannerAdView.proxy = self;
    return bannerAdView;
}

- (void)configurationSet
{
    [super configurationSet];
    
    // Extract configuration from creation arguments
    NSDictionary *args = [self valueForKey:@"_args"];
    if (args && [args isKindOfClass:[NSDictionary class]]) {
        if ([args objectForKey:@"adUnitId"]) {
            self.adUnitId = [TiUtils stringValue:@"adUnitId" properties:args];
        }
        
        if ([args objectForKey:@"adSize"]) {
            self.adSize = [TiUtils stringValue:@"adSize" properties:args];
        }
        
        if ([args objectForKey:@"keywords"]) {
            self.keywords = [args objectForKey:@"keywords"];
        }
        
        if ([args objectForKey:@"extras"]) {
            self.extras = [args objectForKey:@"extras"];
        }
    }
    
    DebugLog(@"[DEBUG] Banner ad proxy configured with adUnitId: %@, adSize: %@", self.adUnitId, self.adSize);
}

#pragma mark - Public Methods

- (void)load:(id)args
{
    DebugLog(@"[DEBUG] Loading banner ad");
    
    MxCodigomovilTiadmobunifiedBannerAdView *bannerAdView = (MxCodigomovilTiadmobunifiedBannerAdView *)[self view];
    if (bannerAdView) {
        [bannerAdView loadAd];
    } else {
        NSLog(@"[ERROR] Cannot load ad - banner view not created yet");
    }
}

- (void)destroy:(id)args
{
    DebugLog(@"[DEBUG] Destroying banner ad");
    
    MxCodigomovilTiadmobunifiedBannerAdView *bannerAdView = (MxCodigomovilTiadmobunifiedBannerAdView *)[self view];
    if (bannerAdView) {
        [bannerAdView destroyAd];
    }
}

- (void)pause:(id)args
{
    DebugLog(@"[DEBUG] Pausing banner ad");
    
    MxCodigomovilTiadmobunifiedBannerAdView *bannerAdView = (MxCodigomovilTiadmobunifiedBannerAdView *)[self view];
    if (bannerAdView) {
        [bannerAdView pauseAd];
    }
}

- (void)resume:(id)args
{
    DebugLog(@"[DEBUG] Resuming banner ad");
    
    MxCodigomovilTiadmobunifiedBannerAdView *bannerAdView = (MxCodigomovilTiadmobunifiedBannerAdView *)[self view];
    if (bannerAdView) {
        [bannerAdView resumeAd];
    }
}

- (NSNumber *)isLoaded:(id)args
{
    MxCodigomovilTiadmobunifiedBannerAdView *bannerAdView = (MxCodigomovilTiadmobunifiedBannerAdView *)[self view];
    if (bannerAdView) {
        return @([bannerAdView isAdLoaded]);
    }
    return @(NO);
}

#pragma mark - Property Setters

- (void)setAdUnitId:(NSString *)adUnitId
{
    _adUnitId = adUnitId;
    DebugLog(@"[DEBUG] AdUnit ID set to: %@", adUnitId);
    
    MxCodigomovilTiadmobunifiedBannerAdView *bannerAdView = (MxCodigomovilTiadmobunifiedBannerAdView *)[self view];
    if (bannerAdView) {
        [bannerAdView setAdUnitId:adUnitId];
    }
}

- (void)setAdSize:(NSString *)adSize
{
    _adSize = adSize;
    DebugLog(@"[DEBUG] Ad size set to: %@", adSize);
    
    MxCodigomovilTiadmobunifiedBannerAdView *bannerAdView = (MxCodigomovilTiadmobunifiedBannerAdView *)[self view];
    if (bannerAdView) {
        [bannerAdView setAdSize:adSize];
    }
}

#pragma mark - GADBannerViewDelegate

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView
{
    DebugLog(@"[DEBUG] Banner ad loaded successfully");
    
    NSDictionary *event = @{
        @"adUnitId": self.adUnitId ?: @""
    };
    [self fireAdEvent:@"loaded" withData:event];
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"[ERROR] Banner ad failed to load: %@", error.localizedDescription);
    
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
        return GADAdSizeSmartBannerPortrait; // Default to portrait
    } else {
        NSLog(@"[WARN] Unknown ad size: %@, using default BANNER", sizeString);
        return GADAdSizeBanner;
    }
}

@end

#pragma mark - Banner Ad View Implementation

@implementation MxCodigomovilTiadmobunifiedBannerAdView

- (id)init
{
    if (self = [super init]) {
        isAdLoaded = NO;
        DebugLog(@"[DEBUG] Banner ad view initialized");
        [self createBannerView];
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
    if (!self.proxy.adUnitId) {
        NSLog(@"[ERROR] Cannot create banner view - no ad unit ID specified");
        return;
    }
    
    GADAdSize adSize = [MxCodigomovilTiadmobunifiedBannerAdProxy getAdSizeFromString:self.proxy.adSize];
    
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
    DebugLog(@"[DEBUG] Ad request sent for banner ad");
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
    // GADBannerView doesn't have explicit pause/resume methods
    // The system handles lifecycle automatically
    DebugLog(@"[DEBUG] Banner ad paused (handled automatically by system)");
}

- (void)resumeAd
{
    // GADBannerView doesn't have explicit pause/resume methods
    // The system handles lifecycle automatically
    DebugLog(@"[DEBUG] Banner ad resumed (handled automatically by system)");
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
        GADAdSize newAdSize = [MxCodigomovilTiadmobunifiedBannerAdProxy getAdSizeFromString:adSize];
        // Note: Changing ad size on existing banner view requires recreating it
        // For now, we'll log a warning
        NSLog(@"[WARN] Changing ad size on existing banner view not supported. Recreate the banner instead.");
    }
}

@end
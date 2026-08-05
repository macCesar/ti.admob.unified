/**
 * ti.admob.unified - Adaptive Banner Ad Proxy for iOS
 *
 * Adaptive banners auto-size to the container width using
 * GADLargeAnchoredAdaptiveBannerAdSizeWithWidth from GMA 13.x. The height is
 * derived by Google based on width + current orientation. No fixed adSize.
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 *
 */

#import "TiViewProxy.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface TiAdmobUnifiedAdaptiveBannerAdProxy : TiViewProxy <GADBannerViewDelegate>

@property (nonatomic, strong) NSString *adUnitId;
// ADAPTIVE_ANCHORED (default) or ADAPTIVE_INLINE, same constants as Android.
@property (nonatomic, strong) NSString *adaptiveType;
// Inline only. Maximum height in points; Android defaults to 50 as well.
@property (nonatomic, assign) NSInteger maxHeight;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSDictionary *extras;
@property (nonatomic, strong) NSString *contentUrl;
// Identifies what issued the request. Google reserves it for libraries that
// wrap the SDK, which is exactly what this module is.
@property (nonatomic, strong) NSString *requestAgent;

- (BOOL)isInlineAdaptive;

- (void)load:(id)args;
- (void)destroy:(id)args;
- (void)pause:(id)args;
- (void)resume:(id)args;
- (NSNumber *)isLoaded:(id)args;
- (void)destroyAdViewAndCancelRequest:(id)args;
- (void)destoyAdViewAndCancelRequest:(id)args;

- (void)fireAdEvent:(NSString *)eventName withData:(NSDictionary *)data;

@end

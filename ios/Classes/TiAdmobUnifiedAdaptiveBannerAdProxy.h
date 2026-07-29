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
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSDictionary *extras;

- (void)load:(id)args;
- (void)destroy:(id)args;
- (NSNumber *)isLoaded:(id)args;

- (void)fireAdEvent:(NSString *)eventName withData:(NSDictionary *)data;

@end

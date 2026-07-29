/**
 * ti.admob.unified - Unified AdMob Banner Ad Proxy for iOS
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "TiViewProxy.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface TiAdmobUnifiedBannerAdProxy : TiViewProxy <GADBannerViewDelegate>

// Configuration properties
@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, strong) NSString *adSize;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSDictionary *extras;

// Public methods
- (void)load:(id)args;
- (void)destroy:(id)args;
- (void)pause:(id)args;
- (void)resume:(id)args;
- (NSNumber *)isLoaded:(id)args;
- (void)destroyAdViewAndCancelRequest:(id)args;
- (void)destoyAdViewAndCancelRequest:(id)args;

// Internal methods
- (void)fireAdEvent:(NSString *)eventName withData:(NSDictionary *)data;
+ (GADAdSize)getAdSizeFromString:(NSString *)sizeString;

@end

/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "TiProxy.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface TiAdmobUnifiedInterstitialAdProxy : TiProxy

// Only the configuration an application supplies is declared here. The native ad
// object and the internal state live in a class extension in the .m, so the
// JavaScript surface matches Android's, which exposes neither.
@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, strong) NSNumber *autoReload;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSDictionary *extras;
// Identifies what issued the request. Google reserves it for libraries that
// wrap the SDK, which is exactly what this module is.
@property (nonatomic, strong) NSString *requestAgent;

// Ad management methods
- (void)load:(id)args;
- (void)show:(id)args;
- (NSNumber *)isLoaded:(id)args;
- (void)destroy:(id)args;

@end

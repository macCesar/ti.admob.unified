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

@interface TiAdmobUnifiedAppOpenAdProxy : TiProxy <GADFullScreenContentDelegate>

@property (nonatomic, strong) GADAppOpenAd *appOpenAd;
@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, assign) BOOL autoReload;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) BOOL destroyedEventFired;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSDictionary *extras;
// Identifies what issued the request. Google reserves it for libraries that
// wrap the SDK, which is exactly what this module is.
@property (nonatomic, strong) NSString *requestAgent;

// Timestamp of the last successful load. App open ads expire four hours after
// the request, so the proxy has to remember when the ad arrived.
@property (nonatomic, strong) NSDate *loadTime;

// Ad management methods
- (void)load:(id)args;
- (void)show:(id)args;
- (NSNumber *)isLoaded:(id)args;
- (void)destroy:(id)args;

@end

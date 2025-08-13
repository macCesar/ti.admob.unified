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

@interface MxCodigomovilTiadmobunifiedInterstitialAdProxy : TiProxy <GADFullScreenContentDelegate>

@property (nonatomic, strong) GADInterstitialAd *interstitialAd;
@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, assign) BOOL autoReload;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSDictionary *extras;

// Ad management methods
- (void)load:(id)args;
- (void)show:(id)args;
- (NSNumber *)isLoaded:(id)args;
- (void)destroy:(id)args;

@end
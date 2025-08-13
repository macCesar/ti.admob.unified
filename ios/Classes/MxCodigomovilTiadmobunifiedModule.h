/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "TiModule.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <UserMessagingPlatform/UserMessagingPlatform.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

@interface MxCodigomovilTiadmobunifiedModule : TiModule <GADInitializationDelegate> {

}

// Initialization and SDK setup
- (void)initialize:(id)args;

// Consent management (GDPR/CCPA/UMP)
- (void)requestConsent:(id)args;
- (NSNumber *)canShowAds:(id)args;
- (NSNumber *)canShowPersonalizedAds:(id)args;
- (NSNumber *)isGDPR:(id)args;
- (NSNumber *)isPrivacyOptionsRequired:(id)args;
- (void)presentPrivacyOptions:(id)args;
- (void)resetConsent:(id)args;

// iOS-specific: App Tracking Transparency
- (void)requestTrackingAuthorization:(id)args;

// Ad creation methods
- (id)createRewarded:(id)args;
- (id)createInterstitial:(id)args;
- (id)createBanner:(id)args;
- (id)createAdaptiveBanner:(id)args;
- (id)createAppOpen:(id)args;

// Utility methods
- (void)setAppVolume:(id)args;
- (void)setTestDevice:(id)args;
- (NSNumber *)isTestDevice:(id)args;

@end
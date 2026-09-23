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

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif

@interface TiAdmobUnifiedModule : TiModule {

}

// Initialization and SDK setup
- (void)initialize:(id)args;
- (void)openAdInspector:(id)args;

// Consent management (GDPR/CCPA/UMP)
- (void)requestConsent:(id)args;
- (NSNumber *)canRequestAds:(id)args;
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
- (NSDictionary *)getAnchoredAdaptiveBannerSize:(id)args;
- (void)setAppVolume:(id)args;
- (void)setTestDevice:(id)args;
- (NSNumber *)isTestDevice:(id)args;

// Mediation diagnostics
- (NSNumber *)isAppLovinAvailable:(id)args;
- (NSNumber *)isMetaAvailable:(id)args;
- (NSNumber *)isInMobiAvailable:(id)args;
- (NSNumber *)isVungleAvailable:(id)args;
- (NSNumber *)isUnityAvailable:(id)args;
- (NSNumber *)isIronSourceAvailable:(id)args;
- (NSDictionary *)getMediationStatus:(id)args;

// Legacy mediation compatibility
- (void)setAppLovinGDPRConsent:(id)args;
- (void)setInMobiGDPRConsent:(id)args;
- (void)setVungleGDPRConsent:(id)args;
- (void)enableOptionalMediationNetworks:(id)args;

@end

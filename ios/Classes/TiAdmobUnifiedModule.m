/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "TiAdmobUnifiedModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiAdmobUnifiedRewardedAdProxy.h"
#import "TiAdmobUnifiedAdaptiveBannerAdProxy.h"
#import "TiAdmobUnifiedInterstitialAdProxy.h"
#import "TiAdmobUnifiedBannerAdProxy.h"

@implementation TiAdmobUnifiedModule

#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"67829dbd-d857-4749-9e7c-6143caedee43";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"ti.admob.unified";
}

#pragma mark Lifecycle

- (void)startup
{
  // This method is called when the module is first loaded
  // You *must* call the superclass
  [super startup];
  DebugLog(@"[DEBUG] %@ loaded", self);
}

#pragma mark Constants

// Constants will be implemented as getter methods

// ===================================================================
// BANNER SIZE CONSTANTS
// ===================================================================

// ===================================================================
// EVENT CONSTANTS (UNIFIED NAMING)
// ===================================================================

// ===================================================================
// CONSENT/COMPLIANCE CONSTANTS
// ===================================================================

// Debug Geography Constants

// iOS Tracking Authorization Constants (iOS 14+ only)
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
#else
// Fallback for iOS < 14
#endif

// Content Rating Constants

// ===================================================================
// ERROR CODE CONSTANTS
// ===================================================================

// ===================================================================
// TEST AD UNIT IDS (OFFICIAL GOOGLE TEST IDS)
// ===================================================================

#pragma mark Public APIs

// ===================================================================
// SDK INITIALIZATION METHODS
// ===================================================================
- (void)initialize:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    
    DebugLog(@"[DEBUG] Initializing Google Mobile Ads SDK");
    
    // Configure request configuration if provided
    if (config != nil) {
        [GADMobileAds.sharedInstance.requestConfiguration setTestDeviceIdentifiers:[self buildRequestConfiguration:config].testDeviceIdentifiers];
    }
    
    // Initialize the SDK
    [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *status) {
        DebugLog(@"[DEBUG] AdMob SDK initialization completed successfully");
        
        // Fire module initialization event
        NSDictionary *event = @{
            @"success": @YES,
            @"status": status.description
        };
        [self fireEvent:@"module_initialized" withObject:event];
    }];
}

- (GADRequestConfiguration *)buildRequestConfiguration:(NSDictionary *)config
{
    GADRequestConfiguration *requestConfig = GADMobileAds.sharedInstance.requestConfiguration;
    
    // Test device IDs
    if ([config objectForKey:@"testDeviceIds"]) {
        NSArray *testDeviceIds = [config objectForKey:@"testDeviceIds"];
        if (testDeviceIds != nil && [testDeviceIds count] > 0) {
            requestConfig.testDeviceIdentifiers = testDeviceIds;
        }
    }
    
    // Tag for child directed treatment (COPPA)
    if ([config objectForKey:@"tagForChildDirectedTreatment"]) {
        BOOL childDirected = [TiUtils boolValue:[config objectForKey:@"tagForChildDirectedTreatment"]];
        requestConfig.tagForChildDirectedTreatment = childDirected ? @YES : @NO;
    }
    
    // Tag for under age of consent (GDPR)
    if ([config objectForKey:@"tagForUnderAgeOfConsent"]) {
        BOOL underAge = [TiUtils boolValue:[config objectForKey:@"tagForUnderAgeOfConsent"]];
        requestConfig.tagForUnderAgeOfConsent = underAge ? @YES : @NO;
    }
    
    // Max ad content rating
    if ([config objectForKey:@"maxAdContentRating"]) {
        NSString *rating = [TiUtils stringValue:[config objectForKey:@"maxAdContentRating"]];
        requestConfig.maxAdContentRating = rating;
    }
    
    return requestConfig;
}

// ===================================================================
// CONSENT MANAGEMENT METHODS (GDPR/CCPA/UMP)
// ===================================================================
- (void)requestConsent:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    
    DebugLog(@"[DEBUG] Requesting consent");
    
    UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
    
    // Handle debug geography and test devices
    if ([config objectForKey:@"geography"]) {
        NSInteger geography = [TiUtils intValue:[config objectForKey:@"geography"]];
        UMPDebugSettings *debugSettings = [[UMPDebugSettings alloc] init];
        debugSettings.geography = geography;
        
        // Handle test device IDs for consent testing
        if ([config objectForKey:@"testDeviceIds"]) {
            NSArray *testDeviceIds = [config objectForKey:@"testDeviceIds"];
            if (testDeviceIds != nil && [testDeviceIds count] > 0) {
                debugSettings.testDeviceIdentifiers = testDeviceIds;
            }
        }
        
        parameters.debugSettings = debugSettings;
    }
    
    // Tag for under age of consent
    if ([config objectForKey:@"tagForUnderAgeOfConsent"]) {
        BOOL underAge = [TiUtils boolValue:[config objectForKey:@"tagForUnderAgeOfConsent"]];
        parameters.tagForUnderAgeOfConsent = underAge;
    }
    
    // Request consent info update
    [UMPConsentInformation.sharedInstance 
        requestConsentInfoUpdateWithParameters:parameters
        completionHandler:^(NSError *_Nullable error) {
            if (error) {
                DebugLog(@"[ERROR] Consent info update failed: %@", error.localizedDescription);
                
                NSDictionary *errorEvent = @{
                    @"error": error.localizedDescription,
                    @"code": @(error.code)
                };
                [self fireEvent:@"consent_error" withObject:errorEvent];
                return;
            }
            
            DebugLog(@"[DEBUG] Consent info update successful");
            
            // Check if consent form is available
            if (UMPConsentInformation.sharedInstance.formStatus == UMPFormStatusAvailable) {
                [self loadConsentForm];
            } else {
                // No consent form needed, fire ready event
                [self fireConsentReadyEvent];
            }
        }];
}

- (void)loadConsentForm
{
    [UMPConsentForm loadWithCompletionHandler:^(UMPConsentForm *form, NSError *error) {
        if (error) {
            DebugLog(@"[ERROR] Consent form load failed: %@", error.localizedDescription);
            
            NSDictionary *errorEvent = @{
                @"error": error.localizedDescription,
                @"code": @(error.code)
            };
            [self fireEvent:@"consent_error" withObject:errorEvent];
            return;
        }
        
        if (form) {
            DebugLog(@"[DEBUG] Consent form loaded successfully");
            
            UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
            [form presentFromViewController:rootViewController
                          completionHandler:^(NSError *_Nullable error) {
                if (error) {
                    DebugLog(@"[ERROR] Consent form error: %@", error.localizedDescription);
                    
                    NSDictionary *errorEvent = @{
                        @"error": error.localizedDescription,
                        @"code": @(error.code)
                    };
                    [self fireEvent:@"consent_error" withObject:errorEvent];
                } else {
                    DebugLog(@"[DEBUG] Consent form dismissed successfully");
                    [self fireConsentReadyEvent];
                }
            }];
        }
    }];
}

- (void)fireConsentReadyEvent
{
    NSDictionary *consentEvent = @{
        @"canShowAds": [self canShowAds:nil],
        @"canShowPersonalizedAds": [self canShowPersonalizedAds:nil],
        @"isGDPR": [self isGDPR:nil],
        @"isPrivacyOptionsRequired": [self isPrivacyOptionsRequired:nil]
    };
    [self fireEvent:@"consent_ready" withObject:consentEvent];
}

// ===================================================================
// CONSENT STATUS METHODS
// ===================================================================
- (NSNumber *)canShowAds:(id)args
{
    return @(UMPConsentInformation.sharedInstance.canRequestAds);
}

- (NSNumber *)canShowPersonalizedAds:(id)args
{
    // The UMP SDK is the authoritative source for whether ads can be shown and
    // whether personalization is permitted. Returning canRequestAds matches the
    // SDK's gating: GMA itself respects the user's TCF choices when fetching ads.
    // Parsing IABTCF_TCString by hand here is brittle and was a known weak point.
    return @(UMPConsentInformation.sharedInstance.canRequestAds);
}

- (NSNumber *)isGDPR:(id)args
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *gdprApplies = [userDefaults stringForKey:@"IABTCF_gdprApplies"] ?: @"0";
    return @([gdprApplies isEqualToString:@"1"]);
}

- (NSNumber *)isPrivacyOptionsRequired:(id)args
{
    return @(UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == UMPPrivacyOptionsRequirementStatusRequired);
}

- (void)presentPrivacyOptions:(id)args
{
    NSDictionary *config = nil;
    if (args != nil && [args count] > 0) {
        config = [args objectAtIndex:0];
    }
    
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    [UMPConsentForm presentPrivacyOptionsFormFromViewController:rootViewController
                                              completionHandler:^(NSError *_Nullable error) {
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        if (error != nil) {
            [result setObject:@NO forKey:@"success"];
            [result setObject:error.localizedDescription forKey:@"error"];
        } else {
            [result setObject:@YES forKey:@"success"];
        }
        
        [self fireEvent:@"privacy_options_dismissed" withObject:result];
    }];
}

- (void)resetConsent:(id)args
{
    [UMPConsentInformation.sharedInstance reset];
    DebugLog(@"[DEBUG] Consent information has been reset");
}

// ===================================================================
// iOS-SPECIFIC: APP TRACKING TRANSPARENCY
// ===================================================================
- (void)requestTrackingAuthorization:(id)args
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
    if (@available(iOS 14, *)) {
        NSDictionary *config = nil;
        if (args != nil && [args count] > 0) {
            config = [args objectAtIndex:0];
        }
        
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            NSDictionary *result = @{
                @"status": @(status)
            };
            
            [self fireEvent:@"tracking_authorization_completed" withObject:result];
            
            // If callback is provided in config, also fire that
            if (config && [config objectForKey:@"callback"]) {
                // The callback should be handled by the JavaScript side
            }
        }];
    } else {
        // iOS < 14, tracking authorization not required
        NSDictionary *result = @{
            @"status": @(3) // ATTrackingManagerAuthorizationStatusAuthorized equivalent
        };
        [self fireEvent:@"tracking_authorization_completed" withObject:result];
    }
#else
    // iOS < 14, tracking authorization not required
    NSDictionary *result = @{
        @"status": @(3) // ATTrackingManagerAuthorizationStatusAuthorized equivalent
    };
    [self fireEvent:@"tracking_authorization_completed" withObject:result];
#endif
}

// ===================================================================
// AD CREATION METHODS
// ===================================================================
- (id)createRewarded:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    
    DebugLog(@"[DEBUG] Creating rewarded ad");
    return [[TiAdmobUnifiedRewardedAdProxy alloc] _initWithPageContext:[self executionContext] args:@[config]];
}

- (id)createInterstitial:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    
    DebugLog(@"[DEBUG] Creating interstitial ad");
    return [[TiAdmobUnifiedInterstitialAdProxy alloc] _initWithPageContext:[self executionContext] args:@[config]];
}

- (id)createBanner:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    DebugLog(@"[DEBUG] Creating banner ad");
    return [[TiAdmobUnifiedBannerAdProxy alloc] _initWithPageContext:[self pageContext] args:args];
}

- (id)createAdaptiveBanner:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    DebugLog(@"[DEBUG] Creating adaptive banner ad");
    TiAdmobUnifiedAdaptiveBannerAdProxy *proxy = [[TiAdmobUnifiedAdaptiveBannerAdProxy alloc] _initWithPageContext:[self pageContext] args:args];
    return proxy;
}

- (id)createAppOpen:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    
    DebugLog(@"[DEBUG] Creating app open ad");
    // TODO: Implement app open ad proxy
    return nil;
}

// ===================================================================
// UTILITY METHODS
// ===================================================================
- (void)setAppVolume:(id)args
{
    // GADMobileAds.applicationVolume was removed by Google. The method is kept as
    // a no-op for backwards compatibility with JS code that still calls it.
    // Use the device system volume for ad audio control.
    ENSURE_ARG_COUNT(args, 1);
    DebugLog(@"[DEBUG] setAppVolume() is a no-op in GMA 13.x+; use device system volume");
}

- (void)setTestDevice:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSString *deviceId = [TiUtils stringValue:[args objectAtIndex:0]];

    GADRequestConfiguration *requestConfig = GADMobileAds.sharedInstance.requestConfiguration;
    requestConfig.testDeviceIdentifiers = @[deviceId];

    DebugLog(@"[DEBUG] Test device ID set: %@", deviceId);
}

- (NSNumber *)isTestDevice:(id)args
{
    // Returns YES if any test device IDs have been registered via setTestDevice().
    NSArray<NSString *> *testIds = GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers;
    return @(testIds != nil && testIds.count > 0);
}

#pragma mark - Mediation network availability (parity with Android)

- (NSNumber *)isAppLovinAvailable:(id)args
{
    return @(NSClassFromString(@"ALSdk") != nil);
}

- (NSNumber *)isInMobiAvailable:(id)args
{
    return @(NSClassFromString(@"IMSdk") != nil);
}

- (NSNumber *)isVungleAvailable:(id)args
{
    return @(NSClassFromString(@"VungleAds") != nil);
}

#pragma mark - Per-network GDPR consent (stubs — iOS GMA already routes UMP consent to adapters)

- (void)setAppLovinGDPRConsent:(id)args
{
    DebugLog(@"[DEBUG] setAppLovinGDPRConsent called; on iOS this is handled by GMA via UMP. No-op.");
}

- (void)setInMobiGDPRConsent:(id)args
{
    DebugLog(@"[DEBUG] setInMobiGDPRConsent called; on iOS this is handled by GMA via UMP. No-op.");
}

- (void)setVungleGDPRConsent:(id)args
{
    DebugLog(@"[DEBUG] setVungleGDPRConsent called; on iOS this is handled by GMA via UMP. No-op.");
}

- (void)enableOptionalMediationNetworks:(id)args
{
    DebugLog(@"[DEBUG] enableOptionalMediationNetworks called; iOS bundle includes all adapters statically.");
}

#pragma mark - JS Constants (parity with Android @Kroll.constant)

// Ad type identifiers
- (NSString *)AD_TYPE_BANNER { return @"banner"; }
- (NSString *)AD_TYPE_INTERSTITIAL { return @"interstitial"; }
- (NSString *)AD_TYPE_REWARDED { return @"rewarded"; }
- (NSString *)AD_TYPE_REWARDED_INTERSTITIAL { return @"rewarded_interstitial"; }
- (NSString *)AD_TYPE_APP_OPEN { return @"app_open"; }
- (NSString *)AD_TYPE_NATIVE { return @"native"; }

// Banner sizes
- (NSString *)BANNER { return @"banner"; }
- (NSString *)LARGE_BANNER { return @"large_banner"; }
- (NSString *)MEDIUM_RECTANGLE { return @"medium_rectangle"; }
- (NSString *)FULLBANNER { return @"fullbanner"; }
- (NSString *)LEADERBOARD { return @"leaderboard"; }
- (NSString *)ADAPTIVE_ANCHORED { return @"adaptive_anchored"; }
- (NSString *)ADAPTIVE_INLINE { return @"adaptive_inline"; }
- (NSString *)COLLAPSIBLE_TOP { return @"collapsible_top"; }
- (NSString *)COLLAPSIBLE_BOTTOM { return @"collapsible_bottom"; }

// Event names
- (NSString *)AD_LOADED { return @"loaded"; }
- (NSString *)AD_FAILED_TO_LOAD { return @"failed_to_load"; }
- (NSString *)AD_OPENED { return @"opened"; }
- (NSString *)AD_CLOSED { return @"closed"; }
- (NSString *)AD_CLICKED { return @"clicked"; }
- (NSString *)AD_IMPRESSION { return @"impression"; }
- (NSString *)AD_REWARDED { return @"rewarded"; }
- (NSString *)AD_FAILED_TO_SHOW { return @"failed_to_show"; }
- (NSString *)AD_SHOWED_FULLSCREEN_CONTENT { return @"showed_fullscreen_content"; }
- (NSString *)AD_DESTROYED { return @"destroyed"; }

// UMP consent status (values from UMPConsentStatus iOS enum, match Android UMP)
- (NSNumber *)CONSENT_STATUS_UNKNOWN { return @(UMPConsentStatusUnknown); }
- (NSNumber *)CONSENT_STATUS_REQUIRED { return @(UMPConsentStatusRequired); }
- (NSNumber *)CONSENT_STATUS_NOT_REQUIRED { return @(UMPConsentStatusNotRequired); }
- (NSNumber *)CONSENT_STATUS_OBTAINED { return @(UMPConsentStatusObtained); }

// UMP debug geography — bundled iOS UMP has only Disabled/EEA/NotEEA.
// OTHER maps to NotEEA (closest match in this SDK version).
// REGULATED_US_STATE is hardcoded to 3 — will work after UMP SDK bump in Fase 2.
- (NSNumber *)DEBUG_GEOGRAPHY_DISABLED { return @(UMPDebugGeographyDisabled); }
- (NSNumber *)DEBUG_GEOGRAPHY_EEA { return @(UMPDebugGeographyEEA); }
- (NSNumber *)DEBUG_GEOGRAPHY_OTHER { return @(UMPDebugGeographyNotEEA); }
- (NSNumber *)DEBUG_GEOGRAPHY_REGULATED_US_STATE { return @(3); }

// Max ad content ratings
- (NSString *)MAX_AD_CONTENT_RATING_GENERAL { return @"G"; }
- (NSString *)MAX_AD_CONTENT_RATING_PARENTAL_GUIDANCE { return @"PG"; }
- (NSString *)MAX_AD_CONTENT_RATING_TEEN { return @"T"; }
- (NSString *)MAX_AD_CONTENT_RATING_MATURE_AUDIENCE { return @"MA"; }

// GMA error codes
- (NSNumber *)ERROR_CODE_SERVER_ERROR { return @(0); }
- (NSNumber *)ERROR_CODE_INVALID_REQUEST { return @(1); }
- (NSNumber *)ERROR_CODE_NETWORK_ERROR { return @(2); }
- (NSNumber *)ERROR_CODE_NO_FILL { return @(3); }
- (NSNumber *)ERROR_CODE_APP_ID_MISSING { return @(8); }
- (NSNumber *)ERROR_CODE_MEDIATION_NO_FILL { return @(9); }
- (NSNumber *)ERROR_CODE_INVALID_AD_SIZE { return @(10); }

// Google test ad unit IDs (iOS-specific values from https://developers.google.com/admob/ios/test-ads)
- (NSString *)TEST_BANNER { return @"ca-app-pub-3940256099942544/2934735716"; }
- (NSString *)TEST_ADAPTIVE_BANNER { return @"ca-app-pub-3940256099942544/2435281174"; }
- (NSString *)TEST_INTERSTITIAL { return @"ca-app-pub-3940256099942544/4411468910"; }
- (NSString *)TEST_INTERSTITIAL_VIDEO { return @"ca-app-pub-3940256099942544/5135589807"; }
- (NSString *)TEST_REWARDED { return @"ca-app-pub-3940256099942544/1712485313"; }
- (NSString *)TEST_REWARDED_INTERSTITIAL { return @"ca-app-pub-3940256099942544/6978759866"; }
- (NSString *)TEST_NATIVE { return @"ca-app-pub-3940256099942544/3986624511"; }
- (NSString *)TEST_APP_OPEN { return @"ca-app-pub-3940256099942544/5575463023"; }

@end

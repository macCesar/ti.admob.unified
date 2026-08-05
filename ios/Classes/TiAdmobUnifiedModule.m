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
#import "TiApp.h"
#import "TiUtils.h"
#import "TiAdmobUnifiedRewardedAdProxy.h"
#import "TiAdmobUnifiedAdaptiveBannerAdProxy.h"
#import "TiAdmobUnifiedInterstitialAdProxy.h"
#import "TiAdmobUnifiedBannerAdProxy.h"
#import "TiAdmobUnifiedAppOpenAdProxy.h"

typedef NS_ENUM(NSInteger, TiAdmobUnifiedOperationState) {
    TiAdmobUnifiedOperationStateNotStarted = 0,
    TiAdmobUnifiedOperationStateInFlight,
    TiAdmobUnifiedOperationStateComplete
};

@interface TiAdmobUnifiedModule ()

@property(nonatomic, assign) TiAdmobUnifiedOperationState initializationState;
@property(nonatomic, copy) NSDictionary *initializationResult;
@property(nonatomic, assign) TiAdmobUnifiedOperationState consentState;
@property(nonatomic, copy) NSDictionary *consentResult;

@end

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

    NSDictionary *cachedResult = nil;
    @synchronized(self) {
        if (self.initializationState == TiAdmobUnifiedOperationStateComplete) {
            cachedResult = self.initializationResult;
        } else if (self.initializationState == TiAdmobUnifiedOperationStateInFlight) {
            DebugLog(@"[DEBUG] Google Mobile Ads SDK initialization already in flight");
            return;
        } else {
            self.initializationState = TiAdmobUnifiedOperationStateInFlight;
        }
    }

    if (cachedResult != nil) {
        [self fireEvent:@"module_initialized" withObject:cachedResult];
        return;
    }

    DebugLog(@"[DEBUG] Initializing Google Mobile Ads SDK");

    // Configure request configuration if provided
    if (config != nil) {
        [self buildRequestConfiguration:config];
    }

    // Skip mediation adapter initialization when the application declares it
    // will not use mediation during this session. Adapters stay bundled; the
    // SDK just does not start them, so a network that never answers cannot
    // hold the first ad request. Must run before starting the SDK.
    if (config != nil && [TiUtils boolValue:[config objectForKey:@"disableMediation"] def:NO]) {
        DebugLog(@"[DEBUG] Disabling mediation adapter initialization for this session");
        [[GADMobileAds sharedInstance] disableMediationInitialization];
    }

    // Initialize the SDK
    [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *status) {
        DebugLog(@"[DEBUG] AdMob SDK initialization completed successfully");

        NSDictionary *event = @{
            @"success": @YES,
            @"status": status.description
        };

        @synchronized(self) {
            self.initializationResult = event;
            self.initializationState = TiAdmobUnifiedOperationStateComplete;
        }

        [self fireEvent:@"module_initialized" withObject:event];
    }];
}

- (void)openAdInspector:(id)args
{
    ENSURE_UI_THREAD(openAdInspector, args);

    [[GADMobileAds sharedInstance]
        presentAdInspectorFromViewController:nil
                           completionHandler:^(NSError *_Nullable error) {
        NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
        if (error == nil) {
            event[@"success"] = @YES;
        } else {
            event[@"success"] = @NO;
            event[@"error"] = error.localizedDescription;
            event[@"code"] = @(error.code);
        }
        [self fireEvent:@"ad_inspector_closed" withObject:event];
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
    
    NSString *ageTreatment = [TiUtils stringValue:[config objectForKey:@"ageRestrictedTreatment"]];
    if (ageTreatment == nil) {
        BOOL legacyChild = [config objectForKey:@"tagForChildDirectedTreatment"] != nil
            && [TiUtils boolValue:[config objectForKey:@"tagForChildDirectedTreatment"]];
        BOOL legacyUnderAge = [config objectForKey:@"tagForUnderAgeOfConsent"] != nil
            && [TiUtils boolValue:[config objectForKey:@"tagForUnderAgeOfConsent"]];
        ageTreatment = (legacyChild || legacyUnderAge) ? @"child" : @"unspecified";
    }

    if ([ageTreatment isEqualToString:@"child"]) {
        requestConfig.ageRestrictedTreatment = GADAgeRestrictedTreatmentChild;
    } else if ([ageTreatment isEqualToString:@"teen"]) {
        requestConfig.ageRestrictedTreatment = GADAgeRestrictedTreatmentTeen;
    } else {
        requestConfig.ageRestrictedTreatment = GADAgeRestrictedTreatmentUnspecified;
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

    NSDictionary *cachedResult = nil;
    @synchronized(self) {
        if (self.consentState == TiAdmobUnifiedOperationStateComplete) {
            cachedResult = self.consentResult;
        } else if (self.consentState == TiAdmobUnifiedOperationStateInFlight) {
            DebugLog(@"[DEBUG] Consent request already in flight");
            return;
        } else {
            self.consentState = TiAdmobUnifiedOperationStateInFlight;
        }
    }

    if (cachedResult != nil) {
        [self fireEvent:@"consent_complete" withObject:cachedResult];
        return;
    }

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
                [self completeConsentWithError:error];
                return;
            }

            DebugLog(@"[DEBUG] Consent info update successful");

            [UMPConsentForm loadAndPresentIfRequiredFromViewController:nil
                                                   completionHandler:^(NSError *_Nullable formError) {
                if (formError != nil) {
                    DebugLog(@"[ERROR] Consent form failed: %@", formError.localizedDescription);
                }
                [self completeConsentWithError:formError];
            }];
        }];
}

- (void)completeConsentWithError:(NSError *)error
{
    BOOL canRequestAds = UMPConsentInformation.sharedInstance.canRequestAds;
    BOOL privacyOptionsRequired =
        UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus
        == UMPPrivacyOptionsRequirementStatusRequired;

    NSMutableDictionary *result = [@{
        @"success": @(error == nil),
        @"canRequestAds": @(canRequestAds),
        @"privacyOptionsRequired": @(privacyOptionsRequired),
        // Compatibility payload keys retained for one transition release.
        @"canShowAds": @(canRequestAds),
        @"canShowPersonalizedAds": @NO,
        @"isGDPR": [self isGDPR:nil],
        @"isPrivacyOptionsRequired": @(privacyOptionsRequired)
    } mutableCopy];

    if (error != nil) {
        result[@"error"] = error.localizedDescription ?: @"Unknown consent error";
        result[@"code"] = @(error.code);
    }

    @synchronized(self) {
        self.consentResult = result;
        self.consentState = TiAdmobUnifiedOperationStateComplete;
    }

    if (error != nil) {
        [self fireEvent:@"consent_error" withObject:result];
    } else {
        [self fireEvent:@"consent_ready" withObject:result];
    }
    [self fireEvent:@"consent_complete" withObject:result];
}

// ===================================================================
// CONSENT STATUS METHODS
// ===================================================================
- (NSNumber *)canShowAds:(id)args
{
    return [self canRequestAds:args];
}

- (NSNumber *)canRequestAds:(id)args
{
    return @(UMPConsentInformation.sharedInstance.canRequestAds);
}

- (NSNumber *)canShowPersonalizedAds:(id)args
{
    // Deprecated: UMP deliberately does not expose a publisher-facing
    // "personalized" boolean. GMA applies the collected privacy signals.
    return @NO;
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
    [UMPConsentForm presentPrivacyOptionsFormFromViewController:nil
                                              completionHandler:^(NSError *_Nullable error) {
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        if (error != nil) {
            [result setObject:@NO forKey:@"success"];
            [result setObject:error.localizedDescription forKey:@"error"];
            [result setObject:@(error.code) forKey:@"code"];
        } else {
            [result setObject:@YES forKey:@"success"];
        }

        result[@"canRequestAds"] = @(UMPConsentInformation.sharedInstance.canRequestAds);
        result[@"privacyOptionsRequired"] =
            @(UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus
              == UMPPrivacyOptionsRequirementStatusRequired);
        [self fireEvent:@"privacy_options_dismissed" withObject:result];
    }];
}

- (void)resetConsent:(id)args
{
    [UMPConsentInformation.sharedInstance reset];
    @synchronized(self) {
        self.consentState = TiAdmobUnifiedOperationStateNotStarted;
        self.consentResult = nil;
    }
    DebugLog(@"[DEBUG] Consent information has been reset");
}

// ===================================================================
// iOS-SPECIFIC: APP TRACKING TRANSPARENCY
// ===================================================================
- (void)requestTrackingAuthorization:(id)args
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
    if (@available(iOS 14, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            NSDictionary *result = @{
                @"status": @(status),
                @"authorized": @(status == ATTrackingManagerAuthorizationStatusAuthorized),
                @"applicable": @YES
            };

            [self fireEvent:@"tracking_authorization_completed" withObject:result];
        }];
    } else {
        // iOS < 14, tracking authorization not required
        NSDictionary *result = @{
            @"status": @(3), // ATTrackingManagerAuthorizationStatusAuthorized equivalent
            @"authorized": @YES,
            @"applicable": @NO
        };
        [self fireEvent:@"tracking_authorization_completed" withObject:result];
    }
#else
    // iOS < 14, tracking authorization not required
    NSDictionary *result = @{
        @"status": @(3), // ATTrackingManagerAuthorizationStatusAuthorized equivalent
        @"authorized": @YES,
        @"applicable": @NO
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
    return [[TiAdmobUnifiedAppOpenAdProxy alloc] _initWithPageContext:[self executionContext] args:@[config]];
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
    return @(NSClassFromString(@"GADMediationAdapterAppLovin") != nil);
}

- (NSNumber *)isMetaAvailable:(id)args
{
    return @(NSClassFromString(@"GADMediationAdapterFacebook") != nil);
}

- (NSNumber *)isInMobiAvailable:(id)args
{
    return @(NSClassFromString(@"GADMediationAdapterInMobi") != nil);
}

- (NSNumber *)isVungleAvailable:(id)args
{
    return @(NSClassFromString(@"GADMediationAdapterVungle") != nil);
}

- (NSNumber *)isUnityAvailable:(id)args
{
    return @(NSClassFromString(@"GADMediationAdapterUnity") != nil);
}

- (NSNumber *)isIronSourceAvailable:(id)args
{
    return @(NSClassFromString(@"GADMediationAdapterIronSource") != nil);
}

- (NSDictionary *)getMediationStatus:(id)args
{
    return @{
        @"appLovin": [self isAppLovinAvailable:nil],
        @"meta": [self isMetaAvailable:nil],
        @"inMobi": [self isInMobiAvailable:nil],
        @"unity": [self isUnityAvailable:nil],
        @"liftoffMonetize": [self isVungleAvailable:nil],
        @"ironSource": [self isIronSourceAvailable:nil]
    };
}

#pragma mark - Legacy per-network consent compatibility

- (void)setAppLovinGDPRConsent:(id)args
{
    DebugLog(@"[WARN] setAppLovinGDPRConsent() is deprecated and intentionally does not translate one Boolean into regional privacy choices; use UMP and current provider requirements.");
}

- (void)setInMobiGDPRConsent:(id)args
{
    DebugLog(@"[WARN] setInMobiGDPRConsent() is deprecated and intentionally does not translate one Boolean into regional privacy choices; use UMP and current provider requirements.");
}

- (void)setVungleGDPRConsent:(id)args
{
    DebugLog(@"[WARN] setVungleGDPRConsent() is deprecated and intentionally does not translate one Boolean into regional privacy choices; use UMP and current provider requirements.");
}

- (void)enableOptionalMediationNetworks:(id)args
{
    DebugLog(@"[DEBUG] Mediation adapters are auto-discovered by Google Mobile Ads: %@",
             [self getMediationStatus:nil]);
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
// The two COLLAPSIBLE_* constants were removed in 1.3.0. They carried the
// legacy collapsible_top / collapsible_bottom values, which Google's SDK does
// not accept: the native placement strings are top and bottom, and the module
// forwarded the value verbatim, so passing the constants built an invalid
// request. Pass the native string to `collapsible` instead.

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

// Age-restricted treatment values
- (NSString *)AGE_RESTRICTED_TREATMENT_CHILD { return @"child"; }
- (NSString *)AGE_RESTRICTED_TREATMENT_TEEN { return @"teen"; }
- (NSString *)AGE_RESTRICTED_TREATMENT_UNSPECIFIED { return @"unspecified"; }

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

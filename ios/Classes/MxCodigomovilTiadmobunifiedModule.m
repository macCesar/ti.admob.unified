/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "MxCodigomovilTiadmobunifiedModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "MxCodigomovilTiadmobunifiedRewardedAdProxy.h"
#import "MxCodigomovilTiadmobunifiedInterstitialAdProxy.h"

@implementation MxCodigomovilTiadmobunifiedModule

#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"67829dbd-d857-4749-9e7c-6143caedee43";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"mx.codigomovil.tiadmobunified";
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

// ===================================================================
// AD TYPE CONSTANTS
// ===================================================================
MACRO_DEF(AD_TYPE_BANNER, @"banner");
MACRO_DEF(AD_TYPE_INTERSTITIAL, @"interstitial");
MACRO_DEF(AD_TYPE_REWARDED, @"rewarded");
MACRO_DEF(AD_TYPE_REWARDED_INTERSTITIAL, @"rewarded_interstitial");
MACRO_DEF(AD_TYPE_APP_OPEN, @"app_open");
MACRO_DEF(AD_TYPE_NATIVE, @"native");

// ===================================================================
// BANNER SIZE CONSTANTS
// ===================================================================
MACRO_DEF(BANNER, @"banner");
MACRO_DEF(LARGE_BANNER, @"large_banner");
MACRO_DEF(MEDIUM_RECTANGLE, @"medium_rectangle");
MACRO_DEF(FULLBANNER, @"fullbanner");
MACRO_DEF(LEADERBOARD, @"leaderboard");
MACRO_DEF(ADAPTIVE_ANCHORED, @"adaptive_anchored");
MACRO_DEF(ADAPTIVE_INLINE, @"adaptive_inline");
MACRO_DEF(COLLAPSIBLE_TOP, @"collapsible_top");
MACRO_DEF(COLLAPSIBLE_BOTTOM, @"collapsible_bottom");

// ===================================================================
// EVENT CONSTANTS (UNIFIED NAMING)
// ===================================================================
MACRO_DEF(AD_LOADED, @"loaded");
MACRO_DEF(AD_FAILED_TO_LOAD, @"failed_to_load");
MACRO_DEF(AD_OPENED, @"opened");
MACRO_DEF(AD_CLOSED, @"closed");
MACRO_DEF(AD_CLICKED, @"clicked");
MACRO_DEF(AD_IMPRESSION, @"impression");
MACRO_DEF(AD_REWARDED, @"rewarded");
MACRO_DEF(AD_FAILED_TO_SHOW, @"failed_to_show");
MACRO_DEF(AD_SHOWED_FULLSCREEN_CONTENT, @"showed_fullscreen_content");
MACRO_DEF(AD_DESTROYED, @"destroyed");

// ===================================================================
// CONSENT/COMPLIANCE CONSTANTS
// ===================================================================
MACRO_DEF(CONSENT_STATUS_UNKNOWN, NUMINT(UMPConsentStatusUnknown));
MACRO_DEF(CONSENT_STATUS_REQUIRED, NUMINT(UMPConsentStatusRequired));
MACRO_DEF(CONSENT_STATUS_NOT_REQUIRED, NUMINT(UMPConsentStatusNotRequired));
MACRO_DEF(CONSENT_STATUS_OBTAINED, NUMINT(UMPConsentStatusObtained));

// Debug Geography Constants
MACRO_DEF(DEBUG_GEOGRAPHY_DISABLED, NUMINT(UMPDebugGeographyDisabled));
MACRO_DEF(DEBUG_GEOGRAPHY_EEA, NUMINT(UMPDebugGeographyEEA));
MACRO_DEF(DEBUG_GEOGRAPHY_REGULATED_US_STATE, NUMINT(UMPDebugGeographyRegulatedUSState));
MACRO_DEF(DEBUG_GEOGRAPHY_OTHER, NUMINT(UMPDebugGeographyOther));

// iOS Tracking Authorization Constants (iOS 14+ only)
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
MACRO_DEF(TRACKING_AUTHORIZATION_STATUS_NOT_DETERMINED, NUMINT(ATTrackingManagerAuthorizationStatusNotDetermined));
MACRO_DEF(TRACKING_AUTHORIZATION_STATUS_RESTRICTED, NUMINT(ATTrackingManagerAuthorizationStatusRestricted));
MACRO_DEF(TRACKING_AUTHORIZATION_STATUS_DENIED, NUMINT(ATTrackingManagerAuthorizationStatusDenied));
MACRO_DEF(TRACKING_AUTHORIZATION_STATUS_AUTHORIZED, NUMINT(ATTrackingManagerAuthorizationStatusAuthorized));
#else
// Fallback for iOS < 14
MACRO_DEF(TRACKING_AUTHORIZATION_STATUS_NOT_DETERMINED, NUMINT(0));
MACRO_DEF(TRACKING_AUTHORIZATION_STATUS_RESTRICTED, NUMINT(1));
MACRO_DEF(TRACKING_AUTHORIZATION_STATUS_DENIED, NUMINT(2));
MACRO_DEF(TRACKING_AUTHORIZATION_STATUS_AUTHORIZED, NUMINT(3));
#endif

// Content Rating Constants
MACRO_DEF(MAX_AD_CONTENT_RATING_GENERAL, @"G");
MACRO_DEF(MAX_AD_CONTENT_RATING_PARENTAL_GUIDANCE, @"PG");
MACRO_DEF(MAX_AD_CONTENT_RATING_TEEN, @"T");
MACRO_DEF(MAX_AD_CONTENT_RATING_MATURE_AUDIENCE, @"MA");

// ===================================================================
// ERROR CODE CONSTANTS
// ===================================================================
MACRO_DEF(ERROR_CODE_NETWORK_ERROR, NUMINT(2));
MACRO_DEF(ERROR_CODE_NO_FILL, NUMINT(3));
MACRO_DEF(ERROR_CODE_INVALID_REQUEST, NUMINT(1));
MACRO_DEF(ERROR_CODE_SERVER_ERROR, NUMINT(0));
MACRO_DEF(ERROR_CODE_APP_ID_MISSING, NUMINT(8));
MACRO_DEF(ERROR_CODE_MEDIATION_NO_FILL, NUMINT(9));
MACRO_DEF(ERROR_CODE_INVALID_AD_SIZE, NUMINT(10));

// ===================================================================
// TEST AD UNIT IDS (OFFICIAL GOOGLE TEST IDS)
// ===================================================================
MACRO_DEF(TEST_BANNER, @"ca-app-pub-3940256099942544/6300978111");
MACRO_DEF(TEST_ADAPTIVE_BANNER, @"ca-app-pub-3940256099942544/9214589741");
MACRO_DEF(TEST_INTERSTITIAL, @"ca-app-pub-3940256099942544/1033173712");
MACRO_DEF(TEST_INTERSTITIAL_VIDEO, @"ca-app-pub-3940256099942544/8691691433");
MACRO_DEF(TEST_REWARDED, @"ca-app-pub-3940256099942544/5224354917");
MACRO_DEF(TEST_REWARDED_INTERSTITIAL, @"ca-app-pub-3940256099942544/5354046379");
MACRO_DEF(TEST_NATIVE, @"ca-app-pub-3940256099942544/2247696110");
MACRO_DEF(TEST_APP_OPEN, @"ca-app-pub-3940256099942544/9257395921");

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
        GADMobileAds.sharedInstance.requestConfiguration = [self buildRequestConfiguration:config];
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
        @"canShowAds": @([self canShowAds:nil]),
        @"canShowPersonalizedAds": @([self canShowPersonalizedAds:nil]),
        @"isGDPR": @([self isGDPR:nil]),
        @"isPrivacyOptionsRequired": @([self isPrivacyOptionsRequired:nil])
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
    // Check TCF string for personalized ads consent
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *tcString = [userDefaults stringForKey:@"IABTCF_TCString"] ?: @"";
    
    // Simplified check - in real implementation, you'd parse the TC string properly
    return @(![tcString isEqualToString:@""] && [tcString containsString:@"1"]);
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
    return [[MxCodigomovilTiadmobunifiedRewardedAdProxy alloc] _initWithPageContext:[self executionContext] args:@[config]];
}

- (id)createInterstitial:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    
    DebugLog(@"[DEBUG] Creating interstitial ad");
    return [[MxCodigomovilTiadmobunifiedInterstitialAdProxy alloc] _initWithPageContext:[self executionContext] args:@[config]];
}

- (id)createBanner:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    
    DebugLog(@"[DEBUG] Creating banner ad");
    // TODO: Implement banner ad proxy
    return nil;
}

- (id)createAdaptiveBanner:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    
    DebugLog(@"[DEBUG] Creating adaptive banner ad");
    // TODO: Implement adaptive banner ad proxy
    return nil;
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
    ENSURE_ARG_COUNT(args, 1);
    NSString *volume = [TiUtils stringValue:[args objectAtIndex:0]];
    
    // Convert percentage string to float
    NSString *cleanVolume = [volume stringByReplacingOccurrencesOfString:@"%" withString:@""];
    float volumeValue = [cleanVolume floatValue] / 100.0f;
    
    [GADMobileAds.sharedInstance.applicationAudioVolumeProvider setApplicationVolume:volumeValue];
    DebugLog(@"[DEBUG] App volume set to: %f", volumeValue);
}

- (void)setTestDevice:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    NSString *deviceId = [TiUtils stringValue:[args objectAtIndex:0]];
    
    // Set test device through RequestConfiguration
    GADRequestConfiguration *requestConfig = GADMobileAds.sharedInstance.requestConfiguration;
    requestConfig.testDeviceIdentifiers = @[deviceId];
    
    DebugLog(@"[DEBUG] Test device ID set: %@", deviceId);
}

- (NSNumber *)isTestDevice:(id)args
{
    // This would require tracking test device status
    // For now, return false as default implementation
    return @NO;
}

@end

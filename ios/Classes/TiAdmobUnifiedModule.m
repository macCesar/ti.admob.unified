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
#import <math.h>
#import "TiHost.h"
#import "TiApp.h"
#import "TiUtils.h"
#import "TiAdmobUnifiedRewardedAdProxy.h"
#import "TiAdmobUnifiedAdaptiveBannerAdProxy.h"
#import "TiAdmobUnifiedInterstitialAdProxy.h"
#import "TiAdmobUnifiedBannerAdProxy.h"
#import "TiAdmobUnifiedAppOpenAdProxy.h"

static void TiAdmobForward(id target, NSString *name, id first, id second)
{
    SEL selector = NSSelectorFromString(name);
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    if (signature == nil) return;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = selector;
    [invocation setArgument:&first atIndex:2];
    [invocation setArgument:&second atIndex:3];
    [invocation invokeWithTarget:target];
}

@implementation TiAdmobUnifiedNativeDelegate
- (void)bannerViewDidReceiveAd:(GADBannerView *)value { TiAdmobForward(self.target, @"bannerViewDidReceiveAd:internal:", value, nil); }
- (void)bannerViewDidRecordImpression:(GADBannerView *)value { TiAdmobForward(self.target, @"bannerViewDidRecordImpression:internal:", value, nil); }
- (void)bannerViewDidRecordClick:(GADBannerView *)value { TiAdmobForward(self.target, @"bannerViewDidRecordClick:internal:", value, nil); }
- (void)bannerViewWillPresentScreen:(GADBannerView *)value { TiAdmobForward(self.target, @"bannerViewWillPresentScreen:internal:", value, nil); }
- (void)bannerViewWillDismissScreen:(GADBannerView *)value { TiAdmobForward(self.target, @"bannerViewWillDismissScreen:internal:", value, nil); }
- (void)bannerViewDidDismissScreen:(GADBannerView *)value { TiAdmobForward(self.target, @"bannerViewDidDismissScreen:internal:", value, nil); }
- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)value { TiAdmobForward(self.target, @"adDidRecordImpression:internal:", value, nil); }
- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)value { TiAdmobForward(self.target, @"adDidRecordClick:internal:", value, nil); }
- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)value { TiAdmobForward(self.target, @"adWillPresentFullScreenContent:internal:", value, nil); }
- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)value { TiAdmobForward(self.target, @"adDidDismissFullScreenContent:internal:", value, nil); }
- (void)applicationDidEnterBackground:(NSNotification *)value { TiAdmobForward(self.target, @"applicationDidEnterBackground:internal:", value, nil); }
- (void)applicationWillEnterForeground:(NSNotification *)value { TiAdmobForward(self.target, @"applicationWillEnterForeground:internal:", value, nil); }
- (void)bannerView:(GADBannerView *)view didFailToReceiveAdWithError:(NSError *)error
{ TiAdmobForward(self.target, @"bannerView:didFailToReceiveAdWithError:", view, error); }
- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error
{ TiAdmobForward(self.target, @"ad:didFailToPresentFullScreenContentWithError:", ad, error); }
@end

typedef NS_ENUM(NSInteger, TiAdmobUnifiedOperationState) {
    TiAdmobUnifiedOperationStateNotStarted = 0,
    TiAdmobUnifiedOperationStateInFlight,
    TiAdmobUnifiedOperationStateComplete,
    TiAdmobUnifiedOperationStateFailed
};

@interface TiAdmobUnifiedModule ()
{
    TiAdmobUnifiedOperationState _initializationState;
    NSDictionary * _initializationResult;
    TiAdmobUnifiedOperationState _consentState;
    NSDictionary * _consentResult;
    BOOL _consentResetPending;
    BOOL _privacyInFlight;
    NSDictionary *_queuedConsent;
}


@end

@implementation TiAdmobUnifiedModule

+ (BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

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

// Returns the collapsed placement size, not the expanded creative's overlay.
- (NSDictionary *)getAnchoredAdaptiveBannerSize:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    CGFloat width = [TiUtils doubleValue:[args objectAtIndex:0]];
    if (!isfinite(width) || width <= 0) {
        [NSException raise:NSInvalidArgumentException format:@"Banner width must be positive and finite"];
    }
    __block CGSize size;
    TiThreadPerformOnMainThread(^{
        size = GADLargeAnchoredAdaptiveBannerAdSizeWithWidth(width).size;
    }, YES);
    return @{ @"width": @(size.width), @"height": @(size.height), @"heightUnit": @"dp" };
}

#pragma mark Public APIs

// ===================================================================
// SDK INITIALIZATION METHODS
// ===================================================================
- (void)initialize:(id)args
{
    ENSURE_UI_THREAD(initialize, args);
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    ENSURE_TYPE(config, NSDictionary);

    NSDictionary *cachedResult = nil;
    @synchronized(self) {
        if (self->_initializationState == TiAdmobUnifiedOperationStateComplete) {
            cachedResult = self->_initializationResult;
        } else if (self->_initializationState == TiAdmobUnifiedOperationStateInFlight) {
            DebugLog(@"[DEBUG] Google Mobile Ads SDK initialization already in flight");
            return;
        } else {
            self->_initializationState = TiAdmobUnifiedOperationStateInFlight;
        }
    }

    if (cachedResult != nil) {
        [self fireEvent:@"module_initialized" withObject:cachedResult];
        return;
    }

    @try {
    DebugLog(@"[DEBUG] Initializing Google Mobile Ads SDK");

    // Configure request configuration if provided
    if (config != nil) {
        [self buildRequestConfiguration:config internal:nil];
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
            self->_initializationResult = event;
            self->_initializationState = TiAdmobUnifiedOperationStateComplete;
        }

        [self fireEvent:@"module_initialized" withObject:event];
    }];
    } @catch (NSException *exception) {
        @synchronized(self) { self->_initializationState = TiAdmobUnifiedOperationStateFailed; }
        @throw;
    }
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

- (GADRequestConfiguration *)buildRequestConfiguration:(NSDictionary *)config internal:(id)unused
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
    ENSURE_UI_THREAD(requestConsent, args);
    if (_consentResetPending || _privacyInFlight) {
        ENSURE_ARG_COUNT(args, 1);
        NSDictionary *config = [args objectAtIndex:0];
        ENSURE_TYPE(config, NSDictionary);
        _queuedConsent = [config copy];
        return;
    }
    ENSURE_ARG_COUNT(args, 1);
    NSDictionary *config = [args objectAtIndex:0];
    ENSURE_TYPE(config, NSDictionary);

    NSDictionary *cachedResult = nil;
    @synchronized(self) {
        if (self->_consentState == TiAdmobUnifiedOperationStateComplete) {
            cachedResult = self->_consentResult;
        } else if (self->_consentState == TiAdmobUnifiedOperationStateInFlight) {
            DebugLog(@"[DEBUG] Consent request already in flight");
            return;
        } else {
            self->_consentState = TiAdmobUnifiedOperationStateInFlight;
        }
    }

    if (cachedResult != nil) {
        [self fireEvent:@"consent_complete" withObject:cachedResult];
        return;
    }

    @try {
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
            if ([self finishPendingConsentReset:nil context:nil]) return;
            if (error) {
                DebugLog(@"[ERROR] Consent info update failed: %@", error.localizedDescription);
                [self completeConsentWithError:error internal:nil];
                return;
            }

            DebugLog(@"[DEBUG] Consent info update successful");

            [UMPConsentForm loadAndPresentIfRequiredFromViewController:nil
                                                   completionHandler:^(NSError *_Nullable formError) {
                if (formError != nil) {
                    DebugLog(@"[ERROR] Consent form failed: %@", formError.localizedDescription);
                }
                [self completeConsentWithError:formError internal:nil];
            }];
        }];
    } @catch (NSException *exception) {
        @synchronized(self) { self->_consentState = TiAdmobUnifiedOperationStateNotStarted; }
        @throw;
    }
}

- (void)completeConsentWithError:(NSError *)error internal:(id)unused
{
    if ([self finishPendingConsentReset:nil context:nil]) return;
    BOOL canRequestAds = UMPConsentInformation.sharedInstance.canRequestAds;
    BOOL privacyOptionsRequired =
        UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus
        == UMPPrivacyOptionsRequirementStatusRequired;

    NSMutableDictionary *result = [@{
        @"success": [NSNumber numberWithBool:(error == nil)],
        @"canRequestAds": [NSNumber numberWithBool:(canRequestAds)],
        @"privacyOptionsRequired": [NSNumber numberWithBool:(privacyOptionsRequired)],
        // Compatibility payload keys retained for one transition release.
        @"canShowAds": [NSNumber numberWithBool:(canRequestAds)],
        @"canShowPersonalizedAds": @NO,
        @"isGDPR": [self isGDPR:nil],
        @"isPrivacyOptionsRequired": [NSNumber numberWithBool:(privacyOptionsRequired)]
    } mutableCopy];

    if (error != nil) {
        result[@"error"] = error.localizedDescription ?: @"Unknown consent error";
        result[@"code"] = @(error.code);
    }

    @synchronized(self) {
        self->_consentResult = result;
        self->_consentState = error == nil ? TiAdmobUnifiedOperationStateComplete : TiAdmobUnifiedOperationStateNotStarted;
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
    return [NSNumber numberWithBool:(UMPConsentInformation.sharedInstance.canRequestAds)];
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
    return [NSNumber numberWithBool:([gdprApplies isEqualToString:@"1"])];
}

- (NSNumber *)isPrivacyOptionsRequired:(id)args
{
    return [NSNumber numberWithBool:(UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == UMPPrivacyOptionsRequirementStatusRequired)];
}

- (void)presentPrivacyOptions:(id)args
{
    ENSURE_UI_THREAD(presentPrivacyOptions, args);
    if (_privacyInFlight) return;
    if (_consentState == TiAdmobUnifiedOperationStateInFlight) {
        [self fireEvent:@"privacy_options_dismissed" withObject:@{
            @"success": @NO, @"code": @(-1), @"error": @"Consent request is still in progress",
            @"canRequestAds": [self canRequestAds:nil], @"privacyOptionsRequired": [self isPrivacyOptionsRequired:nil]}];
        return;
    }
    _privacyInFlight = YES;
    [UMPConsentForm presentPrivacyOptionsFormFromViewController:nil
                                              completionHandler:^(NSError *_Nullable error) {
        _privacyInFlight = NO;
        if (_consentResetPending) {
            [self fireEvent:@"privacy_options_dismissed" withObject:@{
                @"success": @NO, @"code": @(-1), @"error": @"Consent reset during privacy options",
                @"canRequestAds": @NO, @"privacyOptionsRequired": @NO}];
            [self finishPendingConsentReset:nil context:nil];
            return;
        }
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        if (error != nil) {
            [result setObject:@NO forKey:@"success"];
            [result setObject:error.localizedDescription forKey:@"error"];
            [result setObject:@(error.code) forKey:@"code"];
        } else {
            [result setObject:@YES forKey:@"success"];
        }

        result[@"canRequestAds"] = [NSNumber numberWithBool:(UMPConsentInformation.sharedInstance.canRequestAds)];
        result[@"privacyOptionsRequired"] =
            [NSNumber numberWithBool:(UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus
              == UMPPrivacyOptionsRequirementStatusRequired)];
        // Rebuild cached compatibility fields from the current UMP state.
        @synchronized(self) {
            NSMutableDictionary *cached = [result mutableCopy];
            cached[@"canShowAds"] = result[@"canRequestAds"];
            cached[@"canShowPersonalizedAds"] = @NO;
            cached[@"isGDPR"] = [self isGDPR:nil];
            cached[@"isPrivacyOptionsRequired"] = result[@"privacyOptionsRequired"];
            self->_consentResult = cached;
            self->_consentState = error == nil ? TiAdmobUnifiedOperationStateComplete : TiAdmobUnifiedOperationStateNotStarted;
        }
        [self fireEvent:@"privacy_options_dismissed" withObject:result];
        NSDictionary *next = _queuedConsent;
        _queuedConsent = nil;
        if (next != nil) [self requestConsent:@[next]];
    }];
}

// Reset only after UMP's outstanding update/form completes. UMP callbacks can
// mutate SDK state, so ignoring a callback alone would not cancel the operation.
- (BOOL)finishPendingConsentReset:(id)unused context:(id)context
{
    if (!_consentResetPending) return NO;
    NSDictionary *next = _queuedConsent;
    _queuedConsent = nil;
    _consentResetPending = NO;
    _consentState = TiAdmobUnifiedOperationStateNotStarted;
    [self resetConsent:nil];
    if (next != nil) [self requestConsent:@[next]];
    else [self completeConsentWithError:[NSError errorWithDomain:@"ti.admob.unified" code:-1
        userInfo:@{NSLocalizedDescriptionKey: @"Consent reset during request"}] internal:nil];
    return YES;
}

- (void)resetConsent:(id)args
{
    ENSURE_UI_THREAD(resetConsent, args);
    if (_consentState == TiAdmobUnifiedOperationStateInFlight || _privacyInFlight) {
        _consentResetPending = YES;
        _queuedConsent = nil;
        return;
    }
    [UMPConsentInformation.sharedInstance reset];
    @synchronized(self) {
        self->_consentState = TiAdmobUnifiedOperationStateNotStarted;
        self->_consentResult = nil;
    }
    DebugLog(@"[DEBUG] Consent information has been reset");
}

// ===================================================================
// iOS-SPECIFIC: APP TRACKING TRANSPARENCY
// ===================================================================
- (void)requestTrackingAuthorization:(id)args
{
    ENSURE_UI_THREAD(requestTrackingAuthorization, args);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
    if (@available(iOS 14, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            NSDictionary *result = @{
                @"status": @(status),
                @"authorized": [NSNumber numberWithBool:(status == ATTrackingManagerAuthorizationStatusAuthorized)],
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
    id valueArgument = [args isKindOfClass:[NSArray class]] ? ([args count] ? [args objectAtIndex:0] : nil) : args;
    NSString *value = [[TiUtils stringValue:valueArgument] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if ([value hasSuffix:@"%"]) value = [value substringToIndex:value.length - 1];
    NSScanner *scanner = [NSScanner scannerWithString:value ?: @""];
    double percentage;
    if (![scanner scanDouble:&percentage] || !scanner.isAtEnd || !isfinite(percentage) || percentage < 0 || percentage > 100) {
        DebugLog(@"[WARN] App volume requires a finite percentage between 0 and 100");
        return;
    }
    TiThreadPerformOnMainThread(^{
        GADMobileAds.sharedInstance.applicationVolume = percentage / 100.0;
    }, YES);
}

- (void)setTestDevice:(id)args
{
    id value = [args isKindOfClass:[NSArray class]] ? ([args count] ? [args objectAtIndex:0] : nil) : args;
    NSString *deviceId = [TiUtils stringValue:value];
    if (deviceId.length == 0) return;

    GADRequestConfiguration *requestConfig = GADMobileAds.sharedInstance.requestConfiguration;
    requestConfig.testDeviceIdentifiers = @[deviceId];

    DebugLog(@"[DEBUG] Test device ID set");
}

- (NSNumber *)isTestDevice:(id)args
{
    // Returns YES if any test device IDs have been registered via setTestDevice().
    NSArray<NSString *> *testIds = GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers;
    return [NSNumber numberWithBool:(testIds != nil && testIds.count > 0)];
}

#pragma mark - Mediation diagnostics

- (NSDictionary *)getMediationStatus:(id)args
{
    __block NSDictionary *result;
    TiThreadPerformOnMainThread(^{
        TiAdmobUnifiedOperationState current;
        @synchronized(self) { current = self->_initializationState; }
        NSString *state = @"not_started";
        switch (current) {
            case TiAdmobUnifiedOperationStateInFlight: state = @"initializing"; break;
            case TiAdmobUnifiedOperationStateComplete: state = @"completed"; break;
            case TiAdmobUnifiedOperationStateFailed: state = @"failed"; break;
            default: break;
        }
        NSMutableArray *adapters = [NSMutableArray array];
        if (current != TiAdmobUnifiedOperationStateNotStarted) {
            NSDictionary<NSString *, GADAdapterStatus *> *statuses = GADMobileAds.sharedInstance.initializationStatus.adapterStatusesByClassName;
            for (NSString *adapterClass in [[statuses allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
                GADAdapterStatus *adapter = statuses[adapterClass];
                [adapters addObject:@{
                    @"adapterClass": adapterClass,
                    @"state": adapter.state == GADAdapterInitializationStateReady ? @"ready" : @"not_ready",
                    @"description": adapter.description ?: @"",
                    @"latencyMs": @(llround(adapter.latency * 1000.0))
                }];
            }
        }
        result = @{ @"initializationState": state, @"adapters": adapters };
    }, YES);
    return result;
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
// There is deliberately no COLLAPSIBLE_TOP / COLLAPSIBLE_BOTTOM constant.
// Earlier internal builds exported both, carrying the collapsible_top and
// collapsible_bottom values, which Google's SDK does not accept: the native
// placement strings are top and bottom, and the module forwarded the value
// verbatim, so passing the constants built an invalid request. Pass the
// native string to `collapsible` instead.

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

// UMP debug geography — values mirror Android's ConsentDebugSettings.DebugGeography
// (DISABLED=0, EEA=1, REGULATED_US_STATE=3, OTHER=4).
- (NSNumber *)DEBUG_GEOGRAPHY_DISABLED { return @(UMPDebugGeographyDisabled); }
- (NSNumber *)DEBUG_GEOGRAPHY_EEA { return @(UMPDebugGeographyEEA); }
- (NSNumber *)DEBUG_GEOGRAPHY_OTHER { return @(UMPDebugGeographyOther); }
- (NSNumber *)DEBUG_GEOGRAPHY_REGULATED_US_STATE { return @(UMPDebugGeographyRegulatedUSState); }

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

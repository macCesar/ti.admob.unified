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

// Load failures use the shared JavaScript ERROR_CODE_* values. Presentation,
// UMP and Ad Inspector retain their own native error-code domains.
static inline NSInteger TiAdmobUnifiedLoadErrorCode(NSError *error)
{
    NSError *cause = error;
    for (NSUInteger depth = 0; cause != nil && depth < 4; depth++) {
        NSLog(@"[DEBUG] Ad load error domain=%@ code=%ld", cause.domain, (long)cause.code);
        id next = cause.userInfo[NSUnderlyingErrorKey];
        cause = [next isKindOfClass:[NSError class]] ? next : nil;
    }
    if (![error.domain isEqualToString:GADErrorDomain]) return 0;
    switch (error.code) {
        case GADErrorInvalidRequest:
        case GADErrorInvalidArgument:
        case GADErrorAdAlreadyUsed:
        case GADErrorReceivedInvalidAdString: return 1;
        case GADErrorNoFill: return 3;
        case GADErrorNetworkError:
        case GADErrorTimeout: return 2;
        case GADErrorMediationDataError:
        case GADErrorMediationAdapterError: return 0;
        case GADErrorMediationInvalidAdSize: return 10;
        case GADErrorApplicationIdentifierMissing: return 8;
        default: return 0;
    }
}

@interface TiAdmobUnifiedNativeDelegate : NSObject <GADBannerViewDelegate, GADFullScreenContentDelegate>
@property(nonatomic, weak) id target;
@end

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
- (NSDictionary *)getMediationStatus:(id)args;

@end

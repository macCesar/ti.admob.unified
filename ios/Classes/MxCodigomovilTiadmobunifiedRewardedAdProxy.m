/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "MxCodigomovilTiadmobunifiedRewardedAdProxy.h"
#import "TiUtils.h"

@implementation MxCodigomovilTiadmobunifiedRewardedAdProxy

- (id)_initWithPageContext:(id<TiEvaluator>)context args:(NSArray *)args
{
    self = [super _initWithPageContext:context];
    if (self) {
        if ([args count] > 0) {
            NSDictionary *config = [args objectAtIndex:0];
            [self configureWithDict:config];
        }
    }
    return self;
}

- (void)configureWithDict:(NSDictionary *)config
{
    if (config == nil) {
        return;
    }
    
    // Ad Unit ID (required)
    self.adUnitId = [TiUtils stringValue:[config objectForKey:@"adUnitId"]] ?: @"";
    
    // Auto-reload setting (default: false, but recommended: true)
    self.autoReload = [TiUtils boolValue:[config objectForKey:@"autoReload"] def:NO];
    
    // Keywords for targeting
    if ([config objectForKey:@"keywords"]) {
        self.keywords = [config objectForKey:@"keywords"];
    }
    
    // Extra parameters for mediation networks
    if ([config objectForKey:@"extras"]) {
        self.extras = [config objectForKey:@"extras"];
    }
    
    DebugLog(@"[DEBUG] Rewarded ad configured with unit ID: %@, autoReload: %@", 
             self.adUnitId, self.autoReload ? @"YES" : @"NO");
}

#pragma mark - Public API Methods

- (void)load:(id)args
{
    DebugLog(@"[DEBUG] Loading rewarded ad: %@", self.adUnitId);
    
    if ([self.adUnitId length] == 0) {
        DebugLog(@"[ERROR] Cannot load ad - no ad unit ID provided");
        
        NSDictionary *errorEvent = @{
            @"error": @"No ad unit ID provided",
            @"code": @(1),
            @"adUnitId": self.adUnitId ?: @""
        };
        [self fireEvent:@"failed_to_load" withObject:errorEvent];
        return;
    }
    
    GADRequest *request = [self buildAdRequest];
    
    [GADRewardedAd loadWithAdUnitID:self.adUnitId
                            request:request
                  completionHandler:^(GADRewardedAd *ad, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                DebugLog(@"[ERROR] Rewarded ad failed to load: %@", error.localizedDescription);
                
                NSDictionary *errorEvent = @{
                    @"error": error.localizedDescription,
                    @"code": @(error.code),
                    @"adUnitId": self.adUnitId
                };
                [self fireEvent:@"failed_to_load" withObject:errorEvent];
                return;
            }
            
            DebugLog(@"[DEBUG] Rewarded ad loaded successfully");\n            self.rewardedAd = ad;\n            self.rewardedAd.fullScreenContentDelegate = self;\n            \n            NSDictionary *loadedEvent = @{\n                @"adUnitId": self.adUnitId\n            };\n            [self fireEvent:@"loaded" withObject:loadedEvent];\n        });\n    }];\n}\n\n- (GADRequest *)buildAdRequest\n{\n    GADRequest *request = [GADRequest request];\n    \n    // Add keywords if provided\n    if (self.keywords && [self.keywords count] > 0) {\n        // Keywords are set via GADExtras for mediation networks\n        GADExtras *extras = [[GADExtras alloc] init];\n        NSMutableDictionary *extrasDict = [[NSMutableDictionary alloc] init];\n        \n        // Add keywords\n        [extrasDict setObject:[self.keywords componentsJoinedByString:@","] forKey:@"keywords"];\n        \n        // Add any additional extras\n        if (self.extras) {\n            [extrasDict addEntriesFromDictionary:self.extras];\n        }\n        \n        extras.additionalParameters = extrasDict;\n        [request registerAdNetworkExtras:extras];\n    } else if (self.extras) {\n        // Just add extras without keywords\n        GADExtras *extras = [[GADExtras alloc] init];\n        extras.additionalParameters = self.extras;\n        [request registerAdNetworkExtras:extras];\n    }\n    \n    return request;\n}\n\n- (void)show:(id)args\n{\n    if (!self.rewardedAd) {\n        DebugLog(@"[ERROR] Cannot show rewarded ad - ad not loaded");\n        \n        NSDictionary *errorEvent = @{\n            @"error": @"Ad not loaded",\n            @"adUnitId": self.adUnitId\n        };\n        [self fireEvent:@"failed_to_show" withObject:errorEvent];\n        return;\n    }\n    \n    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;\n    \n    [self.rewardedAd presentFromRootViewController:rootViewController\n                              userDidEarnRewardHandler:^{\n        DebugLog(@"[DEBUG] User earned reward");\n        \n        // Get reward information\n        GADAdReward *reward = self.rewardedAd.adReward;\n        \n        NSDictionary *rewardEvent = @{\n            @"rewardType": reward.type ?: @"coins",\n            @"rewardAmount": reward.amount ?: @(1),\n            @"adUnitId": self.adUnitId\n        };\n        [self fireEvent:@"rewarded" withObject:rewardEvent];\n    }];\n}\n\n- (NSNumber *)isLoaded:(id)args\n{\n    return @(self.rewardedAd != nil);\n}\n\n- (void)destroy:(id)args\n{\n    DebugLog(@"[DEBUG] Destroying rewarded ad");\n    \n    self.rewardedAd = nil;\n    \n    NSDictionary *destroyEvent = @{\n        @"adUnitId": self.adUnitId\n    };\n    [self fireEvent:@"destroyed" withObject:destroyEvent];\n}\n\n#pragma mark - GADFullScreenContentDelegate\n\n- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad\n{\n    DebugLog(@"[DEBUG] Rewarded ad recorded impression");\n    \n    NSDictionary *impressionEvent = @{\n        @"adUnitId": self.adUnitId\n    };\n    [self fireEvent:@"impression" withObject:impressionEvent];\n}\n\n- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad\n{\n    DebugLog(@"[DEBUG] Rewarded ad was clicked");\n    \n    NSDictionary *clickEvent = @{\n        @"adUnitId": self.adUnitId\n    };\n    [self fireEvent:@"clicked" withObject:clickEvent];\n}\n\n- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error\n{\n    DebugLog(@"[ERROR] Rewarded ad failed to present: %@", error.localizedDescription);\n    \n    NSDictionary *errorEvent = @{\n        @"error": error.localizedDescription,\n        @"code": @(error.code),\n        @"adUnitId": self.adUnitId\n    };\n    [self fireEvent:@"failed_to_show" withObject:errorEvent];\n}\n\n- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad\n{\n    DebugLog(@"[DEBUG] Rewarded ad will present full screen content");\n    \n    NSDictionary *openEvent = @{\n        @"adUnitId": self.adUnitId\n    };\n    [self fireEvent:@"opened" withObject:openEvent];\n}\n\n- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad\n{\n    DebugLog(@"[DEBUG] Rewarded ad dismissed full screen content");\n    \n    NSDictionary *closeEvent = @{\n        @"adUnitId": self.adUnitId\n    };\n    [self fireEvent:@"closed" withObject:closeEvent];\n    \n    // Auto-reload if enabled (iOS can reuse the same object, but we'll reload for consistency)\n    if (self.autoReload) {\n        DebugLog(@"[DEBUG] Auto-reloading rewarded ad");\n        [self load:nil];\n    } else {\n        // Clear the ad reference if not auto-reloading\n        self.rewardedAd = nil;\n    }\n}\n\n@end
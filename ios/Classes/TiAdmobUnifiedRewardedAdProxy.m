/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "TiAdmobUnifiedRewardedAdProxy.h"
#import "TiApp.h"
#import "TiUtils.h"

@interface TiAdmobUnifiedRewardedAdProxy ()
- (NSDictionary *)baseEvent;
- (NSDictionary *)errorEvent:(NSString *)message code:(NSInteger)code;
@end

@implementation TiAdmobUnifiedRewardedAdProxy

- (id)_initWithPageContext:(id<TiEvaluator>)context args:(NSArray *)args
{
    self = [super _initWithPageContext:context];
    if (self) {
        self.isLoading = NO;
        self.isShowing = NO;
        self.isDestroyed = NO;
        self.destroyedEventFired = NO;
        if ([args count] > 0) {
            NSDictionary *config = [args objectAtIndex:0];
            [self configureWithDict:config];
        }
    }
    return self;
}

- (void)_destroy
{
    [self destroy:nil];
    [super _destroy];
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

    if (self.isDestroyed) {
        DebugLog(@"[WARN] Ignoring load after rewarded destruction");
        return;
    }

    if (self.isLoading || self.isShowing || self.rewardedAd != nil) {
        DebugLog(@"[WARN] Ignoring duplicate rewarded load");
        return;
    }
    
    if ([self.adUnitId length] == 0) {
        DebugLog(@"[ERROR] Cannot load ad - no ad unit ID provided");
        
        [self fireEvent:@"failed_to_load"
             withObject:[self errorEvent:@"No ad unit ID provided" code:1]];
        return;
    }

    self.isLoading = YES;
    GADRequest *request = [self buildAdRequest];
    
    [GADRewardedAd loadWithAdUnitID:self.adUnitId
                            request:request
                  completionHandler:^(GADRewardedAd *ad, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isDestroyed) {
                return;
            }
            self.isLoading = NO;
            if (error) {
                DebugLog(@"[ERROR] Rewarded ad failed to load: %@", error.localizedDescription);
                
                [self fireEvent:@"failed_to_load"
                     withObject:[self errorEvent:error.localizedDescription
                                            code:error.code]];
                return;
            }
            
            DebugLog(@"[DEBUG] Rewarded ad loaded successfully");
            self.rewardedAd = ad;
            self.rewardedAd.fullScreenContentDelegate = self;
            
            [self fireEvent:@"loaded" withObject:[self baseEvent]];
        });
    }];
}

- (GADRequest *)buildAdRequest
{
    GADRequest *request = [GADRequest request];
    
    // Add keywords if provided
    if (self.keywords && [self.keywords count] > 0) {
        // Keywords are set via GADExtras for mediation networks
        GADExtras *extras = [[GADExtras alloc] init];
        NSMutableDictionary *extrasDict = [[NSMutableDictionary alloc] init];
        
        // Add keywords
        [extrasDict setObject:[self.keywords componentsJoinedByString:@","] forKey:@"keywords"];
        
        // Add any additional extras
        if (self.extras) {
            [extrasDict addEntriesFromDictionary:self.extras];
        }
        
        extras.additionalParameters = extrasDict;
        [request registerAdNetworkExtras:extras];
    } else if (self.extras) {
        // Just add extras without keywords
        GADExtras *extras = [[GADExtras alloc] init];
        extras.additionalParameters = self.extras;
        [request registerAdNetworkExtras:extras];
    }
    
    return request;
}

- (void)show:(id)args
{
    if (self.isDestroyed) {
        [self fireEvent:@"failed_to_show"
             withObject:[self errorEvent:@"Rewarded ad has been destroyed" code:1]];
        return;
    }

    if (!self.rewardedAd) {
        DebugLog(@"[ERROR] Cannot show rewarded ad - ad not loaded");

        [self fireEvent:@"failed_to_show"
             withObject:[self errorEvent:@"Ad not loaded" code:1]];
        return;
    }

    if (self.isShowing) {
        [self fireEvent:@"failed_to_show"
             withObject:[self errorEvent:@"Ad is already showing" code:1]];
        return;
    }

    UIViewController *rootViewController = [[[TiApp app] controller] topPresentedController];
    if (rootViewController == nil) {
        [self fireEvent:@"failed_to_show"
             withObject:[self errorEvent:@"No current view controller" code:-1]];
        return;
    }

    self.isShowing = YES;
    [self.rewardedAd presentFromRootViewController:rootViewController
                              userDidEarnRewardHandler:^{
        DebugLog(@"[DEBUG] User earned reward");
        
        // Get reward information
        GADAdReward *reward = self.rewardedAd.adReward;
        
        if (self.isDestroyed) {
            return;
        }
        NSMutableDictionary *rewardEvent = [[self baseEvent] mutableCopy];
        rewardEvent[@"rewardType"] = reward.type ?: @"coins";
        rewardEvent[@"rewardAmount"] = reward.amount ?: @(1);
        [self fireEvent:@"rewarded" withObject:rewardEvent];
    }];
}

- (NSNumber *)isLoaded:(id)args
{
    return @(!self.isDestroyed && self.rewardedAd != nil
             && !self.isLoading && !self.isShowing);
}

- (void)destroy:(id)args
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Destroying rewarded ad");

    self.isDestroyed = YES;
    self.rewardedAd.fullScreenContentDelegate = nil;
    self.rewardedAd = nil;
    self.isLoading = NO;
    self.isShowing = NO;

    if (!self.destroyedEventFired) {
        self.destroyedEventFired = YES;
        [self fireEvent:@"destroyed" withObject:[self baseEvent]];
    }
}

#pragma mark - GADFullScreenContentDelegate

- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Rewarded ad recorded impression");
    [self fireEvent:@"impression" withObject:[self baseEvent]];
}

- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Rewarded ad was clicked");
    [self fireEvent:@"clicked" withObject:[self baseEvent]];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[ERROR] Rewarded ad failed to present: %@", error.localizedDescription);

    self.rewardedAd = nil;
    self.isShowing = NO;
    [self fireEvent:@"failed_to_show"
         withObject:[self errorEvent:error.localizedDescription code:error.code]];
}

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Rewarded ad will present full screen content");

    NSDictionary *event = [self baseEvent];
    [self fireEvent:@"opened" withObject:event];
    [self fireEvent:@"showed_fullscreen_content" withObject:event];
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Rewarded ad dismissed full screen content");

    self.rewardedAd = nil;
    self.isShowing = NO;
    [self fireEvent:@"closed" withObject:[self baseEvent]];

    if (self.autoReload) {
        DebugLog(@"[DEBUG] Auto-reloading rewarded ad");
        [self load:nil];
    }
}

- (NSDictionary *)baseEvent
{
    return @{
        @"adUnitId": self.adUnitId ?: @"",
        @"adType": @"rewarded"
    };
}

- (NSDictionary *)errorEvent:(NSString *)message code:(NSInteger)code
{
    return @{
        @"adUnitId": self.adUnitId ?: @"",
        @"adType": @"rewarded",
        @"error": message ?: @"Unknown error",
        @"message": message ?: @"Unknown error",
        @"code": @(code)
    };
}

@end

/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "TiAdmobUnifiedInterstitialAdProxy.h"
#import "TiApp.h"
#import "TiUtils.h"

@interface TiAdmobUnifiedInterstitialAdProxy ()
- (NSDictionary *)baseEvent;
- (NSDictionary *)errorEvent:(NSString *)message code:(NSInteger)code;
@end

@implementation TiAdmobUnifiedInterstitialAdProxy

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
    
    DebugLog(@"[DEBUG] Interstitial ad configured with unit ID: %@, autoReload: %@", 
             self.adUnitId, self.autoReload ? @"YES" : @"NO");
}

#pragma mark - Public API Methods

- (void)load:(id)args
{
    DebugLog(@"[DEBUG] Loading interstitial ad: %@", self.adUnitId);

    if (self.isDestroyed) {
        DebugLog(@"[WARN] Ignoring load after interstitial destruction");
        return;
    }

    if (self.isLoading || self.isShowing || self.interstitialAd != nil) {
        DebugLog(@"[WARN] Ignoring duplicate interstitial load");
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
    
    [GADInterstitialAd loadWithAdUnitID:self.adUnitId
                                request:request
                      completionHandler:^(GADInterstitialAd *ad, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isDestroyed) {
                return;
            }
            self.isLoading = NO;
            if (error) {
                DebugLog(@"[ERROR] Interstitial ad failed to load: %@", error.localizedDescription);
                
                [self fireEvent:@"failed_to_load"
                     withObject:[self errorEvent:error.localizedDescription
                                            code:error.code]];
                return;
            }
            
            DebugLog(@"[DEBUG] Interstitial ad loaded successfully");
            self.interstitialAd = ad;
            self.interstitialAd.fullScreenContentDelegate = self;
            
            [self fireEvent:@"loaded" withObject:[self baseEvent]];
        });
    }];
}

- (GADRequest *)buildAdRequest
{
    GADRequest *request = [GADRequest request];
    
    // Keywords are targeting, and GADRequest.keywords is the counterpart of
    // Android's AdRequest.Builder.addKeyword. Folding them into GADExtras would
    // send them to mediation adapters instead, which is a different thing.
    if (self.keywords && [self.keywords count] > 0) {
        request.keywords = self.keywords;
    }

    if (self.requestAgent && [self.requestAgent length] > 0) {
        request.requestAgent = self.requestAgent;
    }

    if (self.extras) {
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
             withObject:[self errorEvent:@"Interstitial has been destroyed" code:1]];
        return;
    }

    if (!self.interstitialAd) {
        DebugLog(@"[ERROR] Cannot show interstitial ad - ad not loaded");

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
    [self.interstitialAd presentFromRootViewController:rootViewController];
}

- (NSNumber *)isLoaded:(id)args
{
    return @(!self.isDestroyed && self.interstitialAd != nil
             && !self.isLoading && !self.isShowing);
}

- (void)destroy:(id)args
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Destroying interstitial ad");

    self.isDestroyed = YES;
    self.interstitialAd.fullScreenContentDelegate = nil;
    self.interstitialAd = nil;
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
    DebugLog(@"[DEBUG] Interstitial ad recorded impression");
    [self fireEvent:@"impression" withObject:[self baseEvent]];
}

- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Interstitial ad was clicked");
    [self fireEvent:@"clicked" withObject:[self baseEvent]];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[ERROR] Interstitial ad failed to present: %@", error.localizedDescription);

    self.interstitialAd = nil;
    self.isShowing = NO;
    [self fireEvent:@"failed_to_show"
         withObject:[self errorEvent:error.localizedDescription code:error.code]];
}

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Interstitial ad will present full screen content");

    NSDictionary *event = [self baseEvent];
    [self fireEvent:@"opened" withObject:event];
    [self fireEvent:@"showed_fullscreen_content" withObject:event];
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
    if (self.isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Interstitial ad dismissed full screen content");

    self.interstitialAd = nil;
    self.isShowing = NO;
    [self fireEvent:@"closed" withObject:[self baseEvent]];

    if (self.autoReload) {
        DebugLog(@"[DEBUG] Auto-reloading interstitial ad");
        [self load:nil];
    }
}

- (NSDictionary *)baseEvent
{
    return @{
        @"adUnitId": self.adUnitId ?: @"",
        @"adType": @"interstitial"
    };
}

- (NSDictionary *)errorEvent:(NSString *)message code:(NSInteger)code
{
    return @{
        @"adUnitId": self.adUnitId ?: @"",
        @"adType": @"interstitial",
        @"error": message ?: @"Unknown error",
        @"message": message ?: @"Unknown error",
        @"code": @(code)
    };
}

@end

/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "MxCodigomovilTiadmobunifiedInterstitialAdProxy.h"
#import "TiUtils.h"

@implementation MxCodigomovilTiadmobunifiedInterstitialAdProxy

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
    
    DebugLog(@"[DEBUG] Interstitial ad configured with unit ID: %@, autoReload: %@", 
             self.adUnitId, self.autoReload ? @"YES" : @"NO");
}

#pragma mark - Public API Methods

- (void)load:(id)args
{
    DebugLog(@"[DEBUG] Loading interstitial ad: %@", self.adUnitId);
    
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
    
    [GADInterstitialAd loadWithAdUnitID:self.adUnitId
                                request:request
                      completionHandler:^(GADInterstitialAd *ad, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                DebugLog(@"[ERROR] Interstitial ad failed to load: %@", error.localizedDescription);
                
                NSDictionary *errorEvent = @{
                    @"error": error.localizedDescription,
                    @"code": @(error.code),
                    @"adUnitId": self.adUnitId
                };
                [self fireEvent:@"failed_to_load" withObject:errorEvent];
                return;
            }
            
            DebugLog(@"[DEBUG] Interstitial ad loaded successfully");
            self.interstitialAd = ad;
            self.interstitialAd.fullScreenContentDelegate = self;
            
            NSDictionary *loadedEvent = @{
                @"adUnitId": self.adUnitId
            };
            [self fireEvent:@"loaded" withObject:loadedEvent];
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
    if (!self.interstitialAd) {
        DebugLog(@"[ERROR] Cannot show interstitial ad - ad not loaded");
        
        NSDictionary *errorEvent = @{
            @"error": @"Ad not loaded",
            @"adUnitId": self.adUnitId
        };
        [self fireEvent:@"failed_to_show" withObject:errorEvent];
        return;
    }
    
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    [self.interstitialAd presentFromRootViewController:rootViewController];
}

- (NSNumber *)isLoaded:(id)args
{
    return @(self.interstitialAd != nil);
}

- (void)destroy:(id)args
{
    DebugLog(@"[DEBUG] Destroying interstitial ad");
    
    self.interstitialAd = nil;
    
    NSDictionary *destroyEvent = @{
        @"adUnitId": self.adUnitId
    };
    [self fireEvent:@"destroyed" withObject:destroyEvent];
}

#pragma mark - GADFullScreenContentDelegate

- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad
{
    DebugLog(@"[DEBUG] Interstitial ad recorded impression");
    
    NSDictionary *impressionEvent = @{
        @"adUnitId": self.adUnitId
    };
    [self fireEvent:@"impression" withObject:impressionEvent];
}

- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad
{
    DebugLog(@"[DEBUG] Interstitial ad was clicked");
    
    NSDictionary *clickEvent = @{
        @"adUnitId": self.adUnitId
    };
    [self fireEvent:@"clicked" withObject:clickEvent];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error
{
    DebugLog(@"[ERROR] Interstitial ad failed to present: %@", error.localizedDescription);
    
    NSDictionary *errorEvent = @{
        @"error": error.localizedDescription,
        @"code": @(error.code),
        @"adUnitId": self.adUnitId
    };
    [self fireEvent:@"failed_to_show" withObject:errorEvent];
}

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
    DebugLog(@"[DEBUG] Interstitial ad will present full screen content");
    
    NSDictionary *openEvent = @{
        @"adUnitId": self.adUnitId
    };
    [self fireEvent:@"opened" withObject:openEvent];
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
    DebugLog(@"[DEBUG] Interstitial ad dismissed full screen content");
    
    NSDictionary *closeEvent = @{
        @"adUnitId": self.adUnitId
    };
    [self fireEvent:@"closed" withObject:closeEvent];
    
    // Auto-reload if enabled
    if (self.autoReload) {
        DebugLog(@"[DEBUG] Auto-reloading interstitial ad");
        [self load:nil];
    } else {
        // Clear the ad reference if not auto-reloading
        self.interstitialAd = nil;
    }
}

@end
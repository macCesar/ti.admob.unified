/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "TiAdmobUnifiedAppOpenAdProxy.h"
#import "TiApp.h"
#import "TiAdmobUnifiedModule.h"
#import "TiUtils.h"

// Google documents that an app open ad expires four hours after the request.
// An ad rendered later is no longer valid and may not earn revenue.
static const NSTimeInterval TiAdmobUnifiedAppOpenValidityWindow = 4 * 60 * 60;

// Plain ivars rather than properties: a synthesised getter is reachable from
// JavaScript through Kroll's key lookup, and Android exposes neither the native
// ad object nor the loading state. accessInstanceVariablesDirectly closes the
// remaining path, key-value coding reaching the ivar by name.
@interface TiAdmobUnifiedAppOpenAdProxy ()
{
    TiAdmobUnifiedNativeDelegate *_nativeDelegate;
    NSString *_requestAdUnitId;
    GADAppOpenAd *appOpenAd;
    BOOL isLoading;
    BOOL isShowing;
    BOOL isDestroyed;
    BOOL destroyedEventFired;
    // Timestamp of the last successful load. App open ads expire four hours after
    // the request, so the proxy has to remember when the ad arrived.
    NSDate *loadTime;
}
- (NSDictionary *)baseEvent:(id)unused internal:(id)context;
- (NSDictionary *)errorEvent:(NSString *)message code:(NSInteger)code;
- (BOOL)isAdExpired:(id)unused internal:(id)context;
- (void)discardAd:(id)unused internal:(id)context;
@end

@implementation TiAdmobUnifiedAppOpenAdProxy
- (TiAdmobUnifiedNativeDelegate *)nativeDelegate:(id)unused context:(id)context
{
    if (_nativeDelegate == nil) {
        _nativeDelegate = [[TiAdmobUnifiedNativeDelegate alloc] init];
        _nativeDelegate.target = self;
    }
    return _nativeDelegate;
}


+ (BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

- (id)_initWithPageContext:(id<TiEvaluator>)context args:(NSArray *)args
{
    self = [super _initWithPageContext:context];
    if (self) {
        _autoReload = @NO;
        self->isLoading = NO;
        self->isShowing = NO;
        self->isDestroyed = NO;
        self->destroyedEventFired = NO;
        if ([args count] > 0) {
            NSDictionary *config = [args objectAtIndex:0];
            [self configureWithDict:config internal:nil];
        }
    }
    return self;
}

- (void)setAutoReload:(NSNumber *)value
{
    _autoReload = [NSNumber numberWithBool:[TiUtils boolValue:value def:NO]];
}

- (void)_destroy
{
    [self destroy:nil];
    [super _destroy];
}

- (void)configureWithDict:(NSDictionary *)config internal:(id)unused
{
    if (config == nil) {
        return;
    }

    // Ad Unit ID (required)
    self.adUnitId = [TiUtils stringValue:[config objectForKey:@"adUnitId"]] ?: @"";

    // Auto-reload setting (default: false, but recommended: true)
    self.autoReload = [NSNumber numberWithBool:[TiUtils boolValue:[config objectForKey:@"autoReload"] def:NO]];

    // Keywords for targeting
    if ([config objectForKey:@"keywords"]) {
        self.keywords = [config objectForKey:@"keywords"];
    }

    // Extra parameters for mediation networks
    if ([config objectForKey:@"extras"]) {
        self.extras = [config objectForKey:@"extras"];
    }

    // Request agent identifying the mediation platform
    if ([config objectForKey:@"requestAgent"]) {
        self.requestAgent = [TiUtils stringValue:[config objectForKey:@"requestAgent"]];
    }

    DebugLog(@"[DEBUG] App open ad configured with unit ID: %@, autoReload: %@",
             self.adUnitId, [self.autoReload boolValue] ? @"YES" : @"NO");
}

#pragma mark - Public API Methods

- (void)load:(id)args
{
    ENSURE_UI_THREAD(load, args);
    DebugLog(@"[DEBUG] Loading app open ad: %@", self.adUnitId);

    if (self->isDestroyed) {
        DebugLog(@"[WARN] Ignoring load after app open destruction");
        return;
    }

    // An expired ad is no longer showable, so it must not block a new request.
    if (!self->isShowing && [self isAdExpired:nil internal:nil]) {
        DebugLog(@"[DEBUG] Discarding expired app open ad before reloading");
        [self discardAd:nil internal:nil];
    }

    if (self->isLoading || self->isShowing || self->appOpenAd != nil) {
        DebugLog(@"[WARN] Ignoring duplicate app open load");
        return;
    }

    if ([self.adUnitId length] == 0) {
        DebugLog(@"[ERROR] Cannot load ad - no ad unit ID provided");

        [self fireEvent:@"failed_to_load"
             withObject:[self errorEvent:@"No ad unit ID provided" code:1]];
        return;
    }

    _requestAdUnitId = [self.adUnitId copy];
    self->isLoading = YES;
    GADRequest *request = [self buildAdRequest:nil internal:nil];

    [GADAppOpenAd loadWithAdUnitID:self.adUnitId
                           request:request
                 completionHandler:^(GADAppOpenAd *ad, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->isDestroyed) {
                return;
            }
            self->isLoading = NO;
            if (error) {
                DebugLog(@"[ERROR] App open ad failed to load: %@", error.localizedDescription);

                [self fireEvent:@"failed_to_load"
                     withObject:[self errorEvent:error.localizedDescription
                                            code:TiAdmobUnifiedLoadErrorCode(error)]];
                return;
            }

            DebugLog(@"[DEBUG] App open ad loaded successfully");
            self->appOpenAd = ad;
            self->appOpenAd.fullScreenContentDelegate = [self nativeDelegate:nil context:nil];
            self->loadTime = [NSDate date];

            [self fireEvent:@"loaded" withObject:[self baseEvent:nil internal:nil]];
        });
    }];
}

- (GADRequest *)buildAdRequest:(id)unused internal:(id)context
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
    ENSURE_UI_THREAD(show, args);
    if (self->isDestroyed) {
        [self fireEvent:@"failed_to_show"
             withObject:[self errorEvent:@"App open has been destroyed" code:1]];
        return;
    }

    if (!self->appOpenAd) {
        DebugLog(@"[ERROR] Cannot show app open ad - ad not loaded");

        [self fireEvent:@"failed_to_show"
             withObject:[self errorEvent:@"Ad not loaded" code:1]];
        return;
    }

    if (self->isShowing) {
        [self fireEvent:@"failed_to_show"
             withObject:[self errorEvent:@"Ad is already showing" code:1]];
        return;
    }

    if ([self isAdExpired:nil internal:nil]) {
        DebugLog(@"[ERROR] Cannot show app open ad - the four hour window elapsed");

        [self discardAd:nil internal:nil];
        [self fireEvent:@"failed_to_show"
             withObject:[self errorEvent:@"App open ad expired after four hours" code:1]];
        return;
    }

    UIViewController *rootViewController = [[[TiApp app] controller] topPresentedController];
    if (rootViewController == nil) {
        [self fireEvent:@"failed_to_show"
             withObject:[self errorEvent:@"No current view controller" code:-1]];
        return;
    }

    self->isShowing = YES;
    [self->appOpenAd presentFromRootViewController:rootViewController];
}

- (NSNumber *)isLoaded:(id)args
{
    if (![NSThread isMainThread]) {
        __block NSNumber *result;
        TiThreadPerformOnMainThread(^{ result = [self isLoaded:args]; }, YES);
        return result;
    }
    return [NSNumber numberWithBool:(!self->isDestroyed && self->appOpenAd != nil
             && !self->isLoading && !self->isShowing && ![self isAdExpired:nil internal:nil])];
}

- (void)destroy:(id)args
{
    ENSURE_UI_THREAD(destroy, args);
    if (self->isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] Destroying app open ad");

    self->isDestroyed = YES;
    self->appOpenAd.fullScreenContentDelegate = nil;
    self->appOpenAd = nil;
    self->loadTime = nil;
    self->isLoading = NO;
    self->isShowing = NO;

    if (!self->destroyedEventFired) {
        self->destroyedEventFired = YES;
        [self fireEvent:@"destroyed" withObject:[self baseEvent:nil internal:nil]];
    }
}

#pragma mark - GADFullScreenContentDelegate

- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad internal:(id)unused
{
    if (self->isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] App open ad recorded impression");
    [self fireEvent:@"impression" withObject:[self baseEvent:nil internal:nil]];
}

- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad internal:(id)unused
{
    if (self->isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] App open ad was clicked");
    [self fireEvent:@"clicked" withObject:[self baseEvent:nil internal:nil]];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error
{
    if (self->isDestroyed) {
        return;
    }
    DebugLog(@"[ERROR] App open ad failed to present: %@", error.localizedDescription);

    self->appOpenAd = nil;
    self->loadTime = nil;
    self->isShowing = NO;
    [self fireEvent:@"failed_to_show"
         withObject:[self errorEvent:error.localizedDescription code:error.code]];
}

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad internal:(id)unused
{
    if (self->isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] App open ad will present full screen content");

    NSDictionary *event = [self baseEvent:nil internal:nil];
    [self fireEvent:@"opened" withObject:event];
    [self fireEvent:@"showed_fullscreen_content" withObject:event];
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad internal:(id)unused
{
    if (self->isDestroyed) {
        return;
    }
    DebugLog(@"[DEBUG] App open ad dismissed full screen content");

    self->appOpenAd = nil;
    self->loadTime = nil;
    self->isShowing = NO;
    [self fireEvent:@"closed" withObject:[self baseEvent:nil internal:nil]];

    if ([self.autoReload boolValue]) {
        DebugLog(@"[DEBUG] Auto-reloading app open ad");
        [self load:nil];
    }
}

#pragma mark - Private helpers

- (BOOL)isAdExpired:(id)unused internal:(id)context
{
    if (self->appOpenAd == nil || self->loadTime == nil) {
        return NO;
    }
    return [[NSDate date] timeIntervalSinceDate:self->loadTime] >= TiAdmobUnifiedAppOpenValidityWindow;
}

- (void)discardAd:(id)unused internal:(id)context
{
    self->appOpenAd.fullScreenContentDelegate = nil;
    self->appOpenAd = nil;
    self->loadTime = nil;
}

- (NSDictionary *)baseEvent:(id)unused internal:(id)context
{
    return @{
        @"adUnitId": _requestAdUnitId ?: self.adUnitId ?: @"",
        @"adType": @"app_open"
    };
}

- (NSDictionary *)errorEvent:(NSString *)message code:(NSInteger)code
{
    return @{
        @"adUnitId": _requestAdUnitId ?: self.adUnitId ?: @"",
        @"adType": @"app_open",
        @"error": message ?: @"Unknown error",
        @"message": message ?: @"Unknown error",
        @"code": @(code)
    };
}

@end

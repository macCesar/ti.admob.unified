#!/usr/bin/env python3
"""Run actual Objective-C method bodies with controlled SDK callbacks on macOS.
This checks wrapper logic, not Google SDK networking or Titanium bridging.
"""
from pathlib import Path
import re, subprocess, tempfile, sys
root = Path(__file__).resolve().parents[2]

def body(path, marker):
    source = (root / path).read_text()
    start = source.index(marker)
    # Skip declarations: a method implementation has { before its first ;.
    while source.find(';', start) < source.find('{', start):
        start = source.index(marker, start + len(marker))
    opening = source.index('{', start)
    depth = 1; end = opening + 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}'); end += 1
    return source[start:end]
module = 'ios/Classes/TiAdmobUnifiedModule.m'
rewarded = ('ios/Classes/TiAdmobUnifiedRewardedInterstitialAdProxy.m'
            if '--rewarded-interstitial' in sys.argv else 'ios/Classes/TiAdmobUnifiedRewardedAdProxy.m')
load = body('ios/Classes/TiAdmobUnifiedModule.h', 'static inline NSInteger TiAdmobUnifiedLoadErrorCode')
constants = sorted(set(re.findall(r'case (GADError\w+):', load)))
prefix = r'''
#import <Foundation/Foundation.h>
#import <math.h>
#define ENSURE_UI_THREAD(a,b)
#define DebugLog(...) ((void)0)
static void TiThreadPerformOnMainThread(void (^block)(void), BOOL wait) { block(); }
#define TiAdmobUnifiedOperationStateNotStarted 0
#define TiAdmobUnifiedOperationStateInFlight 1
#define TiAdmobUnifiedOperationStateComplete 2
#define TiAdmobUnifiedOperationStateFailed 3
typedef NSInteger TiAdmobUnifiedOperationState;
#define GADAdapterInitializationStateReady 1
#define UMPPrivacyOptionsRequirementStatusRequired 1
NSString *GADErrorDomain = @"GMA";
@interface TiUtils : NSObject
+ (NSString *)stringValue:(id)value;
@end
@implementation TiUtils
+ (NSString *)stringValue:(id)value { return value ? [value description] : nil; }
@end
@interface GADAdapterStatus : NSObject
@property NSInteger state;
@property NSString *adapterDescription;
@property double latency;
@end
@implementation GADAdapterStatus
- (NSString *)description { return self.adapterDescription; }
@end
@interface GADInitializationStatus : NSObject
@property NSDictionary *adapterStatusesByClassName;
@end
@implementation GADInitializationStatus @end
@interface GADMobileAds : NSObject
@property GADInitializationStatus *initializationStatus;
@property double applicationVolume;
+ (instancetype)sharedInstance;
@end
@implementation GADMobileAds
+ (instancetype)sharedInstance { static id instance; if (!instance) instance = [self new]; return instance; }
@end
@interface UMPConsentInformation : NSObject
@property BOOL canRequestAds;
@property NSInteger privacyOptionsRequirementStatus;
@property NSInteger resets;
+ (instancetype)sharedInstance;
- (void)reset;
@end
@implementation UMPConsentInformation
+ (instancetype)sharedInstance { static id instance; if (!instance) instance = [self new]; return instance; }
- (void)reset { self.resets++; self.canRequestAds = NO; self.privacyOptionsRequirementStatus = 0; }
@end
@interface UIViewController : NSObject
- (id)topPresentedController;
@end
@implementation UIViewController
- (id)topPresentedController { return self; }
@end
@interface TiApp : NSObject
+ (id)app;
- (id)controller;
@end
@implementation TiApp
+ (id)app { return [self new]; }
- (id)controller { return [UIViewController new]; }
@end
@interface GADAdReward : NSObject
@property NSString *type;
@property NSNumber *amount;
@end
@implementation GADAdReward @end
@protocol GADFullScreenPresentingAd @end
@interface FakeAd : NSObject
@property GADAdReward *adReward;
@property id fullScreenContentDelegate;
@property(copy) void (^callback)(void);
- (void)presentFromRootViewController:(id)controller userDidEarnRewardHandler:(void(^)(void))callback;
@end
@implementation FakeAd
- (void)presentFromRootViewController:(id)c userDidEarnRewardHandler:(void(^)(void))callback { self.callback = callback; }
@end
@interface Harness : NSObject {
@public
    NSInteger _initializationState;
    NSInteger _consentState;
    NSDictionary *_consentResult;
    BOOL _consentResetPending, _privacyInFlight;
    NSDictionary *_queuedConsent;
    BOOL isDestroyed, isShowing, isLoading, destroyedEventFired;
    FakeAd *rewardedAd;
}
@property NSMutableArray *events;
@property NSInteger requests;
@property NSString *identity;
@property NSNumber *autoReload;
- (void)requestConsent:(id)args;
- (BOOL)finishPendingConsentReset:(id)unused context:(id)context;
- (void)completeConsentWithError:(NSError *)error internal:(id)unused;
- (void)resetConsent:(id)args;
@end
@implementation Harness
- (id)init { if ((self = [super init])) { self.events = [NSMutableArray new]; self.identity = @"original"; } return self; }
- (void)fireEvent:(NSString *)name withObject:(id)event { [self.events addObject:@{@"name":name,@"event":event}]; }
- (NSNumber *)isGDPR:(id)args { return @YES; }
- (void)requestConsent:(id)args { self.requests++; _consentState = 1; }
- (void)load:(id)args { self.requests++; }
- (NSDictionary *)baseEvent:(id)a internal:(id)b { return @{@"adUnitId":self.identity}; }
- (NSDictionary *)errorEvent:(NSString *)message code:(NSInteger)code { return @{@"error":message,@"code":@(code)}; }
'''
methods = '\n'.join(body(module, marker) for marker in [
    '- (NSDictionary *)getMediationStatus:', '- (void)setAppVolume:', '- (void)resetConsent:',
    '- (BOOL)finishPendingConsentReset:', '- (void)completeConsentWithError:'])
methods += '\n' + '\n'.join(body(rewarded, marker) for marker in [
    '- (void)show:', '- (NSNumber *)isLoaded:', '- (void)destroy:',
    '- (void)adDidDismissFullScreenContent:'])
main = r'''
@end
static int assertions;
static void check(BOOL condition, NSString *name) { assertions++; if (!condition) { NSLog(@"FAIL %@", name); exit(1); } }
int main() { @autoreleasepool {
    Harness *h = [Harness new];
    check([[h getMediationStatus:nil][@"initializationState"] isEqual:@"not_started"], @"pre-init");
    check([[h getMediationStatus:nil][@"adapters"] count] == 0, @"pre-init empty");
    h->_initializationState = 1;
    check([[h getMediationStatus:nil][@"initializationState"] isEqual:@"initializing"], @"in-flight nil SDK status");
    GADInitializationStatus *status = [GADInitializationStatus new];
    GADMobileAds.sharedInstance.initializationStatus = status; status.adapterStatusesByClassName = @{};
    check([[h getMediationStatus:nil][@"adapters"] count] == 0, @"empty map");
    GADAdapterStatus *ready = [GADAdapterStatus new], *waiting = [GADAdapterStatus new];
    ready.state = 1; ready.latency = .1256; ready.adapterDescription = @"SDK detail";
    waiting.state = 0; waiting.latency = 0; waiting.adapterDescription = @"Waiting";
    status.adapterStatusesByClassName = @{@"z.UnknownAdapter":waiting,@"a.GoogleAdapter":ready};
    h->_initializationState = 2;
    NSDictionary *diagnostic = [h getMediationStatus:nil]; NSArray *adapters = diagnostic[@"adapters"];
    check([diagnostic[@"initializationState"] isEqual:@"completed"], @"completed with not-ready adapter");
    check(adapters.count == 2 && [adapters[0][@"adapterClass"] isEqual:@"a.GoogleAdapter"] && [adapters[1][@"adapterClass"] isEqual:@"z.UnknownAdapter"], @"all adapters sorted");
    check([adapters[0][@"state"] isEqual:@"ready"] && [adapters[1][@"state"] isEqual:@"not_ready"], @"normalized states");
    check([adapters[0][@"latencyMs"] doubleValue] == 126 && [adapters[0][@"description"] isEqual:@"SDK detail"], @"milliseconds and SDK description");
    ready.latency = .1254;
    check([[[h getMediationStatus:nil][@"adapters"] firstObject][@"latencyMs"] doubleValue] == 125, @"round milliseconds down");
    check([adapters[1][@"latencyMs"] longLongValue] == 0, @"zero latency stays zero");
    h->_initializationState = 3;
    check([[h getMediationStatus:nil][@"initializationState"] isEqual:@"failed"], @"failed init");
    for (id value in @[@"0", @"50%", @"100%", @25, @[@"75%"]]) {
        [h setAppVolume:value];
        id raw = [value isKindOfClass:NSArray.class] ? value[0] : value;
        check(fabs(GADMobileAds.sharedInstance.applicationVolume - [raw doubleValue]/100.) < .0001, @"volume applied");
    }
    for (id value in @[@"NaN", @"Infinity", @"-1", @"101", @"50oops", @"", @[]]) {
        [h setAppVolume:value]; check(GADMobileAds.sharedInstance.applicationVolume == .75, @"invalid volume preserved");
    }
    UMPConsentInformation *ump = UMPConsentInformation.sharedInstance;
    ump.canRequestAds = YES; ump.privacyOptionsRequirementStatus = 1;
    h->_consentState = 1;
    [h completeConsentWithError:[NSError errorWithDomain:@"UMP" code:2 userInfo:nil] internal:nil];
    check(h->_consentState == 0, @"consent failure allows retry");
    check([h.events.lastObject[@"event"][@"success"] isEqual:@NO], @"failure event");
    [h completeConsentWithError:nil internal:nil];
    check(h->_consentState == 2 && [h->_consentResult[@"canRequestAds"] boolValue], @"success cached");
    h->_consentState = 1;
    [h resetConsent:nil];
    check(h->_consentResetPending && ump.resets == 0, @"reset waits for SDK callback");
    h->_queuedConsent = @{};
    [h completeConsentWithError:nil internal:nil];
    check(ump.resets == 1 && h.requests == 1 && h->_consentState == 1, @"reset precedes queued retry");
    check(!h->_consentResetPending && h->_queuedConsent == nil, @"pending reset consumed");
    h->_consentState = 1; [h resetConsent:nil];
    [h completeConsentWithError:nil internal:nil];
    check(h->_consentState == 0 && ![h.events.lastObject[@"event"][@"success"] boolValue], @"reset without retry completes cancellation");
    h->_privacyInFlight = YES; [h resetConsent:nil];
    check(h->_consentResetPending && ump.resets == 2, @"privacy reset also deferred");
    h->_privacyInFlight = NO; [h finishPendingConsentReset:nil context:nil];
    check(ump.resets == 3, @"privacy callback can finish reset");
    FakeAd *ad = [FakeAd new]; GADAdReward *reward = [GADAdReward new];
    reward.type = @"coin"; reward.amount = @7; ad.adReward = reward;
    h->rewardedAd = ad; [h show:nil];
    h->rewardedAd = nil; h.identity = @"replacement";
    NSUInteger count = h.events.count; ad.callback(); ad.callback();
    check(h.events.count == count + 1, @"one reward after dismissal");
    NSDictionary *event = h.events.lastObject[@"event"];
    check([event[@"rewardType"] isEqual:@"coin"] && [event[@"rewardAmount"] isEqual:@7], @"original SDK reward retained");
    check([event[@"adUnitId"] isEqual:@"original"], @"original ad identity retained");
    h->isShowing = NO; h->rewardedAd = ad; [h show:nil]; h->isDestroyed = YES;
    count = h.events.count; ad.callback(); check(h.events.count == count, @"destroy suppresses late reward");
    Harness *l = [Harness new]; FakeAd *pending = [FakeAd new];
    check(![[l isLoaded:nil] boolValue], @"new proxy not ready");
    l->rewardedAd = pending;
    check([[l isLoaded:nil] boolValue], @"loaded proxy ready");
    [l show:nil]; check(![[l isLoaded:nil] boolValue], @"show consumes readiness");
    count = l.events.count; [l show:nil]; check(l.events.count == count + 1 && [l.events.lastObject[@"name"] isEqual:@"failed_to_show"], @"duplicate show rejected");
    l.autoReload = @YES;
    [l adDidDismissFullScreenContent:nil internal:nil];
    check(l->rewardedAd == nil && !l->isShowing && l.requests == 1, @"dismissal clears and reloads once");
    check([l.events.lastObject[@"name"] isEqual:@"closed"], @"dismissal grants no reward");
    l->rewardedAd = pending; pending.fullScreenContentDelegate = l;
    [l destroy:nil]; [l destroy:nil];
    check(l->rewardedAd == nil && pending.fullScreenContentDelegate == nil && ![[l isLoaded:nil] boolValue], @"destroy releases ad and delegate");
    check([l.events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == 'destroyed'"]].count == 1, @"destroyed once");
    count = l.events.count; [l adDidDismissFullScreenContent:nil internal:nil];
    check(l.events.count == count && l.requests == 1, @"late dismissal cannot reload");
    l = [Harness new]; pending = [FakeAd new]; pending.adReward = [GADAdReward new];
    l->rewardedAd = pending; [l show:nil]; pending.callback();
    check(l.events.lastObject[@"event"][@"rewardType"] == NSNull.null && l.events.lastObject[@"event"][@"rewardAmount"] == NSNull.null, @"missing SDK reward fields remain null");
    check(TiAdmobUnifiedLoadErrorCode([NSError errorWithDomain:@"other" code:GADErrorNoFill userInfo:nil]) == 0, @"foreign domain");
    NSDictionary *expected = @{ @(GADErrorInvalidRequest):@1, @(GADErrorNoFill):@3, @(GADErrorNetworkError):@2, @(GADErrorTimeout):@2, @(GADErrorMediationDataError):@0, @(GADErrorMediationAdapterError):@0, @(GADErrorMediationInvalidAdSize):@10, @(GADErrorApplicationIdentifierMissing):@8 };
    for (NSNumber *code in expected) check(TiAdmobUnifiedLoadErrorCode([NSError errorWithDomain:GADErrorDomain code:code.integerValue userInfo:nil]) == [expected[code] integerValue], @"load error mapping");
    printf("PASS %d native wrapper behavior assertions\n", assertions);
} return 0; }
'''
if sys.platform != 'darwin':
    print('SKIP: native wrapper harness requires macOS Foundation'); sys.exit(0)
with tempfile.TemporaryDirectory(prefix='admob-native-tests-') as directory:
    path = Path(directory)
    enums = 'enum { ' + ', '.join(constants) + ' };\n'
    (path / 'harness.m').write_text(prefix.replace('@interface Harness', enums + load + '\n@interface Harness') + methods + main)
    subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-fblocks', '-framework', 'Foundation', str(path/'harness.m'), '-o', str(path/'test')], check=True)
    subprocess.run([str(path/'test')], check=True)

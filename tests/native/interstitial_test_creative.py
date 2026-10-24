#!/usr/bin/env python3
"""Exercise the actual private iOS repair task with controlled presentation views."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'ios/Classes/TiAdmobUnifiedInterstitialAdProxy.m').read_text()
helper = source[source.index('static NSString *TiAdmobUnifiedTestCreativeScript'):source.index('// Plain ivars')]
prefix = r'''
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#define DebugLog(...) ((void)0)
static NSMutableArray *tasks;
#define dispatch_after(time, queue, block) [tasks addObject:[block copy]]
@interface UIView : NSObject
@property NSArray *subviews;
@end
@implementation UIView @end
@interface UIViewController : NSObject
@property UIViewController *presentedViewController;
@property UIView *view;
@property BOOL isBeingDismissed;
@end
@implementation UIViewController @end
@interface WKWebView : UIView
@property NSURL *URL;
@property NSInteger evaluations;
- (void)evaluateJavaScript:(NSString *)script completionHandler:(id)handler;
@end
@implementation WKWebView
- (void)evaluateJavaScript:(NSString *)script completionHandler:(id)handler { self.evaluations++; }
@end
'''
main = r'''
static int checks;
static void check(BOOL condition, NSString *message) {
    checks++; if (!condition) { NSLog(@"FAIL %@", message); exit(1); }
}
static void run(void) { NSArray *pending = [tasks copy]; [tasks removeAllObjects]; for (void (^task)(void) in pending) task(); }
int main(void) { @autoreleasepool {
    tasks = [NSMutableArray new];
    UIViewController *presenter = [UIViewController new], *ad = [UIViewController new];
    WKWebView *web = [WKWebView new], *unrelated = [WKWebView new];
    web.URL = [NSURL URLWithString:@"https://googleads.g.doubleclick.net/page"];
    unrelated.URL = [NSURL URLWithString:@"https://doubleclick.net.example.com/page"];
    ad.view = [UIView new]; ad.view.subviews = @[web, unrelated];
    presenter.presentedViewController = ad;
    TiAdmobUnifiedTestCreativeRepair *repair = [TiAdmobUnifiedTestCreativeRepair new]; repair.presenter = presenter;
    [repair start]; check(tasks.count == 7, @"bounded attempt count");
    run(); check(web.evaluations == 7 && unrelated.evaluations == 0, @"only the presented Google host is eligible");
    [repair start]; [repair cancel]; run();
    check(web.evaluations == 7 && repair.presenter == nil && repair.adController == nil, @"cancel drops references and suppresses pending work");
    repair = [TiAdmobUnifiedTestCreativeRepair new]; repair.presenter = presenter;
    ad.isBeingDismissed = YES; [repair start]; run();
    check(web.evaluations == 7, @"dismissal suppresses repair");
    ad.isBeingDismissed = NO; [repair start]; run();
    check(web.evaluations == 14, @"active ad can be repaired");
    UIViewController *other = [UIViewController new]; other.view = web; presenter.presentedViewController = other;
    [repair start]; run(); check(web.evaluations == 14, @"another presentation cannot inherit the repair");
    __weak TiAdmobUnifiedTestCreativeRepair *weakRepair;
    @autoreleasepool { repair = [TiAdmobUnifiedTestCreativeRepair new]; repair.presenter = presenter; weakRepair = repair; [repair start]; repair = nil; }
    check(weakRepair == nil, @"scheduled blocks do not retain the repair"); run();
    printf("PASS %d interstitial test-creative lifecycle assertions\n", checks);
} return 0; }
'''
with tempfile.TemporaryDirectory(prefix='admob-test-creative-') as directory:
    folder = Path(directory)
    (folder / 'harness.m').write_text(prefix + helper + main)
    subprocess.run(['xcrun', 'clang', '-std=c99', '-fobjc-arc', '-fblocks', '-framework', 'Foundation',
                    str(folder / 'harness.m'), '-o', str(folder / 'test')], check=True)
    subprocess.run([str(folder / 'test')], check=True)

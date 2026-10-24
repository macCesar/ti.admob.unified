#!/usr/bin/env python3
"""Execute ATT wrapper bodies; SDK initialization/dialog/event side effects fail.
Stand-ins cover wrapper behavior, not the device prompt or Titanium bridge.
"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def method(path, signature):
    source = (ROOT / path).read_text()
    assert signature in source, f"Missing public ATT query: {signature}"
    start = source.index(signature)
    opening = source.index('{', start)
    end, depth = opening + 1, 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def ios(directory):
    query = method('ios/Classes/TiAdmobUnifiedModule.m', '- (NSDictionary *)getTrackingAuthorizationStatus:')
    code = r'''#import <Foundation/Foundation.h>
#define __IPHONE_OS_VERSION_MAX_ALLOWED 150000
typedef NSInteger ATTrackingManagerAuthorizationStatus;
#define ATTrackingManagerAuthorizationStatusAuthorized 3
static NSInteger currentStatus, reads;
@interface ATTrackingManager : NSObject
+ (ATTrackingManagerAuthorizationStatus)trackingAuthorizationStatus;
@end
@implementation ATTrackingManager
+ (ATTrackingManagerAuthorizationStatus)trackingAuthorizationStatus { reads++; return currentStatus; }
@end
@interface Harness : NSObject
@end
@implementation Harness
''' + query + r'''
@end
int main() { @autoreleasepool {
    Harness *h = [Harness new];
    // Resolved -> denied -> undecided also proves each query reads fresh state.
    for (NSNumber *value in @[@3, @2, @0, @1, @3]) {
        currentStatus = value.integerValue;
        NSDictionary *result = [h getTrackingAuthorizationStatus:nil];
        NSCAssert(result.count == 3, @"exact result keys");
        NSCAssert([result[@"status"] isEqual:value], @"current system status");
        NSCAssert(CFGetTypeID((__bridge CFTypeRef)result[@"authorized"]) == CFBooleanGetTypeID(), @"bridge Boolean");
        NSCAssert([result[@"authorized"] boolValue] == (currentStatus == 3), @"only authorized status");
        NSCAssert(CFGetTypeID((__bridge CFTypeRef)result[@"applicable"]) == CFBooleanGetTypeID() && [result[@"applicable"] boolValue], @"iOS applicable Boolean");
    }
    NSCAssert(reads == 5, @"one fresh system read per call");
    puts("PASS iOS ATT: four states, refreshed permissions, Booleans, no dialog/event/SDK dependencies");
} return 0; }
'''
    source = directory / 'tracking.m'
    source.write_text(code)
    subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-framework', 'Foundation', str(source), '-o', str(directory / 'tracking')], check=True)
    subprocess.run([str(directory / 'tracking')], check=True)


def android(directory):
    query = method('android/src/ti/admob/unified/TiAdmobUnifiedModule.java', 'public KrollDict getTrackingAuthorizationStatus(')
    code = '''import java.util.*;
public class Tracking {
 static class KrollDict extends HashMap<String,Object> {}
''' + query + '''
 public static void main(String[] args) {
  Tracking module = new Tracking();
  for (int i = 0; i < 2; i++) {
   Map<String,Object> result = module.getTrackingAuthorizationStatus();
   if (result.size() != 3 || !Integer.valueOf(3).equals(result.get("status")) ||
       !Boolean.TRUE.equals(result.get("authorized")) || !Boolean.FALSE.equals(result.get("applicable")))
    throw new AssertionError("Android not-applicable contract");
   result.clear();
  }
  System.out.println("PASS Android ATT: not applicable, fresh dictionary, no Activity/event/SDK dependencies");
 }
}
'''
    source = directory / 'Tracking.java'
    source.write_text(code)
    subprocess.run(['javac', '-d', str(directory), str(source)], check=True)
    subprocess.run(['java', '-cp', str(directory), 'Tracking'], check=True)


with tempfile.TemporaryDirectory(prefix='admob-tracking-') as temp:
    directory = Path(temp)
    ios(directory)
    android(directory)

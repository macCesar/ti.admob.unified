/**
 * ti.admob.unified.mediation.meta
 *
 * Copyright (c) 2026 by César Estrada. Licensed under the MIT License.
 *
 * Carrier module for the AdMob mediation adapters.
 *
 * It exposes no JavaScript API on purpose. Declaring it in tiapp.xml links the
 * network XCFrameworks into the application; Google Mobile Ads
 * discovers the adapters at runtime and ti.admob.unified reports them through
 * getMediationStatus(). Every ad call still goes through ti.admob.unified.
 */

#import "TiAdmobUnifiedMediationMetaModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation TiAdmobUnifiedMediationMetaModule

#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"e8ad3af9-f04b-429a-9176-dc33077945df";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"ti.admob.unified.mediation.meta";
}

#pragma mark Lifecycle

- (void)startup
{
  [super startup];
  DebugLog(@"[DEBUG] %@ loaded", self);
}

@end

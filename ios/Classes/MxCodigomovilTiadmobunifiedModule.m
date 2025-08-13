/**
 * ti.admob.unified
 *
 * Created by César Estrada
 * Copyright (c) 2025 . All rights reserved.
 */

#import "MxCodigomovilTiadmobunifiedModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation MxCodigomovilTiadmobunifiedModule

#pragma mark Internal

// This is generated for your module, please do not change it
- (id)moduleGUID
{
  return @"67829dbd-d857-4749-9e7c-6143caedee43";
}

// This is generated for your module, please do not change it
- (NSString *)moduleId
{
  return @"mx.codigomovil.tiadmobunified";
}

#pragma mark Lifecycle

- (void)startup
{
  // This method is called when the module is first loaded
  // You *must* call the superclass
  [super startup];
  DebugLog(@"[DEBUG] %@ loaded", self);
}

#pragma Public APIs

- (NSString *)example:(id)args
{
  // Example method. 
  // Call with "MyModule.example(args)"
  return @"hello world";
}

- (NSString *)exampleProp
{
  // Example property getter. 
  // Call with "MyModule.exampleProp" or "MyModule.getExampleProp()"
  return @"Titanium rocks!";
}

- (void)setExampleProp:(id)value
{
  // Example property setter. 
  // Call with "MyModule.exampleProp = 'newValue'" or "MyModule.setExampleProp('newValue')"
}

@end

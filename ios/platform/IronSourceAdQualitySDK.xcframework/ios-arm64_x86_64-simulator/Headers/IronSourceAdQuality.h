/*
 * Copyright (C) 2012-2016 Soomla Inc. - All Rights Reserved
 *
 *   Unauthorized copying of this file, via any medium is strictly prohibited
 *   Proprietary and confidential
 *
 *   Written by Refael Dakar <refael@soom.la>
 */

#import <Foundation/Foundation.h>
#import "ISAdQualityAdType.h"
#import "ISAdQualityConfig.h"
#import "ISAdQualityCustomMediationRevenue.h"
#import "ISAdQualitySegment.h"

#define IRONSOURCE_AD_QUALITY_VERSION    @"9.8.1"

static NSString *IRONSOURCE_AD_QUALITY_TAG = @"ISAdQualitySDK";

@protocol ISAdQualityDelegate <NSObject>

@required

@optional

- (void)adDisplayedForAdNetwork:(NSString *)adNetwork andAdType:(ISAdQualityAdType)adType;
- (void)adClosedForAdNetwork:(NSString *)adNetwork andAdType:(ISAdQualityAdType)adType;

@end

@interface IronSourceAdQuality : NSObject

@property (nonatomic, weak) id<ISAdQualityDelegate> delegate;

+ (IronSourceAdQuality *)getInstance;
+ (NSString *)getSDKVersion;

- (void)initializeWithAppKey:(NSString *)appKey;
- (void)initializeWithAppKey:(NSString *)appKey andConfig:(ISAdQualityConfig *)config;
- (void)initializeWithGameId:(NSString *)gameId;
- (void)initializeWithGameId:(NSString *)gameId andConfig:(ISAdQualityConfig *)config;
- (void)shutdown
DEPRECATED_MSG_ATTRIBUTE("This method is deprecated and will be removed in version 10.0.0");
- (void)changeUserId:(NSString *)userId;
- (void)sendCustomMediationRevenue:(ISAdQualityCustomMediationRevenue *)customMediationRev;
- (void)setSegment:(ISAdQualitySegment *)segment;

- (void)setUserConsent:(BOOL)userConsent __attribute__((deprecated("This method has been deprecated and will be removed soon")));

- (void)setConfig:(ISAdQualityConfig *)config;

- (void)setMetaData:(NSString *)value forKey:(NSString *)key;

@end

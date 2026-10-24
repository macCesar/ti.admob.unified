#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Configuration object for `+[UCLCoherenceLibrary initializeInstanceWithConfig:]`.

 Build with `+config`, then set the fields you need.

 Set `source` to `@(UCLCoherenceSourceAds)`.
 */
UCL_EXPORT
@interface UCLInitConfig : NSObject

/** Boxed source identifier. Use `@(UCLCoherenceSourceAds)`. nil = unspecified. */
@property (nonatomic, copy, nullable) NSNumber *source;

/** A new config with all fields unset. */
+ (instancetype)config;

@end

/**
 Integer source identifiers.

 Box with `@()` when assigning to the `source` property:
 ```
 config.source = @(UCLCoherenceSourceAds);
 ```
 */
typedef NS_ENUM(NSInteger, UCLCoherenceSource) {
    UCLCoherenceSourceAds = 2,
};

NS_ASSUME_NONNULL_END

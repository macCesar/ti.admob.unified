#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Configuration object for `-[UCLAttributesProvider getCommonAttributesWithConfig:]`.

 Build with `+config`, then set the fields you need. Unset fields (nil) are
 treated as unspecified (0).

 `productId` is a caller-supplied product identifier, orthogonal to the
 init-time source. Currently pass-through.

 `eventId` is a caller-supplied per-call event/correlation id. Currently
 pass-through.
 */
UCL_EXPORT
@interface UCLCommonAttributesConfig : NSObject

/** Boxed product identifier. nil = unspecified. */
@property (nonatomic, copy, nullable) NSNumber *productId;
/** Boxed per-call event/correlation id. nil = unspecified. */
@property (nonatomic, copy, nullable) NSNumber *eventId;

/** A new config with all fields unset. */
+ (instancetype)config;

@end

NS_ASSUME_NONNULL_END

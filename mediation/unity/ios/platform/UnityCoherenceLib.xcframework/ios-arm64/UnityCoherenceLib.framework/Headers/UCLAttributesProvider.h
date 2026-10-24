#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLCommonAttributesConfig.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Exposes metadata describing the hosting application. The Android counterpart
 is `com.unity3d.coherence.AttributesProvider`.
 */
@protocol UCLAttributesProvider <NSObject>

/**
 Returns all device/app attributes as a raw protected payload (opaque bytes).

 @param config Configuration carrying `productId` (0 = unspecified) and
               `eventId` (0 = unspecified).
 @return Raw protected payload bytes, or nil on error.
 */
- (nullable NSData *)getCommonAttributesWithConfig:(UCLCommonAttributesConfig *)config;

@end

NS_ASSUME_NONNULL_END

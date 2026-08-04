#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLCommonAttributesConfig.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Exposes metadata describing the hosting application. The Android counterpart
 is `com.unity3d.coherence.AttributesProvider`.
 */
@protocol UCLAttributesProvider <NSObject>

/**
 Returns all device/app attributes as raw proto3 bytes (protected payload).

 The bytes decode to a `unity.coherence.CommonAttributes` message
 (see `proto/common_attributes.proto`) after unprotecting the envelope.

 Within the proto message, an empty string field signals "unavailable";
 the encoder omits empty strings on the wire. The field set may grow;
 callers should ignore unknown fields per proto3 semantics.

 @param config Configuration carrying `productId` (0 = unspecified) and
               `eventId` (0 = unspecified). Both are orthogonal to the
               init-time source and currently pass-through.
 @return Raw protected payload bytes, or nil on error.
 */
- (nullable NSData *)getCommonAttributesWithConfig:(UCLCommonAttributesConfig *)config;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Accepts identifiers associated with the host app. Values supplied through
 this protocol are surfaced through `-[UCLAttributesProvider getCommonAttributesWithConfig:]`.
 The Android counterpart is `com.unity3d.coherence.IdentityProvider`.
 */
@protocol UCLIdentityProvider <NSObject>

/**
 Sets a host-provided external user id. Pass `nil` or an empty string to clear it.

 The value is exposed in `-[UCLAttributesProvider getCommonAttributesWithConfig:]` as the
 `external_user_id` field (proto field 3) when set, and is omitted from the
 encoded payload when unset/empty. The value is held in memory only — it is
 not persisted across process restarts.
 */
- (void)setExternalUserId:(nullable NSString *)externalUserId;

@end

NS_ASSUME_NONNULL_END

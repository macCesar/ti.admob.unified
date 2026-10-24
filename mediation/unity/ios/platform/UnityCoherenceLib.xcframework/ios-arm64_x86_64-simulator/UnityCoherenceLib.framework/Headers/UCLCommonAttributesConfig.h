#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Configuration object for `-[UCLAttributesProvider getCommonAttributesWithConfig:]`.

 Build with `+config`, then set the fields you need. Unset fields (nil) are
 treated as unspecified (0).

 `productId` is a caller-supplied product identifier, orthogonal to the
 init-time source.

 `eventId` is a caller-supplied per-call event/correlation id.

 Both are forwarded as input to the native `common_attributes` plugin,
 which uses them to gate which public fields are emitted: the essential
 identity block ships on every request; the install-scoped identifiers
 (encrypted local storage, installation id, idfi) ship only when
 `eventId` is unset/0 (regardless of `productId`); every other field
 ships only on a non-baseline (anything other than 0/0) request. Fraud-signal
 collection is gated independently and only by `eventId`: it runs
 whenever `eventId` is unset/0, regardless of `productId` — so a
 non-zero `productId` paired with `eventId` unset/0 ships the full field
 set (still including the install-scoped identifiers) together with
 fraud-signal data. See docs/c-abi.md#get-common-attributes in the
 native repo.

 Note: installation id is currently disabled build-wide (native
 `DISABLE_IDENTITY`), so it is not present in the payload regardless of
 `productId`/`eventId` — the field descriptions above describe what
 scope makes eligible, not what ships today. idfi is collected whenever
 in scope (`eventId` unset/0), regardless of `DISABLE_IDENTITY`.
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

#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLExport.h>
#import <UnityCoherenceLib/UCLAttributesProvider.h>
#import <UnityCoherenceLib/UCLIdentityProvider.h>
#import <UnityCoherenceLib/UCLCoherenceProvider.h>
#import <UnityCoherenceLib/UCLInitConfig.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Singleton entry point for the Unity Coherence Library on iOS.

 Call `+initializeInstanceWithConfig:` once at app startup, passing a
 `UCLInitConfig` whose `source` is one of the
 `UNITY_COHERENCE_LIBRARY_SOURCE_*` constants defined in
 `shared/include/unity/coherence/library.h`. Idempotent — subsequent
 calls are no-ops (the first `source` wins).
 */
UCL_EXPORT
@interface UCLCoherenceLibrary : NSObject

/**
 Initializes the singleton with the given config. `config.source` must
 be one of the `UNITY_COHERENCE_LIBRARY_SOURCE_*` constants from
 `shared/include/unity/coherence/library.h`; unknown values are
 rejected by the C layer.
 */
+ (void)initializeInstanceWithConfig:(UCLInitConfig *)config;

/** Returns the initialized singleton. Raises if not yet initialized. */
+ (instancetype)shared;

@property (nonatomic, strong, readonly) id<UCLAttributesProvider> attributesProvider;
@property (nonatomic, strong, readonly) id<UCLIdentityProvider>   identityProvider;
@property (nonatomic, strong, readonly) id<UCLCoherenceProvider>  coherenceProvider;

/** Raw UNAT-wrapped proto3 Versions bytes describing which bridges are
 *  registered and at what version. Schema in proto/versions.proto;
 *  see docs/c-abi.md#get-versions. Returns nil on error. */
- (nullable NSData *)getVersions;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

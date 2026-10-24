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
 `UCLInitConfig`. Idempotent — subsequent calls are no-ops (the first
 `source` wins).
 */
UCL_EXPORT
@interface UCLCoherenceLibrary : NSObject

/** Initializes the singleton with the given config. */
+ (void)initializeInstanceWithConfig:(UCLInitConfig *)config;

/** Returns the initialized singleton. Raises if not yet initialized. */
+ (instancetype)shared;

@property (nonatomic, strong, readonly) id<UCLAttributesProvider> attributesProvider;
@property (nonatomic, strong, readonly) id<UCLIdentityProvider>   identityProvider;
@property (nonatomic, strong, readonly) id<UCLCoherenceProvider>  coherenceProvider;

/** Plain (unprotected) proto3 Versions bytes. Schema in proto/versions.proto;
 *  see docs/c-abi.md#get-versions. Returns nil on error. */
- (nullable NSData *)getVersions;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

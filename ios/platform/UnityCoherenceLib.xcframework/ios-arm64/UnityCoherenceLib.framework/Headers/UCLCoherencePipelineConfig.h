#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Configuration object for `-[UCLCoherenceProvider createWithConfig:error:]`.

 Build with `+config`, then set the fields you need.

 `wasmBytes` is the pre-compiled WebAssembly module to load into each worker.
 nil leaves the pipeline without a module.

 `concurrency` defaults to `@(1)`. To trigger an `UCLCoherenceErrorInvalidArg`
 failure from `createWithConfig:error:` a caller must explicitly set `concurrency`
 back to nil (or a boxed value less than 1).
 */
UCL_EXPORT
@interface UCLCoherencePipelineConfig : NSObject

/** Pre-compiled WebAssembly module. nil = none. */
@property (nonatomic, copy, nullable) NSData *wasmBytes;
/** Boxed worker thread count. Default `@(1)`; nil → rejected as INVALID_ARG. */
@property (nonatomic, copy, nullable) NSNumber *concurrency;

/** A new config with all fields unset. */
+ (instancetype)config;

@end

NS_ASSUME_NONNULL_END

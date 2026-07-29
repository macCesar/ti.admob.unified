#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLCoherencePipeline.h>
#import <UnityCoherenceLib/UCLCoherencePipelineConfig.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Singleton factory for `UCLCoherencePipeline`. Reach it via
 `[UCLCoherenceLibrary.shared coherenceProvider]`.
 */
@protocol UCLCoherenceProvider <NSObject>

/**
 Build a pipeline preloaded with `config.wasmBytes` and a worker pool of
 `config.concurrency` threads. Returns nil and fills `error` if any worker
 fails to load the module — partial state is cleaned up before the return.
 `config.concurrency < 1` returns nil with code 5 (INVALID_ARG).
 */
- (nullable id<UCLCoherencePipeline>)createWithConfig:(UCLCoherencePipelineConfig *)config
                                                error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 NSError domain for UCLCoherencePipeline failures. The `code` field carries
 a `UCLCoherenceError` value.
 */
FOUNDATION_EXPORT UCL_EXPORT NSErrorDomain const UCLCoherenceErrorDomain;

/** Named error codes for `UCLCoherenceErrorDomain`. */
typedef NS_ERROR_ENUM(UCLCoherenceErrorDomain, UCLCoherenceError) {
    UCLCoherenceErrorInvalidBundle = 1,
    UCLCoherenceErrorLoad          = 2,
    UCLCoherenceErrorInvalidHandle = 3,
    UCLCoherenceErrorTrap          = 4,
    UCLCoherenceErrorInvalidArg    = 5,
    UCLCoherenceErrorInternal      = 6,
};

/**
 A pool of `concurrency` workers, each loaded with the same wasm module.
 `executeWithInput:error:` dispatches work to a worker; `loadWasmBytes:error:`
 replaces the module on every worker.

 Threading: every method blocks the caller. May be called from any thread.

 Lifecycle: call `close` (or release the last reference) to drop all workers.
 */
@protocol UCLCoherencePipeline <NSObject>

/**
 Replace the wasm module on every worker, waiting for any in-flight execute
 to finish first. Returns YES on success; returns NO and fills `error` on
 failure.
 */
- (BOOL)loadWasmBytes:(NSData *)wasmBytes
                error:(NSError **)error;

/**
 Run the loaded module against `input` on a worker. Output bytes are copied;
 the caller owns the returned `NSData`. Returns nil and fills `error` on
 failure.
 */
- (nullable NSData *)executeWithInput:(NSData *)input
                                error:(NSError **)error;

@property (nonatomic, readonly) NSInteger concurrency;

/** Drops all VMs and joins worker threads. Idempotent. */
- (void)close;

@end

NS_ASSUME_NONNULL_END

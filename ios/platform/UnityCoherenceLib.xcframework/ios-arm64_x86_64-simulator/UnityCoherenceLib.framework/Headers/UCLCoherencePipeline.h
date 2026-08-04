#import <Foundation/Foundation.h>
#import <UnityCoherenceLib/UCLExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 NSError domain for UCLCoherencePipeline failures. The `code` field carries
 a `UCLCoherenceError` value mirrored from `unity_coherence_vm_status_t`.
 See `docs/c-abi.md#status-codes`.
 */
FOUNDATION_EXPORT UCL_EXPORT NSErrorDomain const UCLCoherenceErrorDomain;

/** Named error codes for `UCLCoherenceErrorDomain`. Mirror `unity_coherence_vm_status_t`. */
typedef NS_ERROR_ENUM(UCLCoherenceErrorDomain, UCLCoherenceError) {
    UCLCoherenceErrorInvalidBundle = 1,
    UCLCoherenceErrorLoad          = 2,
    UCLCoherenceErrorInvalidHandle = 3,
    UCLCoherenceErrorTrap          = 4,
    UCLCoherenceErrorInvalidArg    = 5,
    UCLCoherenceErrorInternal      = 6,
};

/**
 Round-robin dispatcher across N VMs, each loaded with the same wasm
 module. `executeWithInput:error:` runs `unity_main` directly on the caller's
 thread; the C runtime's per-VM mutex serializes contention when two callers
 happen to round-robin to the same slot. `loadWasmBytes:error:` rebuilds
 every VM under an exclusive lock that drains in-flight executes.

 Threading: every method blocks the caller. May be called from any thread.

 Lifecycle: call `close` (or release the last reference) to drop all VMs.
 */
@protocol UCLCoherencePipeline <NSObject>

/**
 Replace the wasm module on every worker. Drains any in-flight execute,
 drops the old VMs, creates new ones. Returns YES on success; returns NO
 and fills `error` on failure.
 */
- (BOOL)loadWasmBytes:(NSData *)wasmBytes
                error:(NSError **)error;

/**
 Invoke `unity_main(input)` on a worker. Output bytes are copied; the
 caller owns the returned `NSData`. Returns nil and fills `error` on
 failure.
 */
- (nullable NSData *)executeWithInput:(NSData *)input
                                error:(NSError **)error;

@property (nonatomic, readonly) NSInteger concurrency;

/** Drops all VMs and joins worker threads. Idempotent. */
- (void)close;

@end

NS_ASSUME_NONNULL_END

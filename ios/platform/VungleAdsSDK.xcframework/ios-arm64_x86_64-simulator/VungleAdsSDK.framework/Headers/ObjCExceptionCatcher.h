//
//  ObjCExceptionCatcher.h
//  VungleAdsSDK
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// Catches Objective-C NSExceptions and bridges them to NSError
/// so Swift `do/catch` can handle them.
@interface ObjCExceptionCatcher : NSObject

/// Executes `block`; if an ObjC NSException is raised it is caught and
/// returned through the `error` out-parameter as an NSError.
/// @return YES when the block ran without exception, NO otherwise.
+ (BOOL)executeBlock:(void(NS_NOESCAPE ^)(void))block
               error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END

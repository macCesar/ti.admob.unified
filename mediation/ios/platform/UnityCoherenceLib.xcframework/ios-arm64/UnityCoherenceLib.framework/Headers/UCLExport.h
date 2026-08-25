#ifndef UCL_EXPORT_H
#define UCL_EXPORT_H

/**
 Marks a public symbol for export from the static framework.

 The framework target is compiled with GCC_SYMBOLS_PRIVATE_EXTERN=YES
 (see ios/project.yml) so that every symbol is hidden by default — that's
 what keeps the bundled wamr runtime and vendored crypto from leaking out
 and colliding with a consumer's own copies. Public ObjC classes and
 constants must opt back in, or they are unreachable to consumers once the
 symbol-hiding XCFramework merge (tools/merge-static-archive-into-framework.sh)
 localizes everything that isn't externally visible.

 Mirrors UCL_API for the C ABI (shared/include/unity/coherence/library.h).
 */
#define UCL_EXPORT __attribute__((visibility("default")))

#endif /* UCL_EXPORT_H */

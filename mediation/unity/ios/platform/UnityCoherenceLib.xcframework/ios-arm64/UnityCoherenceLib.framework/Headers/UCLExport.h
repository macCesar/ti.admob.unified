#ifndef UCL_EXPORT_H
#define UCL_EXPORT_H

/**
 Marks a public symbol for export from the static framework.

 Every symbol is hidden by default; public ObjC classes and constants must
 opt back in with this attribute, or they are unreachable to consumers.
 */
#define UCL_EXPORT __attribute__((visibility("default")))

#endif /* UCL_EXPORT_H */

Files in this folder are copied directly into the compiled product directory
when the iOS app is compiled:

    <project-dir>/build/iphone/build/Products/<Debug-iphonesimulator|Release-iphoneos>/<app name>.app/

Place your module's iOS bundles and localization files in this folder.

Files with matching paths overwrite files already in the build directory.
Avoid names used by the application or other modules.

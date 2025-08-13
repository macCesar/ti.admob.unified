#!/bin/bash

# Wrapper script for pod install that suppresses irrelevant errors
# Usage: ./install_frameworks.sh

echo "🚀 Installing AdMob frameworks with automatic mediation..."
echo ""

# Execute pod install and capture output
pod install 2>&1 | sed '/\[!\] Oh no, an error occurred\./,$d'

# Clean up CocoaPods files after installation
rm -rf Pods/ Podfile.lock ti.admob.unified.xcworkspace 2>/dev/null

# Verify frameworks were installed correctly
if [ -d "platform" ] && [ "$(ls -1 platform/*.xcframework 2>/dev/null | wc -l)" -gt 0 ]; then
    echo ""
    echo "✅ Installation completed successfully!"
    echo "📦 Frameworks installed in platform/"
    echo "🎯 Your module is ready to build with: ti build -p ios --build-only"
else
    echo ""
    echo "❌ Error: No frameworks found in platform/"
    echo "💡 Try running the command manually: pod install"
fi

echo ""

#!/bin/bash
set -e

echo "Building THISECURE release..."

# Android APK
echo "--- Building Android APK ---"
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info/android \
  --tree-shake-icons

APK_SIZE=$(ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5}')
echo "Android APK size: $APK_SIZE"

# Android App Bundle
echo "--- Building Android App Bundle ---"
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info/android \
  --tree-shake-icons

# iOS (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "--- Building iOS IPA ---"
  flutter build ipa --release \
    --obfuscate \
    --split-debug-info=build/debug-info/ios \
    --tree-shake-icons
fi

echo "Build complete!"

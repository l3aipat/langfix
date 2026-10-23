#!/bin/sh
# Builds build/LangFix.app as a universal (Apple Silicon + Intel) binary. Accessibility permission
# is granted per signed bundle, so the app must run from this bundle rather than from `swift run`.
set -eu
cd "$(dirname "$0")/.."
for arch in arm64 x86_64; do
    swift build -c release --product LangFix --triple "$arch-apple-macosx13.0" --scratch-path ".build/$arch"
done
app=build/LangFix.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
lipo -create -output "$app/Contents/MacOS/LangFix" .build/arm64/release/LangFix .build/x86_64/release/LangFix
cp Resources/Info.plist "$app/Contents/Info.plist"
mkdir -p "$app/Contents/Resources"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
cp -R Resources/th.lproj "$app/Contents/Resources/"
codesign --force --sign - "$app"
echo "$app"

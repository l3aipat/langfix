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
# Drop internal symbol names so the shipped binary says less about how it works.
strip -x "$app/Contents/MacOS/LangFix" 2>/dev/null
cp Resources/Info.plist "$app/Contents/Info.plist"
mkdir -p "$app/Contents/Resources"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
cp -R Resources/th.lproj "$app/Contents/Resources/"
mkdir -p "$app/Contents/Frameworks"
ditto .build/arm64/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework "$app/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath @executable_path/../Frameworks "$app/Contents/MacOS/LangFix"
# One identity for everything inside, so Sparkle's helpers pass its "same signer" check on update.
codesign --force --deep --sign "LangFix Signing" "$app/Contents/Frameworks/Sparkle.framework"
codesign --force --sign "LangFix Signing" "$app"
echo "$app"

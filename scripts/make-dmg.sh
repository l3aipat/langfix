#!/bin/sh
# Builds build/LangFix-<version>.dmg: the app plus an Applications shortcut to drag it onto.
set -eu
cd "$(dirname "$0")/.."
./scripts/bundle.sh
version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
stage=build/dmg
rm -rf "$stage"
mkdir -p "$stage"
cp -R build/LangFix.app "$stage/"
ln -s /Applications "$stage/Applications"
dmg="build/LangFix-$version.dmg"
rm -f "$dmg"
hdiutil create -volname LangFix -srcfolder "$stage" -format UDZO -ov "$dmg" >/dev/null
rm -rf "$stage"
echo "$dmg"

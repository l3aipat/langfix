#!/bin/sh
# Stages build/release/: LangFix.dmg and the Sparkle appcast.xml that points at it. Both go on the
# GitHub release, so .../releases/latest/download/<file> always serves the newest of each.
set -eu
cd "$(dirname "$0")/.."
repo=l3aipat/langfix
dmg=$(./scripts/make-dmg.sh | tail -1)
version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
build=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Resources/Info.plist)
minimum=$(/usr/libexec/PlistBuddy -c "Print LSMinimumSystemVersion" Resources/Info.plist)
out=build/release
rm -rf "$out"
mkdir -p "$out"
cp "$dmg" "$out/LangFix.dmg"
signature=$(.build/arm64/artifacts/sparkle/Sparkle/bin/sign_update "$out/LangFix.dmg")
cat > "$out/appcast.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>LangFix</title>
    <item>
      <title>$version</title>
      <link>https://github.com/$repo/releases/tag/v$version</link>
      <sparkle:version>$build</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$minimum</sparkle:minimumSystemVersion>
      <enclosure url="https://github.com/$repo/releases/download/v$version/LangFix.dmg" type="application/octet-stream" $signature/>
    </item>
  </channel>
</rss>
EOF
echo "staged $out for v$version. Publish with:"
echo "  gh release create v$version $out/LangFix.dmg $out/appcast.xml --repo $repo --title \"LangFix $version\" --notes \"...\""

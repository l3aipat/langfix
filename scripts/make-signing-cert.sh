#!/bin/sh
# Creates the self-signed "LangFix Signing" identity in the login keychain, once. macOS ties the
# Accessibility grant to the signing certificate, so signing every build with this one identity
# keeps the grant across updates; ad-hoc signing changes identity on every build.
# Back the identity up (Keychain Access > export as .p12): losing it means every user re-grants once.
set -eu
name="LangFix Signing"
if security find-certificate -c "$name" >/dev/null 2>&1; then
    echo "$name already exists"
    exit 0
fi
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
openssl req -x509 -newkey rsa:2048 -nodes -days 7300 -subj "/CN=$name" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -keyout "$tmp/key.pem" -out "$tmp/cert.pem" 2>/dev/null
openssl pkcs12 -export -legacy -inkey "$tmp/key.pem" -in "$tmp/cert.pem" -name "$name" \
    -passout pass:langfix -out "$tmp/id.p12"
security import "$tmp/id.p12" -k ~/Library/Keychains/login.keychain-db -P langfix -T /usr/bin/codesign
echo "created $name"

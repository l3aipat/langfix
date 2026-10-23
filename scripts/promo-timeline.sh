#!/bin/sh
# Builds scripts/promo-timeline.swift against the app's corrector and lexicon, plays the given
# messages through it, and writes the typing timeline into scripts/make-promo.swift between its
# "generated replies" markers. Example:
#   scripts/promo-timeline.sh "ได้เลย เดี๋ยวส่ง location ให้" "งั้น confirm อีกทีตอนเย็น"
set -eu
cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
grep -v '^import LangFixCore' Sources/LangFix/SpellLexicon.swift > "$work/SpellLexicon.swift"
cp scripts/promo-timeline.swift "$work/main.swift"
swiftc -O -module-name PromoTimeline -o "$work/timeline" Sources/LangFixCore/*.swift "$work/SpellLexicon.swift" "$work/main.swift"
"$work/timeline" "$@" > "$work/replies.swift"
perl -0pi -e 'BEGIN { local $/; open my $f, "<", shift @ARGV; $r = <$f> } s{// BEGIN generated replies\n.*?// END generated replies\n}{// BEGIN generated replies\n$r// END generated replies\n}s' \
    "$work/replies.swift" scripts/make-promo.swift
echo "updated scripts/make-promo.swift"

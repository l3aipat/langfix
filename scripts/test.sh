#!/bin/sh
# Command Line Tools ship Swift Testing outside the default search paths.
set -eu
cd "$(dirname "$0")/.."
dev=/Library/Developer/CommandLineTools/Library/Developer
swift run check-layout
swift test -Xswiftc -F$dev/Frameworks -Xlinker -F$dev/Frameworks \
    -Xlinker -rpath -Xlinker $dev/Frameworks -Xlinker -rpath -Xlinker $dev/usr/lib

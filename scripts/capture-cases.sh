#!/bin/sh
# Cold-starts the app and screenshots each case of the automatic sequence:
# cold launch, mid first animated toggle, after the instant toggle, and the same pair again.
#   scripts/capture-cases.sh <simulator udid> <output dir> [bundle id]
# Run `npx expo start` first and keep its log; scripts/summarize.py reads the [52396] lines.
UDID=$1; OUT=${2:-cases}; BUNDLE=${3:-dev.dileepapeiris.rnhostviewresizerepro}
mkdir -p "$OUT"
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null
xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
shot() { sleep "$1"; xcrun simctl io "$UDID" screenshot "$OUT/$2.png" >/dev/null 2>&1; }
shot 2.2 cold-launch                 # before the first toggle at 3 s
shot 1.2 mid-animated-1              # 3.4 s: 0.4 s into the 0.8 s animation
shot 3.1 after-instant-1             # 6.5 s: 0.5 s after the instant toggle
shot 2.9 mid-animated-2              # 9.4 s
shot 3.1 after-instant-2             # 12.5 s
echo "screenshots in $OUT"

#!/bin/sh
# Relaunches the app on a booted simulator and takes screenshots as fast as simctl allows for
# ~7 s, which covers the automatic toggles at 3 s and 6 s. Frames land in shots/f_<ms>.png.
#   scripts/capture.sh <simulator udid> [bundle id]
set -e
UDID=$1
BUNDLE=${2:-dev.dileepapeiris.rnhostviewresizerepro}
OUT=${OUT:-shots}
rm -rf "$OUT" && mkdir -p "$OUT"
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
START=$(python3 -c 'import time;print(int(time.time()*1000))')
while :; do
  NOW=$(python3 -c 'import time;print(int(time.time()*1000))')
  EL=$((NOW-START))
  [ "$EL" -gt 7200 ] && break
  if [ "$EL" -gt 2200 ]; then
    xcrun simctl io "$UDID" screenshot --type=png "$OUT/f_$(printf %05d "$EL").png" >/dev/null 2>&1
  fi
done
echo "frames: $(ls "$OUT" | wc -l | tr -d ' ')"

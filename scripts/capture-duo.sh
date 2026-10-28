#!/bin/sh
# Records the iPhone Duo folding into book pose and back to flat while the ArrangementView screen
# is showing, and screenshots the middle of each fold animation.
#   scripts/capture-duo.sh <duo udid> <output prefix>      e.g. scripts/capture-duo.sh F18D... media/duo-before
# Before running: the Duo is booted, open and in landscape, the app is on the ArrangementView
# screen, Metro is running, and Device Hub is open on the Duo (scripts/devicehub.sh needs it).
UDID=$1; OUT=$2
HERE=$(dirname "$0")
xcrun simctl io "$UDID" recordVideo --codec h264 --force "$OUT.mp4" &
sleep 1.5
sh "$HERE/devicehub.sh" "Partially Open" >/dev/null
sleep 3.5
sh "$HERE/devicehub.sh" "Open" >/dev/null
sleep 3.5
pkill -INT -f "simctl io $UDID recordVideo"
wait
# Screenshots cannot run while recording, so repeat the folds for them.
sh "$HERE/devicehub.sh" "Partially Open" >/dev/null
sleep 0.35; xcrun simctl io "$UDID" screenshot "$OUT-mid-fold.png" >/dev/null 2>&1
sleep 3
sh "$HERE/devicehub.sh" "Open" >/dev/null
sleep 0.35; xcrun simctl io "$UDID" screenshot "$OUT-mid-unfold.png" >/dev/null 2>&1
sleep 3; xcrun simctl io "$UDID" screenshot "$OUT-flat.png" >/dev/null 2>&1
echo "wrote $OUT.mp4 $OUT-mid-fold.png $OUT-mid-unfold.png $OUT-flat.png"

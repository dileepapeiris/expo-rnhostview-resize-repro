#!/bin/sh
# Relaunches the app on a booted simulator and takes screenshots as fast as simctl allows for
# ~7 s, which covers the automatic toggles at 3 s and 6 s. Frames land in shots/f_<ms>.png.
#   scripts/capture.sh <simulator udid> [bundle id]

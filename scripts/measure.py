"""Measures, per screenshot, how wide each card and its blue button are.

Needs only the Python standard library and `sips` (macOS): each PNG is converted to BMP and
scanned for the longest run of the card's grey (#f2f2f7) and the button's blue (#007aff) on the
rows of the SwiftUI card (top) and the React Native card (bottom). Pixel values are at 3x.

    python3 scripts/measure.py shots
"""
import glob
import os
import struct
import subprocess
import sys


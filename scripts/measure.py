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

GREY = lambda p: abs(p[0] - 0xF2) <= 4 and abs(p[1] - 0xF2) <= 4 and abs(p[2] - 0xF7) <= 4
BLUE = lambda p: p[0] < 0x30 and 0x60 <= p[1] <= 0x90 and p[2] >= 0xE0
# Rows of the two cards on an iPhone 17 (1206 x 2622) with the layout in App.tsx.
TOP_ROWS = range(380, 1150, 20)
BOTTOM_ROWS = range(1200, 1990, 20)


def read_rows(bmp_path, ys):
    data = open(bmp_path, "rb").read()
    offset = struct.unpack_from("<I", data, 10)[0]
    width = struct.unpack_from("<i", data, 18)[0]
    height = struct.unpack_from("<i", data, 22)[0]
    bpp = struct.unpack_from("<H", data, 28)[0] // 8
    bottom_up = height > 0
    height = abs(height)
    stride = ((width * bpp + 3) // 4) * 4
    rows = {}
    for y in ys:
        ry = (height - 1 - y) if bottom_up else y
        base = offset + ry * stride
        rows[y] = [(data[base + x * bpp + 2], data[base + x * bpp + 1], data[base + x * bpp]) for x in range(width)]
    return rows



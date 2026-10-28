"""Width of the blue button on each side of the ArrangementView, per video frame.

    python3 scripts/measure-frames.py <frames dir> [from ms] [to ms]

Frames come from `swift scripts/compose.swift frames <video> <dir> 20`. Each frame is scaled
down with `sips`, converted to BMP, and scanned for the widest run of the system blue
(#007AFF-ish) in the left half (SwiftUI card) and the right half (React Native card), in the
band of rows where the buttons sit. The two widths per frame show which side animates.
Standard library only.
"""
import os, struct, subprocess, sys, tempfile

def rows(path, width_px=713):
    with tempfile.TemporaryDirectory() as tmp:
        bmp = os.path.join(tmp, 'f.bmp')
        subprocess.run(['sips', '-Z', str(width_px), '-s', 'format', 'bmp', path, '--out', bmp], check=True, capture_output=True)
        data = open(bmp, 'rb').read()
    offset = struct.unpack_from('<I', data, 10)[0]
    width, height = struct.unpack_from('<ii', data, 18)
    bpp = struct.unpack_from('<H', data, 28)[0] // 8
    stride = (width * bpp + 3) & ~3
    flipped = height > 0
    height = abs(height)
    out = []
    for y in range(height):
        src = (height - 1 - y) if flipped else y
        base = offset + src * stride
        out.append([data[base + x * bpp: base + x * bpp + 3] for x in range(width)])
    return out

def is_blue(px):
    b, g, r = px
    return b > 200 and r < 80 and 90 < g < 170

def widest(row, lo, hi):
    best = run = 0
    for x in range(lo, hi):
        if is_blue(row[x]):
            run += 1; best = max(best, run)
        else:
            run = 0
    return best

if __name__ == '__main__':
    d = sys.argv[1]
    lo_ms = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    hi_ms = int(sys.argv[3]) if len(sys.argv) > 3 else 10 ** 9
    print(f"{'ms':>6}  {'SwiftUI button':>14}  {'RN button':>9}   (px at 713 px frame width)")
    for name in sorted(os.listdir(d)):
        if not name.endswith('.png'): continue
        ms = int(name[2:7])
        if ms < lo_ms or ms > hi_ms: continue
        px = rows(os.path.join(d, name))
        h, w = len(px), len(px[0])
        left = right = 0
        for y in range(int(0.3 * h), int(0.85 * h)):
            left = max(left, widest(px[y], 0, w // 2))
            right = max(right, widest(px[y], w // 2, w))
        print(f'{ms:>6}  {left:>14}  {right:>9}')

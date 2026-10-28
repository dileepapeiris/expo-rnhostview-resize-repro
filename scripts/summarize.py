"""Summarises the [52396] lines of a Metro log into one row per phase.

    python3 scripts/summarize.py <metro log>

Each toggle line starts a phase; each onLayout line is counted in the current phase
with its width, so the output shows how many layouts a phase produced, and the first
and last width Yoga laid the hosted tree out at.
"""
import re, sys

TOGGLE = re.compile(r'\[52396\] (AUTO-TOGGLE \d+|TAP) (ANIMATED|INSTANT) -> (\d+)')
LAYOUT = re.compile(r'\[52396\] onLayout #\d+ width=([\d.]+) height=[\d.]+ (?:\+(\d+)ms after toggle|cold launch)')

def summarize(lines):
    phases = [{'name': 'cold launch', 'target': None, 'widths': [], 'times': []}]
    for line in lines:
        m = TOGGLE.search(line)
        if m:
            phases.append({'name': f'{m.group(2).lower()} -> {m.group(3)}', 'target': int(m.group(3)), 'widths': [], 'times': []})
            continue
        m = LAYOUT.search(line)
        if m:
            phases[-1]['widths'].append(float(m.group(1)))
            phases[-1]['times'].append(int(m.group(2)) if m.group(2) else None)
    return phases

if __name__ == '__main__':
    lines = open(sys.argv[1], errors='replace').read().splitlines()
    print(f"{'phase':<20}{'layouts':>8}  {'first width':>11}  {'last width':>10}  {'span':>12}")
    for ph in summarize(lines):
        w = ph['widths']
        first = f'{w[0]:.1f}' if w else '-'
        last = f'{w[-1]:.1f}' if w else '-'
        t = [x for x in ph['times'] if x is not None]
        span = f'{t[0]}-{t[-1]} ms' if t else ''
        print(f"{ph['name']:<20}{len(w):>8}  {first:>11}  {last:>10}  {span:>12}")

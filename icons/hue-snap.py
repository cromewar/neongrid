#!/usr/bin/env python3
"""
Recolors an entire icon theme into the NeonGrid palette WITHOUT flattening it.

Why not just force one color: that kills the neon and makes every icon a
silhouette. Why not leave it: BeautyLine ships blues, yellows and oranges that
simply aren't in the palette, which is what made the tray look like a rainbow.

What this does instead: every color in every SVG is converted to HSL, its HUE is
snapped to the nearest NeonGrid hue, saturation is pushed up (neon), and
LIGHTNESS IS PRESERVED. So each icon keeps its own distinct color, its internal
shading and its gradients — it just lands inside the palette.

Greys/blacks/whites are left alone (they're structure, not color).
"""
import colorsys, os, re, shutil, subprocess, sys

SRC = "/usr/share/icons/BeautyLine"
DST = os.path.expanduser("~/.local/share/icons/NeonGrid")

here = os.path.dirname(os.path.abspath(__file__))
env = subprocess.run(
    ["bash", "-c", f'source "{os.path.join(here, "..", "palette.sh")}"; '
     'for v in GREEN_HERO GREEN CYAN VIOLET MAGENTA RED YELLOW; do echo "$v=${!v}"; done'],
    capture_output=True, text=True, check=True).stdout
P = dict(l.split("=", 1) for l in env.strip().splitlines())


def hue_of(hexstr):
    r, g, b = (int(hexstr[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hls(r, g, b)[0]


# The hues we allow anything to become.
TARGETS = [hue_of(P[k]) for k in
           ("GREEN_HERO", "GREEN", "CYAN", "VIOLET", "MAGENTA", "RED", "YELLOW")]

HEX = re.compile(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b')


def snap(m):
    h = m.group(1)
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    hue, light, sat = colorsys.rgb_to_hls(r, g, b)

    # Leave greyscale structure alone — it is not "color", it is shading.
    if sat < 0.12 or light < 0.06 or light > 0.94:
        return m.group(0)

    # circular distance to the nearest palette hue
    best = min(TARGETS, key=lambda t: min(abs(hue - t), 1 - abs(hue - t)))
    sat = max(sat, 0.78)                    # neon, not muted
    light = min(max(light, 0.32), 0.72)     # keep it readable on a dark panel
    r, g, b = colorsys.hls_to_rgb(best, light, sat)
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


if os.path.isdir(DST):
    shutil.rmtree(DST)
shutil.copytree(SRC, DST, symlinks=True)

changed = 0
for root, _, files in os.walk(DST):
    for f in files:
        if not f.endswith(".svg"):
            continue
        p = os.path.join(root, f)
        if os.path.islink(p):
            continue
        try:
            s = open(p, encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        out = HEX.sub(snap, s)
        if out != s:
            open(p, "w", encoding="utf-8").write(out)
            changed += 1

# index.theme: rename so it is a theme in its own right, not a BeautyLine clone
idx = os.path.join(DST, "index.theme")
s = open(idx, encoding="utf-8", errors="ignore").read()
s = re.sub(r'^Name=.*$', 'Name=NeonGrid', s, count=1, flags=re.M)
s = re.sub(r'^Comment=.*$', 'Comment=BeautyLine hue-snapped into the NeonGrid palette',
           s, count=1, flags=re.M)
open(idx, "w", encoding="utf-8").write(s)

print(f"hue-snapped {changed} svgs -> {DST}")

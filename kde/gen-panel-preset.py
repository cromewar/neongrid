#!/usr/bin/env python3
"""
Generates a 'NeonGrid' Panel Colorizer preset by recoloring the bundled
'Neon Lights' preset. Starting from a shipped preset (rather than authoring the
JSON blob from scratch) means we inherit the exact schema this version expects —
Panel Colorizer's settings format is large and version-specific.

Writes to ~/.config/panel-colorizer/presets/NeonGrid/settings.json and prints the
globalSettings JSON so install.sh can push it into the applet config.
"""
import json, os, re, shutil, sys, subprocess

BASE = "/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/Neon Lights/settings.json"
OUT_DIR = os.path.expanduser("~/.config/panel-colorizer/presets/NeonGrid")

# pull the palette from the single source of truth
here = os.path.dirname(os.path.abspath(__file__))
pal_sh = os.path.join(here, "..", "palette.sh")
env = subprocess.run(
    ["bash", "-c", f'source "{pal_sh}"; '
     'for v in BG SURFACE SURFACE_HI FG GREEN GREEN_HERO VIOLET MAGENTA SEL_BG; '
     'do echo "$v=${!v}"; done'],
    capture_output=True, text=True, check=True).stdout
P = dict(line.split("=", 1) for line in env.strip().splitlines())
hx = lambda k: "#" + P[k]

with open(BASE) as f:
    d = json.load(f)

g = d["globalSettings"]
panel = g["panel"]["normal"]

# --- panel: translucent near-black slab, blurred, rounded ---------------
panel["enabled"] = True
panel["blurBehind"] = True

bg = panel["backgroundColor"]
bg.update(enabled=True, sourceType=0, custom=hx("BG"), alpha=0.55)

fg = panel["foregroundColor"]
fg.update(enabled=True, sourceType=0, custom=hx("FG"), alpha=1)

panel["radius"] = {"enabled": True,
                   "corner": {"topLeft": 12, "topRight": 12,
                              "bottomRight": 12, "bottomLeft": 12}}
panel["margin"] = {"enabled": True,
                   "side": {"left": 8, "right": 8, "top": 6, "bottom": 6}}

# --- the neon edge ------------------------------------------------------
border = panel["border"]
border["enabled"] = True
border["customSides"] = False
border["width"] = 2
bcol = border.setdefault("color", {})
bcol.update(sourceType=0, custom=hx("GREEN_HERO"), alpha=1)
border.setdefault("radius", {"enabled": True,
                             "corner": {"topLeft": 12, "topRight": 12,
                                        "bottomRight": 12, "bottomLeft": 12}})

# --- the glow (shadow tinted hero green) --------------------------------
shadow = panel["shadow"]["background"]
shadow["enabled"] = True
shadow.setdefault("color", {}).update(sourceType=0, custom=hx("GREEN_HERO"), alpha=1)
for k, v in (("size", 18), ("xOffset", 0), ("yOffset", 0)):
    if k in shadow or True:
        shadow[k] = v

# --- widgets: violet islands on the panel -------------------------------
wn = g["widgets"]["normal"]
wbg = wn.get("backgroundColor", {})
wbg.update(enabled=True, sourceType=0, custom=hx("SEL_BG"), alpha=0.45)
wn["backgroundColor"] = wbg
wfg = wn.get("foregroundColor", {})
wfg.update(enabled=True, sourceType=0, custom=hx("GREEN_HERO"), alpha=1)
wn["foregroundColor"] = wfg
wn["radius"] = {"enabled": True,
                "corner": {"topLeft": 8, "topRight": 8,
                           "bottomRight": 8, "bottomLeft": 8}}

os.makedirs(OUT_DIR, exist_ok=True)
with open(os.path.join(OUT_DIR, "settings.json"), "w") as f:
    json.dump(d, f, indent=1)

print(json.dumps(g), end="")  # stdout = globalSettings for install.sh
print(f"\npreset written: {OUT_DIR}/settings.json", file=sys.stderr)

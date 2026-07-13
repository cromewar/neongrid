#!/usr/bin/env python3
"""
Configures the Panel Colorizer applet in place.

We read the applet's OWN current globalSettings and patch it, rather than
injecting a bundled preset's JSON. The installed version's schema is a superset
of the shipped presets' (it adds gradient/image/backgroundClipping/etc.), so
patching-in-place is the only way to guarantee we write a shape this version
understands. Feeding it a stale shape is exactly how plasmashell ends up in a
crash loop.
"""
import json, os, subprocess, sys

APPLETSRC = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")
PLUGIN = "luisbocanegra.panel.colorizer"

here = os.path.dirname(os.path.abspath(__file__))
env = subprocess.run(
    ["bash", "-c", f'source "{os.path.join(here, "..", "palette.sh")}"; '
     'for v in BG SURFACE SURFACE_HI FG GREEN GREEN_HERO VIOLET MAGENTA SEL_BG; '
     'do echo "$v=${!v}"; done'],
    capture_output=True, text=True, check=True).stdout
P = dict(l.split("=", 1) for l in env.strip().splitlines())
hx = lambda k: "#" + P[k]


def find_applets():
    """Return [(containment, applet)] for every Panel Colorizer instance."""
    out, cur = [], None
    for line in open(APPLETSRC):
        line = line.strip()
        if line.startswith("[Containments]") and "[Applets]" in line and "Configuration" not in line:
            cur = line
        elif line == f"plugin={PLUGIN}" and cur:
            c = cur.split("[Containments][")[1].split("]")[0]
            a = cur.split("[Applets][")[1].split("]")[0]
            out.append((c, a))
    return out


def kread(c, a, key):
    r = subprocess.run(
        ["kreadconfig6", "--file", APPLETSRC,
         "--group", "Containments", "--group", c,
         "--group", "Applets", "--group", a,
         "--group", "Configuration", "--group", "General",
         "--key", key], capture_output=True, text=True)
    return r.stdout.strip()


def kwrite(c, a, key, val):
    subprocess.run(
        ["kwriteconfig6", "--file", APPLETSRC,
         "--group", "Containments", "--group", c,
         "--group", "Applets", "--group", a,
         "--group", "Configuration", "--group", "General",
         "--key", key, val], check=True)


def set_color(node, hexval, alpha=1.0):
    """sourceType 0 = custom color (1 = follow a system color)."""
    node["enabled"] = True
    node["sourceType"] = 0
    node["custom"] = hexval
    node["alpha"] = alpha


def patch(g):
    panel = g["panel"]["normal"]
    panel["enabled"] = True
    panel["blurBehind"] = True

    set_color(panel["backgroundColor"], hx("BG"), 0.55)
    set_color(panel["foregroundColor"], hx("FG"), 1)

    panel["radius"] = {"enabled": True, "corner": dict.fromkeys(
        ("topLeft", "topRight", "bottomRight", "bottomLeft"), 12)}
    panel["margin"] = {"enabled": True,
                       "side": {"left": 8, "right": 8, "top": 5, "bottom": 5}}

    # the neon edge
    b = panel["border"]
    b["enabled"] = True
    b["customSides"] = False
    b["width"] = 2
    if "color" not in b:
        b["color"] = json.loads(json.dumps(panel["foregroundColor"]))
    set_color(b["color"], hx("GREEN_HERO"), 1)
    b.setdefault("radius", {"enabled": True, "corner": dict.fromkeys(
        ("topLeft", "topRight", "bottomRight", "bottomLeft"), 12)})

    # the glow: a hero-green shadow behind the panel
    sh = panel["shadow"]["background"]
    sh["enabled"] = True
    set_color(sh["color"], hx("GREEN_HERO"), 1)
    for k, v in (("size", 16), ("xOffset", 0), ("yOffset", 0)):
        sh[k] = v

    # widgets become violet islands with neon icons
    w = g["widgets"]["normal"]
    set_color(w["backgroundColor"], hx("SEL_BG"), 0.45)
    set_color(w["foregroundColor"], hx("GREEN_HERO"), 1)
    w["radius"] = {"enabled": True, "corner": dict.fromkeys(
        ("topLeft", "topRight", "bottomRight", "bottomLeft"), 8)}
    if "shadow" in w and "background" in w["shadow"]:
        ws = w["shadow"]["background"]
        ws["enabled"] = False  # per-widget glow on top of panel glow = mush
    return g


applets = find_applets()
if not applets:
    sys.exit("no Panel Colorizer applet found — add the widget to a panel first")

for c, a in applets:
    raw = kread(c, a, "globalSettings")
    if not raw:
        print(f"  [{c}/{a}] no globalSettings yet — skipping", file=sys.stderr)
        continue
    g = patch(json.loads(raw))
    kwrite(c, a, "globalSettings", json.dumps(g, separators=(",", ":")))
    kwrite(c, a, "isEnabled", "true")
    kwrite(c, a, "hideWidget", "true")   # the applet itself must not be visible
    print(f"  configured Panel Colorizer at containment {c}, applet {a}")

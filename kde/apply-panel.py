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

    set_color(panel["backgroundColor"], hx("BG"), 0.72)
    set_color(panel["foregroundColor"], hx("FG"), 1)

    panel["radius"] = {"enabled": True, "corner": dict.fromkeys(
        ("topLeft", "topRight", "bottomRight", "bottomLeft"), 10)}
    panel["margin"] = {"enabled": True,
                       "side": {"left": 6, "right": 6, "top": 4, "bottom": 4}}

    # The edge.
    # A 2px FULL-OPACITY hero-green border reads as a highlighter rectangle, not
    # neon — a real neon edge is a THIN, PARTLY-TRANSPARENT line whose glow comes
    # from the shadow behind it, not from the line's own weight.
    b = panel["border"]
    b["enabled"] = True
    b["customSides"] = False
    b["width"] = 1
    if "color" not in b:
        b["color"] = json.loads(json.dumps(panel["foregroundColor"]))
    set_color(b["color"], hx("GREEN"), 0.55)
    b.setdefault("radius", {"enabled": True, "corner": dict.fromkeys(
        ("topLeft", "topRight", "bottomRight", "bottomLeft"), 10)})

    # The glow lives here: a soft, low-alpha green bloom behind the slab.
    sh = panel["shadow"]["background"]
    sh["enabled"] = True
    set_color(sh["color"], hx("GREEN"), 0.35)
    for k, v in (("size", 24), ("xOffset", 0), ("yOffset", 0)):
        sh[k] = v

    # Widgets: no per-widget slabs (that was the boxy mess).
    # Deliberately DO NOT force a single foreground color on icons — that
    # flattens every app mark to one flat hue and kills the neon. Coherence
    # comes from the NeonGrid icon theme (per-app gradients in palette), not
    # from steamrolling the colors here. Text/labels do follow the palette.
    w = g["widgets"]["normal"]
    w["backgroundColor"]["enabled"] = False
    w["foregroundColor"]["enabled"] = False
    w["radius"] = {"enabled": False, "corner": dict.fromkeys(
        ("topLeft", "topRight", "bottomRight", "bottomLeft"), 0)}
    if "shadow" in w and "background" in w["shadow"]:
        w["shadow"]["background"]["enabled"] = False
    return g


# --- system tray icon replacements ------------------------------------------
# Apps like Cohesion, Slack, Claude, Cider, ChatGPT, Antigravity and TickTick
# push their tray icon as an EMBEDDED PIXMAP over StatusNotifierItem — it never
# goes through the icon theme, so no amount of theming touches it (that's why
# TickTick still showed its old logo).
#
# Panel Colorizer can override them by rule: `match` is a regex tested against
# the tray item's name/title, `icon` is an icon-theme name. We point each at the
# NeonGrid icon we built, so the tray finally matches the dock.
#
# Matches must be specific. Several Electron apps register as
# chrome_status_icon_1@<app>; a bare ^chrome_status_icon would steal Notion
# Calendar and ChatGPT and paint them as TickTick.
#
# The names are the SNI Ids as registered on the bus, e.g.:
#   cohesion_status_icon_1 | Slack_status_icon_1 | Claude_status_icon_1
#   Cider_status_icon_1 | Antigravity_status_icon_1
#   chrome_status_icon_1@ticktick | chrome_status_icon_1@ChatGPT
#   chrome_status_icon_1@notion-calendar


def ci(s):
    """Case-insensitive pattern as character classes.

    Panel Colorizer compiles these with a bare `new RegExp(match)` (no flags
    argument), and ECMAScript has no `(?i)` inline modifier — that is PCRE/
    Python syntax. A `(?i)` rule therefore throws "Invalid regular expression:
    Invalid group" INSIDE the `.find()` predicate, which aborts the entire
    lookup: every rule after the bad one stops working and plasmashell logs the
    throw once per tray item per repaint. Expand to `[Ll]` classes instead.
    """
    return "".join(f"[{c.lower()}{c.upper()}]" if c.isalpha() else c for c in s)


TRAY_RULES = [
    {"description": "Cohesion",        "match": "^cohesion_status_icon",    "icon": "io.github.brunofin.Cohesion", "enabled": True},
    {"description": "Slack",           "match": "^Slack_status_icon",       "icon": "slack",                       "enabled": True},
    {"description": "Claude",          "match": "^Claude_status_icon",      "icon": "claude-desktop",              "enabled": True},
    {"description": "Cider",           "match": "^Cider_status_icon",       "icon": "cider",                       "enabled": True},
    {"description": "Antigravity",     "match": "^Antigravity_status_icon", "icon": "antigravity",                 "enabled": True},
    {"description": "ChatGPT",         "match": "ChatGPT",                  "icon": "chatgpt",                     "enabled": True},
    {"description": "Notion Calendar", "match": "notion-calendar",          "icon": "notion-calendar",             "enabled": True},
    {"description": "Linear",          "match": ci("linear"),               "icon": "linear-linux",                "enabled": True},
    {"description": "Proton Mail",     "match": ci("proton") + "[- ]?" + ci("mail"),      "icon": "proton-mail",                 "enabled": True},
    {"description": "TickTick",        "match": ci("ticktick"),             "icon": "ticktick",                    "enabled": True},
    {"description": "Codex",           "match": "^(Codex|openai)",          "icon": "openai-codex-desktop",        "enabled": True},
    {"description": "Arch-Update",     "match": "^Arch-Update",             "icon": "system-software-update",      "enabled": True},
]

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
    # Icon color comes from the NeonGrid icon theme, not from a global override.
    kwrite(c, a, "forceForegroundColor", "false")
    # The whole replacement feature is gated behind this toggle (default false) —
    # the rules are silently ignored without it.
    kwrite(c, a, "systemTrayIconsReplacementEnabled", "true")
    kwrite(c, a, "systemTrayIconUserReplacements",
           json.dumps(TRAY_RULES, separators=(",", ":")))
    print(f"  configured Panel Colorizer at containment {c}, applet {a} "
          f"(+{len(TRAY_RULES)} tray icon rules)")

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


def set_system_color(node, system_color, color_set, hexval, alpha=1.0):
    """sourceType 1 — resolve from the live colour scheme at paint time.

    Panel Colorizer does `Kirigami.Theme[systemColor]` under `colorSet`, so the
    panel re-colours itself the moment the colour scheme changes. That is what
    lets NeonGrid Light actually work: a Global Theme switch only rewrites
    kdeglobals, it never re-runs this script, so any colour pinned as a custom
    hex would stay dark on a light desktop.

    The colour set is chosen so these resolve to the SAME hexes the hardcoded
    dark values used, leaving the dark panel pixel-identical:
        View/backgroundColor   -> BG      (#0a0e0f dark, #f7faf8 light)
        View/textColor         -> FG      (#c6d0cb dark, #1a2422 light)
        View/positiveTextColor -> GREEN   (#3be05c dark, #0a6128 light)
    `custom` is still written as the dark value so the config stays readable and
    degrades sanely if someone flips sourceType back to 0 in the GUI.
    """
    node["enabled"] = True
    node["sourceType"] = 1
    node["systemColor"] = system_color
    node["systemColorSet"] = color_set
    node["custom"] = hexval
    node["alpha"] = alpha


LIGHT = subprocess.run(
    ["kreadconfig6", "--file", "kdeglobals", "--group", "General", "--key", "ColorScheme"],
    capture_output=True, text=True).stdout.strip().endswith("Light")


def patch(g):
    panel = g["panel"]["normal"]
    panel["enabled"] = True
    panel["blurBehind"] = True

    # The colour SOURCES follow the scheme on their own (see set_system_color),
    # but alpha and shadow geometry cannot — and those are what actually break
    # on light. A 0.55-alpha green hairline over near-white is a washed-out
    # sage smear, and a 24px green bloom becomes a dirty halo. Glow is a
    # dark-theme device: on light, raise the border to a crisp hairline and
    # replace the bloom with an ordinary drop shadow.
    bg_alpha = 0.82 if LIGHT else 0.72
    set_system_color(panel["backgroundColor"], "backgroundColor", "View", hx("BG"), bg_alpha)
    set_system_color(panel["foregroundColor"], "textColor", "View", hx("FG"), 1)

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
    set_system_color(b["color"], "positiveTextColor", "View", hx("GREEN"),
                     0.85 if LIGHT else 0.55)
    b.setdefault("radius", {"enabled": True, "corner": dict.fromkeys(
        ("topLeft", "topRight", "bottomRight", "bottomLeft"), 10)})

    # The glow lives here: a soft, low-alpha green bloom behind the slab, to
    # match the halo Klassy puts around windows. Both variants get it.
    #
    # What made this look filthy on light earlier was NOT the glow — it was the
    # doubled native panel edge below, plus a 0.55 hairline that washed out. The
    # bloom itself only needs pulling in, because a shadow composites downward:
    # the same alpha and radius that read as spill on near-black read as a
    # smudge on paper.
    sh = panel["shadow"]["background"]
    sh["enabled"] = True
    set_system_color(sh["color"], "positiveTextColor", "View", hx("GREEN"),
                     0.30 if LIGHT else 0.35)
    for k, v in (("size", 18 if LIGHT else 24), ("xOffset", 0), ("yOffset", 0)):
        sh[k] = v

    # Turn OFF Plasma's own panel background. Panel Colorizer paints its slab
    # ON TOP of the native one rather than replacing it, so with both enabled
    # every panel carries two edges and two shadows. On the dark theme that was
    # invisible — a dark native edge under a dark slab — but on light it is the
    # doubled outline that made the top and bottom bars look wrong.
    npb = g["nativePanel"]["background"]
    npb["enabled"] = False
    npb["shadow"] = False

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


def _icon_search_path():
    """Directories an icon name can actually resolve from at paint time.

    Deliberately NOT "anywhere under /usr/share/icons": this box has
    Colloid-Green-Light, BeautyLine and friends installed as *sources* for the
    hue-snap build, and none of them are in the active theme's inheritance
    chain. Counting those would mark a rule live for an icon Plasma will never
    find, which is the exact failure this gate exists to prevent.
    """
    theme = subprocess.run(
        ["kreadconfig6", "--file", "kdeglobals", "--group", "Icons", "--key", "Theme"],
        capture_output=True, text=True).stdout.strip() or "hicolor"
    roots = [os.path.expanduser("~/.local/share/icons"), "/usr/share/icons"]
    names = [theme]
    # Follow Inherits= one level; that is enough for our single-parent themes.
    for r in roots:
        idx = os.path.join(r, theme, "index.theme")
        if os.path.isfile(idx):
            for line in open(idx, encoding="utf-8", errors="replace"):
                if line.startswith("Inherits="):
                    names += [n.strip() for n in line.split("=", 1)[1].split(",") if n.strip()]
                    break
    names += ["hicolor"]
    out = [os.path.join(r, n) for n in names for r in roots if os.path.isdir(os.path.join(r, n))]
    out += [p for p in ("/usr/share/pixmaps",) if os.path.isdir(p)]
    return out


ICON_DIRS = _icon_search_path()


def icon_exists(name):
    """Is `name` resolvable as an icon on this machine?

    This gate is not optional. Panel Colorizer swaps a matched tray icon for the
    icon NAME given in the rule; if that name does not resolve, the tray item
    renders BLANK rather than falling back to the app's own icon. And
    icons/gen-icons.sh only builds a brand mark for apps that are actually
    installed — so on a machine without Slack/Linear/TickTick, those rules point
    at nothing and enabling them silently empties part of the system tray.
    """
    for root in ICON_DIRS:
        for _dirpath, _dirnames, filenames in os.walk(root):
            for f in filenames:
                stem, ext = os.path.splitext(f)
                if stem == name and ext.lower() in (".svg", ".png", ".svgz", ".xpm"):
                    return True
    return False


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

# Keep only the rules whose replacement icon actually resolves here; a rule
# pointing at a missing icon blanks the tray item instead of leaving it alone.
for _r in TRAY_RULES:
    _r["enabled"] = icon_exists(_r["icon"])
LIVE_RULES = [r for r in TRAY_RULES if r["enabled"]]
SKIPPED = [r["description"] for r in TRAY_RULES if not r["enabled"]]

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
    # the rules are silently ignored without it. Only turn it on when at least
    # one rule can actually resolve, or it blanks the tray (see icon_exists).
    kwrite(c, a, "systemTrayIconsReplacementEnabled",
           "true" if LIVE_RULES else "false")
    kwrite(c, a, "systemTrayIconUserReplacements",
           json.dumps(TRAY_RULES, separators=(",", ":")))
    print(f"  configured Panel Colorizer at containment {c}, applet {a} "
          f"({len(LIVE_RULES)}/{len(TRAY_RULES)} tray icon rules live)")

if SKIPPED:
    print(f"  tray rules off (icon not built on this machine): {', '.join(SKIPPED)}")

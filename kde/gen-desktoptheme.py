#!/usr/bin/env python3
"""
Builds the NeonGrid Plasma style — a thin package that inherits Breeze and
overrides exactly ONE file: widgets/tasks.svg (the dock task indicators).

Why a whole Plasma style for one SVG:
  The dock's running/active/hover indicator is drawn by the Plasma style, not by
  Panel Colorizer and not by the icon theme. Breeze's tasks.svg paints a filled
  9-slice slab behind the task cell — `hover-center` at 34% of
  [Colors:Button]DecorationHover and `focus-center` at 45% of DecorationFocus.
  With the NeonGrid palette those resolve to magenta #d96bff and hero green
  #39ff14, so hovering a dock icon drops a saturated violet brick behind it.

  Retuning the colors is the wrong lever: DecorationFocus/DecorationHover also
  drive focus rings and hover states in every Qt app, and dimming them there to
  fix the dock would flatten the neon everywhere else.

  So we keep Breeze's exact frame GEOMETRY (it is a fiddly 9-slice, and getting
  it wrong makes indicators jump or clip) and only change opacities and classes.

What actually changes:
  Breeze already draws a brighter accent line on one edge of the frame; the rest
  is the slab. So: zero the slab segments, keep the line, and recolor the
  `normal` (running-but-not-active) line from grey Text to the accent so a
  running app reads green rather than grey.

  Which edge the line goes on is NOT cosmetic guesswork — FrameSvg composes the
  9-slice by element NAME in screen orientation, so `<prefix>-bottom` always
  paints along the visual bottom regardless of panel edge. Verified by rendering
  a probe build with `-top` red and `-bottom` blue. The directional prefixes
  exist so the ARTWORK can differ per edge, not because the names rotate. So the
  indicator edge has to be chosen per prefix — see EDGE below.

Regenerate after a plasma-workspace update:  ./install.sh --only kde
"""
import gzip
import json
import os
import re
import shutil
import sys

BREEZE = "/usr/share/plasma/desktoptheme/default/widgets/tasks.svgz"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "desktoptheme", "NeonGrid")

SEGMENTS = ("center", "top", "bottom", "left", "right",
            "topleft", "topright", "bottomleft", "bottomright")

# The indicator sits on the edge nearest the screen edge, so it depends on where
# the panel is. Prefix "" is the fallback set, which is what a BOTTOM panel gets:
# taskPrefix() returns ["south-<state>", "<state>"] and Breeze ships no `south-`
# elements, so the unprefixed frame is what a bottom dock actually renders.
# Everything not listed for a prefix is slab and gets zeroed.
EDGE = {
    "":       ("bottom", "bottomleft", "bottomright"),  # bottom panel
    "north-": ("top", "topleft", "topright"),           # top panel
    "west-":  ("left", "topleft", "bottomleft"),        # left panel
    "east-":  ("right", "topright", "bottomright"),     # right panel
}

# state -> (line opacity, line colour class or None to keep Breeze's)
# `normal` is a running, non-active task: Breeze paints it grey Text at .33,
# which reads as dirt next to the neon. Point it at the accent instead.
STATES = {
    "normal":    (".55", "ColorScheme-ButtonFocus"),
    "focus":     ("1.0", "ColorScheme-ButtonFocus"),
    "hover":     ("1.0", None),   # keep DecorationHover — magenta is the
                                  # palette's designated hover accent
    "minimized": (".28", "ColorScheme-ButtonFocus"),
    "attention": (".95", None),   # NeutralText — must stay loud
    "progress":  (".70", None),
}


def group_span(src, start):
    """Return the end index of the <g> element that opens at `start`."""
    i = src.index(">", start) + 1
    depth = 1
    for m in re.finditer(r"<(/?)g\b", src[i:]):
        depth += -1 if m.group(1) else 1
        if depth == 0:
            return i + m.end()
    raise ValueError("unbalanced <g>")


def set_attr(tag, name, value):
    if re.search(rf'\b{name}="', tag):
        return re.sub(rf'\b{name}="[^"]*"', f'{name}="{value}"', tag, count=1)
    return tag[:-1].rstrip() + f' {name}="{value}">'


def main():
    if not os.path.exists(BREEZE):
        sys.exit(f"ERROR: {BREEZE} not found — is plasma-workspace installed?")

    with gzip.open(BREEZE, "rt", encoding="utf-8") as fh:
        src = fh.read()

    edits = 0
    for prefix, line_segs in EDGE.items():
        for state, (line_op, line_cls) in STATES.items():
            for seg in SEGMENTS:
                gid = f"{prefix}{state}-{seg}"
                m = re.search(rf'<g id="{re.escape(gid)}"', src)
                if not m:
                    continue
                end = group_span(src, m.start())
                open_end = src.index(">", m.start()) + 1
                tag = src[m.start():open_end]
                body = src[open_end:end]

                if seg not in line_segs:
                    # Hide the brick outright. Zeroing the GROUP opacity is
                    # enough — every child inherits it.
                    tag = set_attr(tag, "opacity", "0")
                else:
                    tag = set_attr(tag, "opacity", line_op)
                    if line_cls:
                        tag = set_attr(tag, "class", line_cls)
                        # children carry their own class= and would otherwise win
                        body = re.sub(r'class="ColorScheme-[A-Za-z]+"',
                                      f'class="{line_cls}"', body)

                src = src[:m.start()] + tag + body + src[end:]
                edits += 1

    # A silent no-op here would ship a stock Breeze file and look like the fix
    # simply did not work, so fail loudly if the ids ever move.
    expected = len(EDGE) * len(STATES) * len(SEGMENTS)
    if edits < expected * 0.8:
        sys.exit(f"ERROR: only patched {edits}/{expected} frame segments — "
                 "Breeze's tasks.svg ids changed; update EDGE/SEGMENTS/STATES.")

    shutil.rmtree(OUT, ignore_errors=True)
    os.makedirs(os.path.join(OUT, "widgets"), exist_ok=True)
    with open(os.path.join(OUT, "widgets", "tasks.svg"), "w", encoding="utf-8") as fh:
        fh.write(src)

    # Everything not present here falls back to Breeze automatically.
    meta = {
        "KPlugin": {
            "Id": "NeonGrid",
            "Name": "NeonGrid",
            "Description": "Cyberpunk Plasma style — Breeze with flat dock task indicators",
            "Authors": [{"Name": "cromewar"}],
            "License": "LGPL",
            "Version": "1.0",
            "Website": "https://github.com/cromewar/neongrid",
        },
        "X-Plasma-API": "5.0",
    }
    with open(os.path.join(OUT, "metadata.json"), "w", encoding="utf-8") as fh:
        json.dump(meta, fh, indent=4)
        fh.write("\n")

    print(f"  built Plasma style: {OUT} ({edits} frame segments retuned)")


if __name__ == "__main__":
    main()

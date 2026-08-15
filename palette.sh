#!/usr/bin/env bash
# NEONGRID palette — the single source of truth.
# Every generator in this repo sources this file. Change a hex here, re-run
# ./install.sh, and it propagates to KDE, GTK, Ghostty, btop, fzf, starship, Limine.

# --- base ---------------------------------------------------------------
# Never pure #000000: palette0 must stay distinguishable from the background,
# or TUIs that paint block backgrounds (btop, fzf) lose their edges.
BG="0a0e0f"          # near-black, faint cyan cast
SURFACE="131a1c"     # panels, cards, ANSI black
SURFACE_HI="1b2427"  # hover / raised
FG="c6d0cb"          # neutral grey-green. Deliberately NOT green.
FG_DIM="7d8a86"

# --- the neons ----------------------------------------------------------
GREEN="3be05c"       # bulk ANSI green: diff-adds, strings, success (~11:1 on BG)
GREEN_HERO="39ff14"  # accents only: cursor, prompt, focus rings, borders, glow
VIOLET="9d6bff"      # ANSI blue slot (cyberpunk swap)
VIOLET_BR="bc8cff"
MAGENTA="d96bff"     # secondary accent, hover
MAGENTA_BR="e89aff"
RED="ff3c6a"         # neon rose
RED_BR="ff6b93"
YELLOW="f5d742"
YELLOW_BR="ffe96b"
CYAN="38e8d0"
CYAN_BR="6bfff0"
WHITE="b8c4c0"
WHITE_BR="e6f2ee"
BLACK_BR="3a4a46"

# --- semantic -----------------------------------------------------------
ACCENT="$GREEN_HERO"     # KDE accent, focus outline
ACCENT_ALT="$MAGENTA"    # hover
SEL_BG="2a1b4d"          # deep violet — selected text must stay readable
SEL_FG="e8e3ff"
CURSOR="$GREEN_HERO"
CURSOR_TEXT="001a00"
CURSOR_OUTLINE="7b2ff7"  # violet outline for the Bibata build

# --- light mode ---------------------------------------------------------
# Call neongrid_light() BEFORE using any of the names above and every generator
# downstream emits the light variant instead — same roles, same code paths.
#
# This is not the dark palette inverted. Two things do not survive a flip:
#
#  1. Neon green cannot be both vivid and readable on white. #39ff14 sits at
#     1.3:1 on a light background — invisible. So the light neons are darkened
#     until they clear WCAG, and saturation is kept as high as possible at that
#     luminance so they still read as neon rather than as muddy corporate green.
#  2. SURFACE_HI is "hover / raised", which means LIGHTER than the surface on a
#     dark theme and DARKER on a light one. Flipping the hex would invert the
#     depth cue and make raised elements look recessed.
#
# Measured against BG (contrast is lower against SURFACE; both clear their bar):
#   FG 15.2:1 · GREEN 7.3:1 (bulk, mirrors dark's 11:1 role) · GREEN_HERO 5.2:1
#   at 94% saturation · VIOLET 6.8:1 · MAGENTA 6.0:1 · RED 5.3:1 · CYAN 5.1:1
neongrid_light() {
  BG="f7faf8"          # near-white, faint cyan-green cast. Never pure #ffffff.
  SURFACE="e8eeeb"     # panels, cards
  SURFACE_HI="dae3df"  # hover / raised — darker here, see note 2 above
  FG="1a2422"          # dark grey-green. Deliberately NOT green.
  FG_DIM="5a6764"

  GREEN="0a6128"       # bulk: body text, diff-adds, success
  GREEN_HERO="047a2e"  # accent: focus rings, borders. Lighter = more vivid.
  VIOLET="6d28d9"
  VIOLET_BR="5b21b6"   # "bright" means darker on light
  MAGENTA="a21caf"
  MAGENTA_BR="86198f"
  RED="c81e4a"
  RED_BR="a1123a"
  YELLOW="8a6100"      # amber — pure yellow is unreadable on white
  YELLOW_BR="6d4c00"
  CYAN="0d7490"
  CYAN_BR="0a5c73"
  WHITE="3f4a47"       # the light/dark ANSI slots swap roles wholesale
  WHITE_BR="1a2422"
  BLACK_BR="c8d2ce"

  ACCENT="$GREEN_HERO"
  ACCENT_ALT="$MAGENTA"
  SEL_BG="d9c9ff"      # light violet; SEL_FG rides it at 11.1:1
  SEL_FG="241243"
  CURSOR="$GREEN_HERO"
  CURSOR_TEXT="ffffff"
}

# --- helpers ------------------------------------------------------------
# KDE .colors files want "R,G,B" decimal triplets.
rgb() { printf '%d,%d,%d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
# '#rrggbb' for the many consumers that want a hash.
hx()  { printf '#%s' "$1"; }

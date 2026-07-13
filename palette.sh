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

# --- helpers ------------------------------------------------------------
# KDE .colors files want "R,G,B" decimal triplets.
rgb() { printf '%d,%d,%d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
# '#rrggbb' for the many consumers that want a hash.
hx()  { printf '#%s' "$1"; }

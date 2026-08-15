#!/usr/bin/env bash
# Klassy window decoration: thin neon outline + neon glow shadow + translucent
# blurred titlebars. Key names/enums were read from Klassy's own kcfg schema
# (libbreezecommon/breezesettingsdata.kcfg), not guessed.
# Config lives at ~/.config/klassy/klassyrc.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

# Klassy caches its config until KWin restarts, so anything pinned here cannot
# follow a live dark/light switch. Take the mode from the active colour scheme
# rather than a flag, so a plain re-run always lands on the right values.
case "${1:-}${NEONGRID_MODE:-}$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null)" in
  *light|*Light) neongrid_light ;;
esac

kk() { kwriteconfig6 --file klassy/klassyrc "$@"; }

# --- the neon outline ---------------------------------------------------
# Follow the SYSTEM ACCENT rather than a pinned custom colour. Klassy derives
# the accent from the decoration palette at paint time, so the outline tracks a
# dark/light switch live — a pinned #39ff14 stayed neon on a light window and
# was the "weird border" it produced. Our schemes set accent per variant
# (#39ff14 dark, #047a2e light), so this stays on-palette either way.
kk --group WindowOutlineStyle --key LockWindowOutlineStyleActiveInactive --type bool false
kk --group WindowOutlineStyle --key LockWindowOutlineCustomColorActiveInactive --type bool false
kk --group WindowOutlineStyle --key WindowOutlineStyleActive   WindowOutlineAccentColor
kk --group WindowOutlineStyle --key WindowOutlineStyleInactive WindowOutlineAccentColor
kk --group WindowOutlineStyle --key WindowOutlineAccentColorOpacityActive   100
kk --group WindowOutlineStyle --key WindowOutlineAccentColorOpacityInactive 40
kk --group WindowOutlineStyle --key WindowOutlineThickness 2.0
kk --group WindowOutlineStyle --key WindowOutlineSnapToWholePixel --type bool true

# --- the glow -----------------------------------------------------------
# There is no maintained KWin "neon outline" effect, so the glow IS the
# decoration shadow: a large, saturated green bloom around every window. BOTH
# variants get it — it is the signature of the theme, not a dark-mode trick.
#
# It does have to be re-tuned rather than reused, because a shadow is composited
# DOWNWARD: on near-black, hero green at full strength reads as light spilling
# off the window, while the same values on paper read as a heavy dirty ring. The
# light variant therefore uses its own accent green — darker, still 94%
# saturated — at reduced strength, which lands as a green halo rather than as
# either glare or grey.
kk --group ShadowStyle --key ShadowSize ShadowVeryLarge
if [ "$BG" = "f7faf8" ]; then     # light palette is loaded
  kk --group ShadowStyle --key ShadowColor "$(rgb "$GREEN_HERO")"
  kk --group ShadowStyle --key ShadowStrength 190
else
  kk --group ShadowStyle --key ShadowColor "$(rgb "$GREEN_HERO")"
  kk --group ShadowStyle --key ShadowStrength 255
fi

# --- translucent, blurred titlebars -------------------------------------
kk --group TitleBarOpacity --key ActiveTitleBarOpacity 88
kk --group TitleBarOpacity --key InactiveTitleBarOpacity 72
kk --group TitleBarOpacity --key BlurTransparentTitleBars --type bool true
kk --group TitleBarOpacity --key ApplyOpacityToHeader --type bool true
kk --group TitleBarOpacity --key OpaqueMaximizedTitleBars --type bool false
kk --group TitleBarOpacity --key OverrideActiveTitleBarOpacity --type bool true
kk --group TitleBarOpacity --key OverrideInactiveTitleBarOpacity --type bool true

# --- shape --------------------------------------------------------------
kk --group Windeco --key WindowCornerRadius 10
kk --group Windeco --key RoundAllCornersWhenNoBorders --type bool true

echo "Klassy applied."

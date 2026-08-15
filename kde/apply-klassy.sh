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
# decoration shadow: tint it green, max strength, largest size. On a light
# desktop a full-strength hero-green bloom around every window is glare, so the
# light variant uses the bulk green and pulls the strength back.
if [ "$BG" = "f7faf8" ]; then     # light palette is loaded
  kk --group ShadowStyle --key ShadowColor "$(rgb "$GREEN")"
  kk --group ShadowStyle --key ShadowStrength 120
  kk --group ShadowStyle --key ShadowSize ShadowLarge
else
  kk --group ShadowStyle --key ShadowColor "$(rgb "$GREEN_HERO")"
  kk --group ShadowStyle --key ShadowStrength 255
  kk --group ShadowStyle --key ShadowSize ShadowVeryLarge
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

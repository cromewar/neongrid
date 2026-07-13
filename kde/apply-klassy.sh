#!/usr/bin/env bash
# Klassy window decoration: thin neon outline + neon glow shadow + translucent
# blurred titlebars. Key names/enums were read from Klassy's own kcfg schema
# (libbreezecommon/breezesettingsdata.kcfg), not guessed.
# Config lives at ~/.config/klassy/klassyrc.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

kk() { kwriteconfig6 --file klassy/klassyrc "$@"; }

# --- the neon outline ---------------------------------------------------
# Active windows get a hero-green custom outline; inactive ones a dim violet,
# so focus is obvious at a glance across a tiled workspace.
kk --group WindowOutlineStyle --key LockWindowOutlineStyleActiveInactive --type bool false
kk --group WindowOutlineStyle --key LockWindowOutlineCustomColorActiveInactive --type bool false
kk --group WindowOutlineStyle --key WindowOutlineStyleActive   WindowOutlineCustomColor
kk --group WindowOutlineStyle --key WindowOutlineStyleInactive WindowOutlineCustomColor
kk --group WindowOutlineStyle --key WindowOutlineCustomColorActive   "$(rgb "$GREEN_HERO")"
kk --group WindowOutlineStyle --key WindowOutlineCustomColorInactive "$(rgb "$VIOLET")"
kk --group WindowOutlineStyle --key WindowOutlineCustomColorOpacityActive   100
kk --group WindowOutlineStyle --key WindowOutlineCustomColorOpacityInactive 45
kk --group WindowOutlineStyle --key WindowOutlineThickness 2.0
kk --group WindowOutlineStyle --key WindowOutlineSnapToWholePixel --type bool true

# --- the glow -----------------------------------------------------------
# There is no maintained KWin "neon outline" effect, so the glow IS the
# decoration shadow: tint it hero-green, max strength, largest size.
kk --group ShadowStyle --key ShadowColor "$(rgb "$GREEN_HERO")"
kk --group ShadowStyle --key ShadowStrength 255
kk --group ShadowStyle --key ShadowSize ShadowVeryLarge

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

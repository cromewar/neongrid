#!/usr/bin/env bash
# Blur, glow and transparency. User-level.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

kw() { kwriteconfig6 "$@"; }

# --- blur ---------------------------------------------------------------
# Better Blur DX REPLACES the stock blur effect — running both fights over the
# same surfaces. Stock off, Better Blur on.
kw --file kwinrc --group Plugins --key blurEnabled --type bool false
kw --file kwinrc --group Plugins --key better_blur_dxEnabled --type bool true

# Background Contrast lightens whatever sits behind a translucent window. On a
# near-black neon base that washes the whole look out. Off; we tune contrast
# inside Better Blur instead, where it's per-effect and far finer.
kw --file kwinrc --group Plugins --key contrastEnabled --type bool false

# Force-blur by window class. This is the entire reason Better Blur exists:
# these apps never *request* blur, so stock KWin would never blur them.
# Ghostty is the headline case — KDE 6.7 dropped the old blur protocol that
# Ghostty 1.3.1 speaks, so its own background-blur is a no-op. This fixes it,
# and fixes every GTK/Electron app at the same time.
FORCE_CLASSES="com.mitchellh.ghostty,ghostty,org.kde.dolphin,org.kde.konsole,brave-browser,firefox,obsidian,code,org.kde.systemsettings,org.kde.kate,org.kde.plasma-systemmonitor,vlc,mpv"
kw --file kwinrc --group Effect-better_blur_dx --key windowClasses "$FORCE_CLASSES"
kw --file kwinrc --group Effect-better_blur_dx --key windowClassMatchingMode 0
kw --file kwinrc --group Effect-better_blur_dx --key blurMatching --type bool true
kw --file kwinrc --group Effect-better_blur_dx --key blurDecorations --type bool true
kw --file kwinrc --group Effect-better_blur_dx --key paintAsTranslucent --type bool true

# Strength + the dark-glass look. Brightness slightly <1 and saturation >1 keeps
# the base near-black while letting neon behind the glass bloom through.
kw --file kwinrc --group Effect-better_blur_dx --key blurStrength 12
kw --file kwinrc --group Effect-better_blur_dx --key noiseStrength 4
kw --file kwinrc --group Effect-better_blur_dx --key brightness 0.85
kw --file kwinrc --group Effect-better_blur_dx --key saturation 1.25
kw --file kwinrc --group Effect-better_blur_dx --key contrast 1.05

# Rounded corners + refraction — the glass edge reads as a faint glowing rim.
kw --file kwinrc --group Effect-better_blur_dx --key roundedCorners --type bool true
kw --file kwinrc --group Effect-better_blur_dx --key topCornerRadius 12
kw --file kwinrc --group Effect-better_blur_dx --key bottomCornerRadius 12
kw --file kwinrc --group Effect-better_blur_dx --key antialiasing 1.0
kw --file kwinrc --group Effect-better_blur_dx --key refractionStrength 0.06
kw --file kwinrc --group Effect-better_blur_dx --key refractionEdgeSize 12

# --- supporting effects -------------------------------------------------
kw --file kwinrc --group Plugins --key kwin4_effect_translucencyEnabled --type bool true
kw --file kwinrc --group Plugins --key kwin4_effect_dimscreenEnabled --type bool true
# Wobbly/magic-lamp are off: they read as playful, not cyberpunk.
kw --file kwinrc --group Plugins --key wobblywindowsEnabled --type bool false

echo "Effects applied."

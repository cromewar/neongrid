#!/usr/bin/env bash
# Blur, glow and transparency. User-level.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

kw() { kwriteconfig6 "$@"; }

# --- blur ---------------------------------------------------------------
# Better Blur DX REPLACES the stock blur effect — running both fights over the
# same surfaces. Stock off, Better Blur on.
#
# ⚠ THE TRAP: the [Plugins] enable key uses the PLUGIN ID, which has UNDERSCORES
#    (better_blur_dxEnabled), but the effect's own config group has HYPHENS
#    ([Effect-better-blur-dx], per src/blur.kcfg). Get the group wrong and every
#    setting below is silently ignored — you still get blur, because Better Blur
#    blurs translucent windows by default, so it LOOKS like it worked while
#    force-blur, rounded corners and refraction are all inert.
# ⚠ Keys are CamelCase, and Brightness/Saturation/Contrast are INTEGER PERCENTS
#    (100 = neutral), not 0..1 floats.
kw --file kwinrc --group Plugins --key blurEnabled --type bool false
kw --file kwinrc --group Plugins --key better_blur_dxEnabled --type bool true

# Background Contrast lightens whatever sits behind a translucent window. On a
# near-black neon base that washes the whole look out. Off; we tune contrast
# inside Better Blur instead.
kw --file kwinrc --group Plugins --key contrastEnabled --type bool false

G=Effect-better-blur-dx

# Force-blur by window class. This is the entire reason Better Blur exists:
# these apps never *request* blur, so stock KWin would never blur them.
# Ghostty is the headline case — KDE 6.7 dropped the old blur protocol that
# Ghostty 1.3.1 speaks, so its own background-blur is a no-op. This fixes it,
# and fixes every GTK/Electron app at the same time.
FORCE_CLASSES="com.mitchellh.ghostty,ghostty,org.kde.dolphin,org.kde.konsole,brave-browser,firefox,obsidian,code,org.kde.systemsettings,org.kde.kate,org.kde.plasma-systemmonitor,vlc,mpv"
kw --file kwinrc --group "$G" --key WindowClasses "$FORCE_CLASSES"
kw --file kwinrc --group "$G" --key BlurMatching --type bool true
kw --file kwinrc --group "$G" --key BlurNonMatching --type bool false
kw --file kwinrc --group "$G" --key BlurDecorations --type bool true
kw --file kwinrc --group "$G" --key BlurMenus --type bool true
kw --file kwinrc --group "$G" --key BlurDocks --type bool true

# Strength + the dark-glass look. Brightness slightly under 100 and saturation
# over 100 keeps the base near-black while letting neon behind the glass bloom.
kw --file kwinrc --group "$G" --key BlurStrength 12
kw --file kwinrc --group "$G" --key NoiseStrength 4
kw --file kwinrc --group "$G" --key Brightness 90
kw --file kwinrc --group "$G" --key Saturation 140
kw --file kwinrc --group "$G" --key Contrast 105

# Rounded corners + refraction — the glass edge reads as a faint glowing rim.
kw --file kwinrc --group "$G" --key CornerRadius 12
kw --file kwinrc --group "$G" --key RefractionStrength 8
kw --file kwinrc --group "$G" --key RefractionEdgeSize 20

# --- supporting effects -------------------------------------------------
kw --file kwinrc --group Plugins --key kwin4_effect_translucencyEnabled --type bool true
kw --file kwinrc --group Plugins --key kwin4_effect_dimscreenEnabled --type bool true
# Wobbly/magic-lamp are off: they read as playful, not cyberpunk.
kw --file kwinrc --group Plugins --key wobblywindowsEnabled --type bool false

echo "Effects applied."

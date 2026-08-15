#!/usr/bin/env bash
# Applies the NeonGrid KDE core: color scheme, app style, decoration, icons,
# fonts, effects. Entirely user-level — no root needed.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

kw() { kwriteconfig6 "$@"; }

# --- color scheme -------------------------------------------------------
mkdir -p ~/.local/share/color-schemes
bash "$HERE/gen-colors.sh" "$HERE/NeonGrid.colors" >/dev/null
cp -f "$HERE/NeonGrid.colors" ~/.local/share/color-schemes/NeonGrid.colors
plasma-apply-colorscheme NeonGrid >/dev/null 2>&1 || true

# Accent. Critical: accentColorFromWallpaper MUST be false, or the animated
# shader wallpaper overwrites the neon green on every wallpaper change.
kw --file kdeglobals --group General --key AccentColor "$(rgb "$ACCENT")"
kw --file kdeglobals --group General --key LastUsedCustomAccentColor "$(rgb "$ACCENT")"
kw --file kdeglobals --group General --key accentColorFromWallpaper --type bool false

# --- application style --------------------------------------------------
# Darkly follows the KDE color scheme, so the accent reaches every Qt app
# (including QML/Kirigami, which Kvantum cannot theme) with no SVG editing.
kw --file kdeglobals --group KDE --key widgetStyle Darkly

# --- window decoration --------------------------------------------------
# Group name differs across KDecoration 2/3; set both, the live one wins.
for grp in org.kde.kdecoration2 org.kde.kdecoration3; do
  kw --file kwinrc --group "$grp" --key library org.kde.klassy
  kw --file kwinrc --group "$grp" --key theme Klassy
  kw --file kwinrc --group "$grp" --key BorderSize None
  kw --file kwinrc --group "$grp" --key BorderSizeAuto --type bool false
done

# --- icons + cursor -----------------------------------------------------
# NeonGrid is BeautyLine hue-snapped + the brand-mark overlay from
# icons/gen-icons.sh. Do NOT set BeautyLine here — install.sh --only kde
# would otherwise undo the overlay theme.
kw --file kdeglobals --group Icons --key Theme NeonGrid

# --- fonts --------------------------------------------------------------
# Rajdhani: condensed, technical, and — unlike Orbitron — actually legible at
# UI sizes. Orbitron is reserved for headings/banners only.
UI_FONT="Rajdhani,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
MONO_FONT="JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw --file kdeglobals --group General --key font        "$UI_FONT"
kw --file kdeglobals --group General --key menuFont    "$UI_FONT"
kw --file kdeglobals --group General --key toolBarFont "$UI_FONT"
kw --file kdeglobals --group General --key smallestReadableFont "Rajdhani,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw --file kdeglobals --group General --key fixed       "$MONO_FONT"
kw --file kwinrc     --group WM      --key titleFont   "Rajdhani,11,-1,5,600,0,0,0,0,0,0,0,0,0,0,1"

echo "KDE core applied."

#!/usr/bin/env bash
# NeonGrid lock screen: the same live GLSL tile as the desktop, plus the
# NeonGrid look-and-feel package so the locker is not the CachyOS image + Nord UI.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
FRAG="$REPO/wallpapers/neongrid.frag"
PKG="$REPO/look-and-feel/com.cromewar.neongrid"
PLUGIN="online.knowmad.shaderwallpaper"
LNF="com.cromewar.neongrid"

[ -f "$FRAG" ] || { echo "  !! missing $FRAG" >&2; exit 1; }
[ -d "$PKG" ] || { echo "  !! missing $PKG" >&2; exit 1; }

install_lnf() {
  local dest="$HOME/.local/share/plasma/look-and-feel/$LNF"
  # kpackagetool6 --show <unknown-id> exits 0 and prints some other package,
  # so we key off the destination directory, not --show.
  mkdir -p "$(dirname "$dest")"
  if command -v kpackagetool6 >/dev/null 2>&1; then
    if [ -d "$dest" ]; then
      kpackagetool6 --type Plasma/LookAndFeel --upgrade "$PKG" >/dev/null \
        || { rm -rf "$dest"; kpackagetool6 --type Plasma/LookAndFeel --install "$PKG" >/dev/null; }
    else
      kpackagetool6 --type Plasma/LookAndFeel --install "$PKG" >/dev/null \
        || { cp -a "$PKG" "$dest"; }
    fi
  else
    rm -rf "$dest"
    cp -a "$PKG" "$dest"
  fi
}

kw() { kwriteconfig6 --file kscreenlockerrc "$@"; }

install_lnf

# Theme = our L&F package. Wallpaper plugin is independent of Theme and is
# what actually replaces the CachyOS still image.
kw --group Greeter --key Theme "$LNF"
kw --group Greeter --key WallpaperPluginId "$PLUGIN"
kw --group Greeter --key WallpaperPlugin "$PLUGIN"

# Same shader + caps as the desktop, except pauseMode=3: there are no
# "maximized windows" on the locker, but some pause checks still fire and
# freeze the tile. Never-pause keeps it moving.
G=(--group Greeter --group Wallpaper --group "$PLUGIN" --group General)
kw "${G[@]}" --key selectedShaderPath "$FRAG"
kw "${G[@]}" --key running --type bool true
kw "${G[@]}" --key targetFps 30
kw "${G[@]}" --key resolutionScale 0.75
kw "${G[@]}" --key pauseMode 3
kw "${G[@]}" --key shaderSpeed 0.6
kw "${G[@]}" --key audioEnabled --type bool false
kw "${G[@]}" --key mouseEnabled --type bool false

echo "  lock screen -> $PLUGIN ($FRAG)"
echo "  locker theme -> $LNF"

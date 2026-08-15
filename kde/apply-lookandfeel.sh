#!/usr/bin/env bash
# Installs both NeonGrid colour schemes and both Global Themes.
#
# The point of this script is damage control, not appearance: before it, the
# Global Theme page in System Settings offered only Breeze entries, so clicking
# one — or flipping dark/light — reset widget style, colours, icons, Plasma
# style and cursor back to Breeze and the desktop had to be repaired from a
# shell. With NeonGrid and NeonGrid Light registered as real Global Themes,
# that click applies NeonGrid instead of destroying it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

SCHEMES="$HOME/.local/share/color-schemes"
LNF_DIR="$HOME/.local/share/plasma/look-and-feel"

# --- colour schemes -----------------------------------------------------
bash "$HERE/gen-colors.sh"         "$HERE/NeonGrid.colors"      >/dev/null
bash "$HERE/gen-colors.sh" --light "$HERE/NeonGridLight.colors" >/dev/null
mkdir -p "$SCHEMES"
cp -f "$HERE/NeonGrid.colors"      "$SCHEMES/NeonGrid.colors"
cp -f "$HERE/NeonGridLight.colors" "$SCHEMES/NeonGridLight.colors"

# --- global themes ------------------------------------------------------
bash "$HERE/gen-lookandfeel.sh"

install_lnf() {
  local src="$1" id="$2" dest="$LNF_DIR/$2"
  mkdir -p "$LNF_DIR"
  # kpackagetool6 --show <unknown-id> exits 0 and prints some other package, so
  # key off the destination directory rather than trusting a lookup.
  if command -v kpackagetool6 >/dev/null 2>&1; then
    if [ -d "$dest" ]; then
      kpackagetool6 --type Plasma/LookAndFeel --upgrade "$src" >/dev/null 2>&1 \
        || { rm -rf "$dest"; cp -a "$src" "$dest"; }
    else
      kpackagetool6 --type Plasma/LookAndFeel --install "$src" >/dev/null 2>&1 \
        || cp -a "$src" "$dest"
    fi
  else
    rm -rf "$dest"; cp -a "$src" "$dest"
  fi
  [ -d "$dest" ] || { echo "  !! failed to install $id" >&2; return 1; }
}

install_lnf "$REPO/look-and-feel/com.cromewar.neongrid"       com.cromewar.neongrid
install_lnf "$REPO/look-and-feel/com.cromewar.neongrid.light" com.cromewar.neongrid.light

echo "  colour schemes -> NeonGrid, NeonGrid Light"
echo "  global themes  -> $(ls "$LNF_DIR" | tr '\n' ' ')"

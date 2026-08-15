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

# --- retire the pre-rename identifiers ----------------------------------
# The dark variant used to be the bare id `com.cromewar.neongrid` / scheme
# `NeonGrid`. That read as the family name rather than as a variant, so the
# Global Theme grid showed "NeonGrid" next to "NeonGrid Light" with nothing
# saying which was dark. Both halves are now explicit. Delete the old ids or
# they linger in the KCM as a stale duplicate that still resolves.
rm -rf "$LNF_DIR/com.cromewar.neongrid"
rm -f  "$SCHEMES/NeonGrid.colors"

# --- colour schemes -----------------------------------------------------
bash "$HERE/gen-colors.sh"         "$HERE/NeonGridDark.colors"  >/dev/null
bash "$HERE/gen-colors.sh" --light "$HERE/NeonGridLight.colors" >/dev/null
mkdir -p "$SCHEMES"
cp -f "$HERE/NeonGridDark.colors"  "$SCHEMES/NeonGridDark.colors"
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

install_lnf "$REPO/look-and-feel/com.cromewar.neongrid.dark"  com.cromewar.neongrid.dark
install_lnf "$REPO/look-and-feel/com.cromewar.neongrid.light" com.cromewar.neongrid.light

# --- the light/dark PAIR ------------------------------------------------
# Registering the themes is not enough on its own. The "Dark Mode" switch in
# the Brightness & Color applet — and the automatic time-of-day/idle switch —
# never consult the Global Theme list. They flip LookAndFeelPackage between
# this configured pair, defined in /usr/share/config.kcfg/lookandfeelsettings.kcfg:
#
#   [KDE] DefaultLightLookAndFeel   default org.kde.breeze.desktop
#   [KDE] DefaultDarkLookAndFeel    default org.kde.breezedark.desktop
#
# Leave them unset and that toggle hard-reverts the desktop to Breeze no matter
# what is installed or currently applied. Point the pair at NeonGrid so the
# toggle switches between our own two variants instead.
kwriteconfig6 --file kdeglobals --group KDE \
  --key DefaultLightLookAndFeel com.cromewar.neongrid.light
kwriteconfig6 --file kdeglobals --group KDE \
  --key DefaultDarkLookAndFeel com.cromewar.neongrid.dark
kwriteconfig6 --file kdeglobals --group KDE \
  --key LookAndFeelPackage com.cromewar.neongrid.dark

# --- splash -------------------------------------------------------------
# contents/defaults carries this too, so a Global Theme switch moves the splash
# with it. Set it here as well for the plain `--only kde` path, which writes the
# individual keys without going through the look-and-feel machinery.
kwriteconfig6 --file ksplashrc --group KSplash --key Theme  com.cromewar.neongrid.dark
kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML

echo "  colour schemes -> NeonGrid Dark, NeonGrid Light"
echo "  global themes  -> $(ls "$LNF_DIR" | tr '\n' ' ')"

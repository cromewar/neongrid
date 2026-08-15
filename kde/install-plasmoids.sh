#!/usr/bin/env bash
# Installs the two extra panel widgets the reference desktop uses.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

install_one() {
  local id="$1" src="$REPO/plasmoids/$1"
  [ -d "$src" ] || { echo "  !! missing $src" >&2; return 1; }
  if ! command -v kpackagetool6 >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/share/plasma/plasmoids"
    rm -rf "$HOME/.local/share/plasma/plasmoids/$id"
    cp -a "$src" "$HOME/.local/share/plasma/plasmoids/$id"
    echo "  $id (copied; kpackagetool6 not found)"
    return 0
  fi
  if kpackagetool6 --type Plasma/Applet --show "$id" >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --upgrade "$src" >/dev/null
    echo "  $id upgraded"
  else
    kpackagetool6 --type Plasma/Applet --install "$src" >/dev/null
    echo "  $id installed"
  fi
}

install_one com.cromewar.downloadsstack
install_one org.kde.plasma.pomodoro

notify_src="$REPO/plasmoids/org.kde.plasma.pomodoro/notifications/org.kde.plasma.pomodoro.notifyrc"
if [ -f "$notify_src" ]; then
  mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/knotifications6"
  cp -f "$notify_src" "${XDG_DATA_HOME:-$HOME/.local/share}/knotifications6/org.kde.plasma.pomodoro.notifyrc"
fi

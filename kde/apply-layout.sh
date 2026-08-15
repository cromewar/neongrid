#!/usr/bin/env bash
# Applies the reference-machine panel layout: floating bottom dock + slim
# top bar, pinned launchers (only apps that exist here), clock font, and
# the two extra plasmoids if they are installed.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

desktop_exists() {
  local name="$1"
  [ -f "/usr/share/applications/$name" ] && return 0
  [ -f "$HOME/.local/share/applications/$name" ] && return 0
  [ -f "/var/lib/flatpak/exports/share/applications/$name" ] && return 0
  return 1
}

# Order is the reference dock, left to right. Missing apps are skipped so
# a machine without Linear still gets a coherent dock, just shorter.
CANDIDATES=(
  preferred://filemanager
  applications:firefox.desktop
  applications:brave-browser.desktop
  applications:google-chrome.desktop
  applications:com.mitchellh.ghostty.desktop
  applications:chatgpt.desktop
  applications:com.anthropic.Claude.desktop
  applications:t3code.desktop
  applications:visual-studio-code-electron.desktop
  applications:cursor.desktop
  applications:ticktick.desktop
  applications:obsidian.desktop
  applications:Linear.desktop
  applications:io.github.brunofin.Cohesion.desktop
  applications:cider.desktop
  applications:slack.desktop
  applications:proton-mail.desktop
  applications:notion-calendar.desktop
)

launchers=()
for item in "${CANDIDATES[@]}"; do
  if [ "$item" = "preferred://filemanager" ]; then
    launchers+=("$item")
    continue
  fi
  desktop_exists "${item#applications:}" && launchers+=("$item")
done
IFS=','; LAUNCHERS="${launchers[*]}"; unset IFS

HAS_POMODORO=0
HAS_DOWNLOADS=0
[ -d "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.pomodoro" ] && HAS_POMODORO=1
[ -d "$HOME/.local/share/plasma/plasmoids/com.cromewar.downloadsstack" ] && HAS_DOWNLOADS=1
[ -d /usr/share/plasma/plasmoids/org.kde.plasma.pomodoro ] && HAS_POMODORO=1
[ -d /usr/share/plasma/plasmoids/com.cromewar.downloadsstack ] && HAS_DOWNLOADS=1

# Notion Calendar's shipped desktop file asks for notion-calendar.png, which
# skips the SVG overlay. Point it at the theme name. Same for Affinity's
# hardcoded absolute path, if that launcher exists.
mkdir -p "$HOME/.local/share/applications"
if desktop_exists notion-calendar.desktop; then
  src=""
  for d in /usr/share/applications "$HOME/.local/share/applications"; do
    [ -f "$d/notion-calendar.desktop" ] && src="$d/notion-calendar.desktop" && break
  done
  if [ -n "$src" ]; then
    sed 's|^Icon=.*|Icon=notion-calendar|' "$src" \
      > "$HOME/.local/share/applications/notion-calendar.desktop"
  fi
fi
if [ -f "$HOME/.local/share/applications/Affinity.desktop" ]; then
  sed -i 's|^Icon=.*|Icon=affinity|' "$HOME/.local/share/applications/Affinity.desktop"
fi

js=$(mktemp)
trap 'rm -f "$js"' EXIT
sed \
  -e "s|__LAUNCHERS__|$LAUNCHERS|g" \
  -e "s|__HAS_POMODORO__|$HAS_POMODORO|g" \
  -e "s|__HAS_DOWNLOADS__|$HAS_DOWNLOADS|g" \
  "$HERE/apply-layout.js" > "$js"

if qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$js")" \
     >/dev/null 2>&1; then
  echo "  panel layout applied (${#launchers[@]} dock icons, pomodoro=$HAS_POMODORO, downloads=$HAS_DOWNLOADS)"
else
  echo "  !! plasmashell script failed — is a desktop session running?" >&2
  exit 1
fi

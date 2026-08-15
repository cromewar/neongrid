#!/usr/bin/env bash
# Installs the user units that keep the wallpaper in step with the colour scheme.
# See kde/theme-sync.sh for why this needs a watcher at all.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
DEST="$HOME/.config/systemd/user"

mkdir -p "$DEST"
for u in neongrid-theme-sync.service neongrid-theme-sync.path; do
  install -Dm644 "$REPO/systemd/$u" "$DEST/$u"
done

systemctl --user daemon-reload
systemctl --user enable --now neongrid-theme-sync.path >/dev/null 2>&1 \
  || { echo "  !! could not enable neongrid-theme-sync.path" >&2; exit 1; }

echo "  wallpaper follows the colour scheme ($(systemctl --user is-active neongrid-theme-sync.path))"

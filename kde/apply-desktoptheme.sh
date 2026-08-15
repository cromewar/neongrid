#!/usr/bin/env bash
# Installs and activates the NeonGrid Plasma style.
#
# The style exists for one reason: Breeze's widgets/tasks.svg paints a filled
# slab behind hovered/active dock icons (see gen-desktoptheme.py). Everything
# else falls back to Breeze, so this package stays a single SVG + metadata.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

SRC="$HERE/desktoptheme/NeonGrid"
DEST="$HOME/.local/share/plasma/desktoptheme/NeonGrid"

python3 "$HERE/gen-desktoptheme.py"

rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
cp -r "$SRC" "$DEST"

if command -v plasma-apply-desktoptheme >/dev/null 2>&1; then
  plasma-apply-desktoptheme NeonGrid >/dev/null 2>&1 || true
fi
# plasma-apply-desktoptheme is not always present (it ships with
# plasma-workspace, not plasma-desktop), so write the key directly too.
kwriteconfig6 --file plasmarc --group Theme --key name NeonGrid

echo "  Plasma style -> $(kreadconfig6 --file plasmarc --group Theme --key name)"

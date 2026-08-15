#!/usr/bin/env bash
# Re-points the shader wallpaper and the lock screen at the variant that matches
# the active colour scheme.
#
# Plasma has no hook for this. A Global Theme's contents/defaults can set an
# `[Wallpaper] Image=`, but only for org.kde.image — there is no mechanism to
# carry a wallpaper *plugin's* configuration, and the shader wallpaper keeps its
# frag path in plasma-org.kde.plasma.desktop-appletsrc. So switching dark/light
# left a near-black grid under a light desktop with no way to notice.
#
# Hence the systemd path unit that runs this on every kdeglobals write. That
# fires often, so this exits without touching anything unless the wallpaper is
# genuinely on the wrong variant.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
APPLETSRC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

case "$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null)" in
  *Light) WANT="$REPO/wallpapers/neongrid-light.frag" ;;
  *)      WANT="$REPO/wallpapers/neongrid.frag" ;;
esac

# Already correct (and no stale variant anywhere)? Do nothing — this runs on
# every kdeglobals write, and thrashing the wallpaper would be worse than the
# bug it fixes.
if [ -f "$APPLETSRC" ] \
   && grep -q "selectedShaderPath=$WANT" "$APPLETSRC" \
   && ! grep -q "selectedShaderPath=$REPO/wallpapers/$( [ "${WANT##*/}" = "neongrid.frag" ] \
        && echo neongrid-light.frag || echo neongrid.frag )" "$APPLETSRC"; then
  exit 0
fi

# plasmashell must be up to take the dbus call; on a login race the path unit
# fires again on the next kdeglobals write.
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'print(1)' \
  >/dev/null 2>&1 || exit 0

bash "$HERE/apply-wallpaper.sh"  >/dev/null 2>&1 || true
bash "$HERE/apply-lockscreen.sh" >/dev/null 2>&1 || true

# Klassy's outline follows the accent by itself, but the glow colour is pinned
# in klassyrc, so rewrite it for the new mode. Klassy only re-reads that file
# when KWin starts, so the glow lands on the next login while the outline
# changes immediately — the visible half is the one that keeps up.
bash "$HERE/apply-klassy.sh" >/dev/null 2>&1 || true

# Panel Colorizer colour SOURCES follow the scheme, but the border alpha and
# the shadow geometry are baked into its config, and those are what break on
# light (washed hairline + green halo). Rewrite them for the new mode.
python3 "$HERE/apply-panel.py" >/dev/null 2>&1 || true

echo "neongrid: wallpaper -> ${WANT##*/}"

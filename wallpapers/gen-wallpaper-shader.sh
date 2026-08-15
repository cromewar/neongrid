#!/usr/bin/env bash
# Forks the stock Grid_Landscape shader into the repo and recolors it to the
# NeonGrid palette: hero-green wireframe over a deep violet field.
#
# Two things learned the hard way:
#  - Many bundled shaders (Digital_Rain, Circuits, Sunset_Cyber) declare
#    iChannel0/1/2 textures the plugin never feeds them. They compile fine and
#    render PURE BLACK. Only pick self-contained shaders.
#  - The field is deliberately dark: this sits behind terminals all day.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

# The installed plugin is the preferred source, but on a fresh machine this runs
# BEFORE the root pass has done `make install` — so fall back to the build tree.
# (Sourcing only from /usr made this step unsatisfiable on a first install.)
SRC=""
for c in \
  /usr/share/plasma/wallpapers/online.knowmad.shaderwallpaper/contents/ui/Shaders/Grid_Landscape.frag \
  "$HERE/../.build-shader/package/contents/ui/Shaders/Grid_Landscape.frag"
do
  [ -f "$c" ] && { SRC="$c"; break; }
done
[ -n "$SRC" ] || {
  echo "ERROR: Grid_Landscape.frag not found — is .build-shader/ cloned?" >&2; exit 1; }

OUT="$HERE/neongrid.frag"

# hex -> "r, g, b" GLSL floats
glsl() {
  awk -v r="$((16#${1:0:2}))" -v g="$((16#${1:2:2}))" -v b="$((16#${1:4:2}))" -v s="${2:-1.0}" \
    'BEGIN { printf "%.3f, %.3f, %.3f", r/255*s, g/255*s, b/255*s }'
}

# Grid lines are dimmed to ~45%: at full hero-green this reads as a blinding
# Tron floor and fights every window sitting on top of it. The wallpaper is
# background, not the subject.
LINES="$(glsl "$GREEN" 0.45)"
FIELD="$(glsl "$SEL_BG" 0.30)"

# Write via a temp file: `> "$OUT"` truncates before sed runs, so a failure here
# used to leave neongrid.frag as an empty tracked file and abort the install.
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

sed -E \
  -e "s|^#define GRID_COLOR_1 .*|#define GRID_COLOR_1 vec3($FIELD) // neongrid: deep violet field|" \
  -e "s|^#define GRID_COLOR_2 .*|#define GRID_COLOR_2 vec3($LINES) // neongrid: hero green wireframe|" \
  "$SRC" > "$TMP"

grep -q "neongrid: hero green" "$TMP" || { echo "ERROR: shader defines not patched" >&2; exit 1; }
mv -f "$TMP" "$OUT"
chmod 644 "$OUT"
echo "wrote $OUT (source: $SRC)"
grep -E "^#define GRID_COLOR" "$OUT"

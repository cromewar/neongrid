#!/usr/bin/env bash
# Recolors the upstream cursor_blaze shader to the NeonGrid palette.
# Upstream (0xhckr/ghostty-shaders) hardcodes a yellow trail with a red accent;
# we swap those consts for neon green with a violet accent. The pristine
# upstream file is kept as .glsl.in so it can be re-pulled and re-patched.
set -euo pipefail
source "$(dirname "$0")/../palette.sh"

SRC="$(dirname "$0")/shaders/cursor_blaze.glsl.in"
OUT="$(dirname "$0")/shaders/cursor_blaze.glsl"

# hex -> "r, g, b" as GLSL floats in 0..1  (awk, not bc — bc isn't installed)
glsl_rgb() {
  awk -v r="$((16#${1:0:2}))" -v g="$((16#${1:2:2}))" -v b="$((16#${1:4:2}))" \
    'BEGIN { printf "%.3f, %.3f, %.3f", r/255, g/255, b/255 }'
}

TRAIL="$(glsl_rgb "$GREEN_HERO")"
ACC="$(glsl_rgb "$MAGENTA")"

sed -E \
  -e "s|^const vec4 TRAIL_COLOR = .*|const vec4 TRAIL_COLOR = vec4($TRAIL, 1.0); // neongrid: hero green|" \
  -e "s|^const vec4 TRAIL_COLOR_ACCENT = .*|const vec4 TRAIL_COLOR_ACCENT = vec4($ACC, 1.0); // neongrid: magenta|" \
  "$SRC" > "$OUT"

grep -q "neongrid: hero green" "$OUT" || { echo "ERROR: TRAIL_COLOR not patched — upstream shader changed shape" >&2; exit 1; }
grep -q "neongrid: magenta"    "$OUT" || { echo "ERROR: TRAIL_COLOR_ACCENT not patched" >&2; exit 1; }
echo "wrote $OUT"

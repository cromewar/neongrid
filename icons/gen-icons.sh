#!/usr/bin/env bash
# Builds the NeonGrid icon OVERLAY theme.
#
# The problem: every icon theme keeps each app's brand hue — Brave orange,
# Firefox orange, Claude coral, Obsidian violet. On a dock that reads as a
# rainbow and fights the theme.
#
# The fix is NOT to flatten everything to one color (that looks sterile and
# kills the neon). Each app gets its OWN two-stop gradient, drawn from the
# NeonGrid palette. Variety stays; the palette stays coherent.
#
# Source SVGs: simple-icons / lobe-icons. Every one of these apps ships only a
# PNG, so the upstream vector brand marks are the correct source.
# The theme INHERITS BeautyLine, so icons we don't override still resolve.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

THEME="$HOME/.local/share/icons/NeonGrid"
SI="https://raw.githubusercontent.com/simple-icons/simple-icons/master/icons"
LOBE="https://raw.githubusercontent.com/lobehub/lobe-icons/master/packages/static-svg/icons"

OUT="$THEME/apps/scalable"
mkdir -p "$OUT"

# icon-name (the .desktop Icon= key) | source URL | gradient start | gradient end
# Gradients run along the icon diagonal. Each app is distinct, all are neon.
MAP="
com.mitchellh.ghostty|$SI/ghostty.svg|$GREEN_HERO|$CYAN
openai-codex-desktop|$LOBE/openai.svg|$CYAN_BR|$GREEN
chatgpt|$LOBE/openai.svg|$CYAN_BR|$GREEN
claude-desktop|$SI/claude.svg|$GREEN_HERO|$YELLOW
antigravity-ide|$LOBE/antigravity.svg|$CYAN|$VIOLET
brave-desktop|$SI/brave.svg|$VIOLET|$RED
firefox|$SI/firefoxbrowser.svg|$MAGENTA|$RED_BR
obsidian|$SI/obsidian.svg|$VIOLET|$MAGENTA_BR
ticktick|$SI/ticktick.svg|$GREEN|$CYAN_BR
notion|$SI/notion.svg|$CYAN_BR|$VIOLET
"

# Injects a linearGradient into a flat single-path brand mark.
grad_svg() {
  python3 - "$1" "$2" "#$3" "#$4" <<'PY'
import re, sys
src, dst, c1, c2 = sys.argv[1:5]
s = open(src).read()
s = re.sub(r'\sfill="(?!none)[^"]*"', '', s)   # drop the baked-in brand fill

# ⚠ lobe-icons ship width="1em" height="1em" on the <svg> root. An intrinsic size
#   of 1em resolves to ~16px, so the icon is RASTERIZED AT 16x16 AND UPSCALED —
#   it renders visibly blurry at dock/tray sizes while simple-icons (which carry
#   no width/height, only a viewBox) stay crisp. Strip the root's width/height so
#   the viewBox alone drives scaling. Only the ROOT tag: inner <rect width=…> etc.
#   must survive.
m = re.search(r'<svg\b[^>]*>', s)
if m:
    root = re.sub(r'\s(?:width|height)="[^"]*"', '', m.group(0))
    s = s[:m.start()] + root + s[m.end():]

gid = "ngGrad"
defs = (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="{c1}"/>'
        f'<stop offset="1" stop-color="{c2}"/></linearGradient></defs>')
s = re.sub(r'(<svg\b[^>]*>)', r'\1' + defs, s, count=1)
s = re.sub(r'<svg\b', f'<svg fill="url(#{gid})"', s, count=1)
open(dst, 'w').write(s)
PY
}

while IFS='|' read -r name url c1 c2; do
  [ -n "$name" ] || continue
  tmp=$(mktemp)
  if ! curl -fsSL "$url" -o "$tmp"; then
    echo "  !! could not fetch $name" >&2; rm -f "$tmp"; continue
  fi
  grad_svg "$tmp" "$OUT/$name.svg" "$c1" "$c2"
  rm -f "$tmp"
  echo "  $name  #$c1 -> #$c2"
done <<< "$MAP"

# Cohesion's Flatpak desktop entry requests this application-specific name.
# Keep it as an alias of the generated Notion mark so the launcher, task manager,
# and tray replacement all resolve to the exact same SVG.
ln -sfn notion.svg "$OUT/io.github.brunofin.Cohesion.svg"
echo "  io.github.brunofin.Cohesion -> notion"

# VS Code's CachyOS package asks for visual-studio-code-electron; BeautyLine
# only ships visual-studio-code / code. Alias so the dock mark is the hue-snapped
# VS Code glyph, not a missing-icon fallback.
if [ -e "$OUT/visual-studio-code.svg" ]; then
  ln -sfn visual-studio-code.svg "$OUT/visual-studio-code-electron.svg"
  echo "  visual-studio-code-electron -> visual-studio-code"
fi

# --- authored marks (Linear, Proton Mail, Notion Calendar, Affinity) --------
# These are the live SVGs from the reference machine. They are not in
# simple-icons as usable dock marks (Linear's official PNG is a black tile;
# Proton Mail / Notion Calendar desktop files ship raster; Affinity is a Wine
# suite with a proprietary lettermark). Copy them over the hue-snapped
# BeautyLine leftovers so the dock matches the reference box.
MARKS="$HERE/marks"
if [ -d "$MARKS" ]; then
  for mark in linear-linux proton-mail notion-calendar affinity; do
    if [ -f "$MARKS/$mark.svg" ]; then
      cp -f "$MARKS/$mark.svg" "$OUT/$mark.svg"
      echo "  $mark  (reference mark)"
    fi
  done
fi

# Affinity.desktop on the reference machine uses an absolute path, not a theme
# name. Keep that path in sync so Wine/launcher and the icon theme agree.
if [ -f "$OUT/affinity.svg" ]; then
  mkdir -p "$HOME/.local/share/icons"
  cp -f "$OUT/affinity.svg" "$HOME/.local/share/icons/Affinity.svg"
  echo "  ~/.local/share/icons/Affinity.svg"
fi

# --- Antigravity vs Antigravity IDE -----------------------------------------
# Upstream ships the SAME arch glyph for both; the only difference is that the
# launcher sits on a rounded tile and the IDE is bare. Identical icons side by
# side in a dock are useless, so we make that distinction explicit AND give them
# different gradients:
#   antigravity      -> arch inside a neon tile frame, green->cyan
#   antigravity-ide  -> bare arch, cyan->violet (written by the MAP above)
ARCH='M21.751 22.607c1.34 1.005 3.35.335 1.508-1.508C17.73 15.74 18.904 1 12.037 1 5.17 1 6.342 15.74.815 21.1c-2.01 2.009.167 2.511 1.507 1.506 5.192-3.517 4.857-9.714 9.715-9.714 4.857 0 4.522 6.197 9.714 9.715z'
cat > "$OUT/antigravity.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill-rule="evenodd">
  <title>Antigravity</title>
  <defs>
    <linearGradient id="agFill" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="$(hx "$GREEN_HERO")"/>
      <stop offset="1" stop-color="$(hx "$CYAN")"/>
    </linearGradient>
  </defs>
  <rect x="0.9" y="0.9" width="22.2" height="22.2" rx="5.2"
        fill="none" stroke="url(#agFill)" stroke-width="1.5" opacity="0.85"/>
  <g transform="translate(12 12.4) scale(0.62) translate(-12 -12)">
    <path d="$ARCH" fill="url(#agFill)"/>
  </g>
</svg>
EOF
echo "  antigravity  #$GREEN_HERO -> #$CYAN (tiled, to distinguish from the IDE)"

# --- T3 Code ----------------------------------------------------------------
# T3 ships NO vector anywhere: not simple-icons, not lobe-icons, not t3.gg, and
# the Electron bundle carries only PNGs (/opt/t3code-bin/usr/share/icons/…).
# What hicolor resolves is a 1024px BLACK ROUNDED TILE with chrome-bevelled "T3"
# — an opaque dark square in a dock of bare neon glyphs, so it reads as a hole.
# Hence the mark is authored here, same construction as antigravity above:
# a stroked tile frame (which also keeps T3 *Code* distinct from T3 Chat) around
# stroked T3 letterforms. Strokes, not filled outlines, so the glyph stays
# consistent with the frame and survives downscaling to tray sizes.
#
# gradientUnits="userSpaceOnUse" is load-bearing: this icon is the only one with
# TWO painted elements. Under the default objectBoundingBox each of the frame and
# the glyph would run the full magenta->cyan ramp inside its OWN box, so the tile
# and the letters would disagree about the color at any given point. In user
# space one ramp crosses the whole 24x24 and both elements sample the same line.
#
# magenta -> bright cyan is the one neon pair no other app in MAP uses (violet
# leans into T3's own brand hue while staying clear of obsidian/antigravity).
cat > "$OUT/t3code.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <title>T3 Code</title>
  <defs>
    <linearGradient id="t3Fill" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="24" y2="24">
      <stop offset="0" stop-color="$(hx "$MAGENTA")"/>
      <stop offset="1" stop-color="$(hx "$CYAN_BR")"/>
    </linearGradient>
  </defs>
  <rect x="0.9" y="0.9" width="22.2" height="22.2" rx="5.2"
        fill="none" stroke="url(#t3Fill)" stroke-width="1.5" opacity="0.85"/>
  <!-- Letterforms are drawn on their own baseline, then centred as a unit: the
       ink spans x 2.4..21.3, so -11.85 (not -12) is what actually centres it. -->
  <g transform="translate(12 12) scale(0.86) translate(-11.85 -12)"
     fill="none" stroke="url(#t3Fill)" stroke-width="2.2"
     stroke-linecap="round" stroke-linejoin="round">
    <path d="M3.6 7.2H11.2M7.4 7.2V16.8"/>
    <path d="M13.8 7.2h5.6l-2.8 4.2"/>
    <path d="M15.9 11.4h1c1.8 0 3.2 1.2 3.2 2.7s-1.4 2.7-3.2 2.7c-1.2 0-2.2-.5-2.7-1.4"/>
  </g>
</svg>
EOF
echo "  t3code  #$MAGENTA -> #$CYAN_BR (authored; upstream ships only a black-tile PNG)"

# --- stragglers -------------------------------------------------------------
# File manager + launcher come from BeautyLine, which paints the folder bright
# orange. BeautyLine already uses linearGradients, so we only need to rewrite
# its stop-colors — that PRESERVES the gradient and just moves it into palette.
recolor_local() {
  local src="$1" name="$2" c1="$3" c2="$4"
  [ -f "$src" ] || return 0
  python3 - "$src" "$OUT/$name.svg" "#$c1" "#$c2" <<'PY'
import re, sys
src, dst, c1, c2 = sys.argv[1:5]
s = open(src).read()
stops = [c1, c2]; i = [0]
def nxt(_m):
    c = stops[i[0] % 2]; i[0] += 1
    return f'stop-color="{c}"'
s = re.sub(r'stop-color="[^"]*"', nxt, s)
s = re.sub(r'stop-color:\s*[^;"\']+', lambda m: f'stop-color:{c1}', s)
s = re.sub(r'fill:\s*#[0-9a-fA-F]{3,6}', f'fill:{c1}', s)
s = re.sub(r'stroke:\s*#[0-9a-fA-F]{3,6}', f'stroke:{c1}', s)
s = re.sub(r'fill="(?!none|url)[^"]*"', f'fill="{c1}"', s)
s = re.sub(r'stroke="(?!none|url)#[0-9a-fA-F]{3,6}"', f'stroke="{c1}"', s)
open(dst, 'w').write(s)
PY
  echo "  $name  #$c1 -> #$c2 (BeautyLine gradient remapped)"
}

BL=/usr/share/icons/BeautyLine/apps/scalable
recolor_local "$BL/system-file-manager.svg" system-file-manager "$GREEN_HERO" "$CYAN"
recolor_local "$BL/org.kde.dolphin.svg"     org.kde.dolphin     "$GREEN_HERO" "$CYAN"
recolor_local "$BL/start-here.svg"          start-here          "$VIOLET"     "$GREEN_HERO"
recolor_local "$BL/start-here-kde.svg"      start-here-kde      "$VIOLET"     "$GREEN_HERO"
recolor_local "$BL/start-here.svg"          org.cachyos.hello   "$VIOLET"     "$GREEN_HERO"

# hue-snap.py builds the full theme (copied from BeautyLine, every hue snapped
# into the palette) and brings a complete index.theme with it. Only write a
# standalone index if that hasn't run — otherwise we'd throw away every
# directory mapping and the theme would resolve almost nothing.
if [ ! -f "$THEME/index.theme" ]; then
cat > "$THEME/index.theme" <<EOF
[Icon Theme]
Name=NeonGrid
Comment=Neon gradient app marks over BeautyLine
Inherits=BeautyLine,Colloid-Dark,breeze-dark,hicolor
Directories=apps/scalable

[apps/scalable]
Size=48
MinSize=16
MaxSize=512
Context=Applications
Type=Scalable
EOF
fi

gtk-update-icon-cache -f -t "$THEME" 2>/dev/null || true
echo "built: $THEME"

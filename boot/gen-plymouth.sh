#!/usr/bin/env bash
# Builds the "neongrid" Plymouth theme by recoloring the stock `spinner` theme.
#
# Why recolor a stock theme instead of pulling an AUR theme pack: Plymouth themes
# are just PNG sequences + an ini, they don't rot, and the well-known neon packs
# (adi1090x) haven't been touched since 2024. Recoloring `spinner` gives us a
# maintained base that survives Plymouth updates.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

SRC=/usr/share/plymouth/themes/spinner
OUT="$HERE/plymouth/neongrid"

command -v magick >/dev/null || { echo "imagemagick required" >&2; exit 1; }

rm -rf "$OUT"; mkdir -p "$OUT"
cp "$SRC"/*.png "$OUT"/ 2>/dev/null || true

# The spinner art is white/grey. Tint it hero-green while keeping the alpha mask:
# colorize by multiplying against a solid neon fill.
for f in "$OUT"/*.png; do
  magick "$f" \
    \( +clone -alpha extract \) \
    -alpha off -fill "$(hx "$GREEN_HERO")" -colorize 100% \
    -compose CopyOpacity -composite \
    "$f"
done

# throbber/progress art that should read violet instead, for contrast
for f in "$OUT"/progress-*.png "$OUT"/throbber-*.png; do
  [ -e "$f" ] || continue
  magick "$f" \
    \( +clone -alpha extract \) \
    -alpha off -fill "$(hx "$VIOLET")" -colorize 100% \
    -compose CopyOpacity -composite \
    "$f"
done

cat > "$OUT/neongrid.plymouth" <<EOF
[Plymouth Theme]
Name=NeonGrid
Description=Cyberpunk neon boot splash
ModuleName=two-step

[two-step]
Font=Rajdhani 12
TitleFont=Orbitron 28
MonospaceFont=JetBrainsMono Nerd Font 12
ImageDir=/usr/share/plymouth/themes/neongrid
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.382
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.382
HorizontalAlignment=.5
VerticalAlignment=.7
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.96
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x${BG}
BackgroundEndColor=0x${BG}
ProgressBarBackgroundColor=0x${SURFACE_HI}
ProgressBarForegroundColor=0x${GREEN_HERO}
MessageBelowAnimation=true

[boot-up]
UseEndAnimation=false

[shutdown]
UseEndAnimation=false

[reboot]
UseEndAnimation=false
EOF

echo "built plymouth theme: $OUT"

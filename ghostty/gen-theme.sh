#!/usr/bin/env bash
# Generates the Ghostty NeonGrid theme from palette.sh.
# A Ghostty theme file is just a config file that sets colors — it may NOT set
# `theme` itself.
set -euo pipefail
source "$(dirname "$0")/../palette.sh"

OUT="${1:-$(dirname "$0")/themes/NeonGrid}"

cat > "$OUT" <<EOF
# NeonGrid — generated from cyberdeck/palette.sh. Do not hand-edit.
background = $(hx "$BG")
foreground = $(hx "$FG")
cursor-color = $(hx "$CURSOR")
cursor-text = $(hx "$CURSOR_TEXT")
selection-background = $(hx "$SEL_BG")
selection-foreground = $(hx "$SEL_FG")
bold-color = $(hx "$WHITE_BR")

# normal
palette = 0=$(hx "$SURFACE")
palette = 1=$(hx "$RED")
palette = 2=$(hx "$GREEN")
palette = 3=$(hx "$YELLOW")
palette = 4=$(hx "$VIOLET")
palette = 5=$(hx "$MAGENTA")
palette = 6=$(hx "$CYAN")
palette = 7=$(hx "$WHITE")

# bright
palette = 8=$(hx "$BLACK_BR")
palette = 9=$(hx "$RED_BR")
palette = 10=$(hx "$GREEN_HERO")
palette = 11=$(hx "$YELLOW_BR")
palette = 12=$(hx "$VIOLET_BR")
palette = 13=$(hx "$MAGENTA_BR")
palette = 14=$(hx "$CYAN_BR")
palette = 15=$(hx "$WHITE_BR")
EOF

echo "wrote $OUT"

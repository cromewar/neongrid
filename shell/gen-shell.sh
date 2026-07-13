#!/usr/bin/env bash
# Terminal ecosystem: one palette across prompt, btop, fzf, bat, eza, cava,
# fastfetch. This is where the user actually lives (Claude Code / Codex), so it
# matters more than the desktop chrome.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../palette.sh"

mkdir -p ~/.config/{btop/themes,fastfetch,bat,cava,eza}

# ============ starship ==================================================
# Starship over powerlevel10k: p10k drives color via 256-color INDICES, which
# would quantize #39ff14 into something muddy. Starship takes raw hex per module
# and gives one prompt across both zsh and fish.
cat > ~/.config/starship.toml <<EOF
"\$schema" = 'https://starship.rs/config-schema.json'

format = """
[](fg:$(hx "$GREEN_HERO"))\\
\$os\\
\$directory\\
\$git_branch\\
\$git_status\\
\$python\\
\$nodejs\\
\$rust\\
\$docker_context\\
\$cmd_duration\\
\$line_break\\
\$character"""

add_newline = true

[character]
success_symbol = "[▶](bold $(hx "$GREEN_HERO"))"
error_symbol = "[▶](bold $(hx "$RED"))"
vimcmd_symbol = "[◀](bold $(hx "$VIOLET"))"

[os]
disabled = false
style = "bg:$(hx "$GREEN_HERO") fg:$(hx "$BG")"
format = '[ \$symbol ](\$style)[](fg:$(hx "$GREEN_HERO") bg:$(hx "$SEL_BG"))'

[os.symbols]
Arch = "󰣇"
Linux = "󰌽"

[directory]
style = "bg:$(hx "$SEL_BG") fg:$(hx "$VIOLET_BR")"
format = '[ \$path ](\$style)[](fg:$(hx "$SEL_BG") bg:$(hx "$SURFACE_HI"))'
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = ""
style = "bg:$(hx "$SURFACE_HI") fg:$(hx "$MAGENTA")"
format = '[ \$symbol \$branch ](\$style)'

[git_status]
style = "bg:$(hx "$SURFACE_HI") fg:$(hx "$YELLOW")"
format = '[\$all_status\$ahead_behind ](\$style)[](fg:$(hx "$SURFACE_HI"))'

[python]
symbol = ""
style = "fg:$(hx "$CYAN")"
format = ' [\$symbol \$version](\$style)'

[nodejs]
symbol = ""
style = "fg:$(hx "$GREEN")"
format = ' [\$symbol \$version](\$style)'

[rust]
symbol = ""
style = "fg:$(hx "$RED")"
format = ' [\$symbol \$version](\$style)'

[docker_context]
symbol = " "
style = "fg:$(hx "$VIOLET")"
format = ' [\$symbol \$context](\$style)'

[cmd_duration]
min_time = 500
style = "fg:$(hx "$FG_DIM")"
format = ' [ \$duration](\$style)'
EOF

# ============ btop ======================================================
cat > ~/.config/btop/themes/neongrid.theme <<EOF
# NeonGrid — generated from cyberdeck/palette.sh
theme[main_bg]="$(hx "$BG")"
theme[main_fg]="$(hx "$FG")"
theme[title]="$(hx "$WHITE_BR")"
theme[hi_fg]="$(hx "$GREEN_HERO")"
theme[selected_bg]="$(hx "$SEL_BG")"
theme[selected_fg]="$(hx "$GREEN_HERO")"
theme[inactive_fg]="$(hx "$FG_DIM")"
theme[graph_text]="$(hx "$FG_DIM")"
theme[meter_bg]="$(hx "$SURFACE_HI")"
theme[proc_misc]="$(hx "$VIOLET")"
theme[cpu_box]="$(hx "$GREEN")"
theme[mem_box]="$(hx "$VIOLET")"
theme[net_box]="$(hx "$MAGENTA")"
theme[proc_box]="$(hx "$CYAN")"
theme[div_line]="$(hx "$SURFACE_HI")"
theme[temp_start]="$(hx "$GREEN")"
theme[temp_mid]="$(hx "$YELLOW")"
theme[temp_end]="$(hx "$RED")"
theme[cpu_start]="$(hx "$GREEN")"
theme[cpu_mid]="$(hx "$CYAN")"
theme[cpu_end]="$(hx "$MAGENTA")"
theme[free_start]="$(hx "$VIOLET")"
theme[free_mid]="$(hx "$VIOLET_BR")"
theme[free_end]="$(hx "$MAGENTA")"
theme[cached_start]="$(hx "$CYAN")"
theme[cached_mid]="$(hx "$CYAN_BR")"
theme[cached_end]="$(hx "$VIOLET")"
theme[available_start]="$(hx "$YELLOW")"
theme[available_mid]="$(hx "$YELLOW_BR")"
theme[available_end]="$(hx "$RED")"
theme[used_start]="$(hx "$GREEN")"
theme[used_mid]="$(hx "$GREEN_HERO")"
theme[used_end]="$(hx "$MAGENTA")"
theme[download_start]="$(hx "$VIOLET")"
theme[download_mid]="$(hx "$MAGENTA")"
theme[download_end]="$(hx "$MAGENTA_BR")"
theme[upload_start]="$(hx "$GREEN")"
theme[upload_mid]="$(hx "$GREEN_HERO")"
theme[upload_end]="$(hx "$CYAN_BR")"
EOF
# point btop at it
if [ -f ~/.config/btop/btop.conf ]; then
  sed -i 's|^color_theme =.*|color_theme = "neongrid"|' ~/.config/btop/btop.conf
  grep -q '^color_theme' ~/.config/btop/btop.conf || echo 'color_theme = "neongrid"' >> ~/.config/btop/btop.conf
  sed -i 's|^theme_background =.*|theme_background = False|' ~/.config/btop/btop.conf
else
  printf 'color_theme = "neongrid"\ntheme_background = False\ntruecolor = True\n' > ~/.config/btop/btop.conf
fi

# ============ bat =======================================================
# 1337 is bat's built-in neon/hacker theme — closest match without shipping a
# whole .tmTheme.
cat > ~/.config/bat/config <<'EOF'
--theme="1337"
--style="numbers,changes,header"
--italic-text=always
EOF

# ============ cava ======================================================
cat > ~/.config/cava/config <<EOF
[general]
framerate = 60
autosens = 1
bars = 0

[color]
gradient = 1
gradient_count = 6
gradient_color_1 = '$(hx "$GREEN_HERO")'
gradient_color_2 = '$(hx "$GREEN")'
gradient_color_3 = '$(hx "$CYAN")'
gradient_color_4 = '$(hx "$VIOLET")'
gradient_color_5 = '$(hx "$MAGENTA")'
gradient_color_6 = '$(hx "$MAGENTA_BR")'

[smoothing]
noise_reduction = 45
EOF

# ============ shared env (fzf + LS_COLORS + zsh highlighting) ===========
# Sourced by both zsh and fish (fish gets its own translation below).
cat > "$HERE/neongrid-env.sh" <<EOF
# NeonGrid shell env — generated. Sourced from ~/.zshrc.

export FZF_DEFAULT_OPTS="\\
--color=fg:$(hx "$FG"),bg:-1,hl:$(hx "$GREEN_HERO") \\
--color=fg+:$(hx "$WHITE_BR"),bg+:$(hx "$SEL_BG"),hl+:$(hx "$GREEN_HERO") \\
--color=info:$(hx "$VIOLET"),prompt:$(hx "$GREEN_HERO"),pointer:$(hx "$MAGENTA") \\
--color=marker:$(hx "$RED"),spinner:$(hx "$VIOLET_BR"),border:$(hx "$SEL_BG") \\
--color=header:$(hx "$FG_DIM") \\
--height=60% --layout=reverse --border=rounded --prompt='▶ '"

# One LS_COLORS shared by ls/eza/fd/tree. NOTE: LS_COLORS/EZA_COLORS override
# eza's theme.yml — we deliberately use vivid as the single mechanism.
if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS="\$(vivid generate molokai 2>/dev/null)"
fi

export SUDO_PROMPT=\$'\e[1;35m[sudo]\e[0m password for %p: '
EOF

# ============ fastfetch =================================================
cat > ~/.config/fastfetch/config.jsonc <<EOF
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "arch",
    "color": { "1": "green", "2": "magenta" },
    "padding": { "top": 1, "right": 3 }
  },
  "display": { "separator": " ▸ " },
  "modules": [
    "break",
    { "type": "title", "color": { "user": "green", "host": "magenta" } },
    { "type": "separator", "string": "─" },
    { "type": "os",         "key": "  OS",     "keyColor": "green" },
    { "type": "kernel",     "key": "  KERNEL", "keyColor": "green" },
    { "type": "uptime",     "key": "  UPTIME", "keyColor": "green" },
    { "type": "packages",   "key": "  PKGS",   "keyColor": "magenta" },
    { "type": "shell",      "key": "  SHELL",  "keyColor": "magenta" },
    { "type": "terminal",   "key": "  TERM",   "keyColor": "magenta" },
    { "type": "wm",         "key": "  WM",     "keyColor": "blue" },
    { "type": "separator",  "string": "─" },
    { "type": "cpu",        "key": "  CPU",    "keyColor": "cyan" },
    { "type": "gpu",        "key": "  GPU",    "keyColor": "cyan" },
    { "type": "memory",     "key": "  MEM",    "keyColor": "cyan" },
    { "type": "disk",       "key": "  DISK",   "keyColor": "cyan" },
    "break",
    { "type": "colors", "paddingLeft": 2, "symbol": "circle" },
    "break"
  ]
}
EOF

echo "Shell ecosystem written."

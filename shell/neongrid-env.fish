# NeonGrid shell env — generated. Sourced from ~/.config/fish/config.fish.

set -gx FZF_DEFAULT_OPTS "--color=fg:#c6d0cb,bg:-1,hl:#39ff14 --color=fg+:#e6f2ee,bg+:#2a1b4d,hl+:#39ff14 --color=info:#9d6bff,prompt:#39ff14,pointer:#d96bff --color=marker:#ff3c6a,spinner:#bc8cff,border:#2a1b4d --color=header:#7d8a86 --height=60% --layout=reverse --border=rounded --prompt='▶ '"

if command -q vivid
    set -gx LS_COLORS (vivid generate molokai 2>/dev/null)
end

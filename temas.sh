#!/usr/bin/env bash
# Lista temas de cores e aplica um deles no GNOME Terminal: cria (ou atualiza) um perfil
# com o nome do tema e o define como padrão. Os perfis que já existem não são alterados.
# Muda só o terminal (fundo, texto e paleta); a barra do tmux segue o tmux.conf.
#
# Uso:
#   ./temas.sh              lista os temas e pergunta qual aplicar
#   ./temas.sh <tema>       aplica o tema, pelo nome ou pelo número da lista (ex.: dracula)
#   ./temas.sh <tema> -t 15 aplica o tema com 15% de transparência no fundo (de 0 a 100)
#   ./temas.sh -t 15        muda só a transparência do perfil em uso (0 desliga)
#   ./temas.sh --list       só lista os temas
#   ./temas.sh --help       mostra esta ajuda
set -euo pipefail

# Fonte do perfil: só é aplicada se estiver instalada (o install.sh instala a Hack Nerd Font).
PROFILE_FONT_FAMILY="${PROFILE_FONT_FAMILY:-Hack Nerd Font Mono}"
PROFILE_FONT_SIZE="${PROFILE_FONT_SIZE:-16}"

PROFILES="org.gnome.Terminal.ProfilesList"
PROFILE_SCHEMA="org.gnome.Terminal.Legacy.Profile"
PROFILE_PATH="/org/gnome/terminal/legacy/profiles:"

info() { printf '\033[1;35m>>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,12s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }

# Um tema por linha: id|nome do perfil|fundo|texto|cursor|seleção|paleta (16 cores ANSI).
# Para adicionar um tema, basta incluir uma linha.
themes() {
    cat <<'EOF'
catppuccin-mocha|Catppuccin Mocha|#1e1e2e|#cdd6f4|#f5e0dc|#585b70|#45475a #f38ba8 #a6e3a1 #f9e2af #89b4fa #f5c2e7 #94e2d5 #bac2de #585b70 #f38ba8 #a6e3a1 #f9e2af #89b4fa #f5c2e7 #94e2d5 #a6adc8
catppuccin-macchiato|Catppuccin Macchiato|#24273a|#cad3f5|#f4dbd6|#5b6078|#494d64 #ed8796 #a6da95 #eed49f #8aadf4 #f5bde6 #8bd5ca #b8c0e0 #5b6078 #ed8796 #a6da95 #eed49f #8aadf4 #f5bde6 #8bd5ca #a5adcb
catppuccin-frappe|Catppuccin Frappe|#303446|#c6d0f5|#f2d5cf|#626880|#51576d #e78284 #a6d189 #e5c890 #8caaee #f4b8e4 #81c8be #b5bfe2 #626880 #e78284 #a6d189 #e5c890 #8caaee #f4b8e4 #81c8be #a5adce
catppuccin-latte|Catppuccin Latte|#eff1f5|#4c4f69|#dc8a78|#acb0be|#5c5f77 #d20f39 #40a02b #df8e1d #1e66f5 #ea76cb #179299 #acb0be #6c6f85 #d20f39 #40a02b #df8e1d #1e66f5 #ea76cb #179299 #bcc0cc
dracula|Dracula|#282a36|#f8f8f2|#f8f8f2|#44475a|#21222c #ff5555 #50fa7b #f1fa8c #bd93f9 #ff79c6 #8be9fd #f8f8f2 #6272a4 #ff6e6e #69ff94 #ffffa5 #d6acff #ff92df #a4ffff #ffffff
nord|Nord|#2e3440|#d8dee9|#d8dee9|#434c5e|#3b4252 #bf616a #a3be8c #ebcb8b #81a1c1 #b48ead #88c0d0 #e5e9f0 #4c566a #bf616a #a3be8c #ebcb8b #81a1c1 #b48ead #8fbcbb #eceff4
gruvbox-dark|Gruvbox Dark|#282828|#ebdbb2|#ebdbb2|#504945|#282828 #cc241d #98971a #d79921 #458588 #b16286 #689d6a #a89984 #928374 #fb4934 #b8bb26 #fabd2f #83a598 #d3869b #8ec07c #ebdbb2
tokyo-night|Tokyo Night|#1a1b26|#c0caf5|#c0caf5|#283457|#15161e #f7768e #9ece6a #e0af68 #7aa2f7 #bb9af7 #7dcfff #a9b1d6 #414868 #f7768e #9ece6a #e0af68 #7aa2f7 #bb9af7 #7dcfff #c0caf5
one-dark|One Dark|#282c34|#abb2bf|#528bff|#3e4451|#282c34 #e06c75 #98c379 #e5c07b #61afef #c678dd #56b6c2 #abb2bf #5c6370 #e06c75 #98c379 #e5c07b #61afef #c678dd #56b6c2 #ffffff
rose-pine|Rose Pine|#191724|#e0def4|#e0def4|#403d52|#26233a #eb6f92 #31748f #f6c177 #9ccfd8 #c4a7e7 #ebbcba #e0def4 #6e6a86 #eb6f92 #31748f #f6c177 #9ccfd8 #c4a7e7 #ebbcba #e0def4
kanagawa|Kanagawa|#1f1f28|#dcd7ba|#c8c093|#2d4f67|#16161d #c34043 #76946a #c0a36e #7e9cd8 #957fb8 #6a9589 #c8c093 #727169 #e82424 #98bb6c #e6c384 #7fb4ca #938aa9 #7aa89f #dcd7ba
everforest-dark|Everforest Dark|#2d353b|#d3c6aa|#d3c6aa|#475258|#475258 #e67e80 #a7c080 #dbbc7f #7fbbb3 #d699b6 #83c092 #d3c6aa #859289 #e67e80 #a7c080 #dbbc7f #7fbbb3 #d699b6 #83c092 #d3c6aa
tokyo-night-storm|Tokyo Night Storm|#24283b|#c0caf5|#c0caf5|#2e3c64|#1d202f #f7768e #9ece6a #e0af68 #7aa2f7 #bb9af7 #7dcfff #a9b1d6 #414868 #f7768e #9ece6a #e0af68 #7aa2f7 #bb9af7 #7dcfff #c0caf5
rose-pine-moon|Rose Pine Moon|#232136|#e0def4|#e0def4|#44415a|#393552 #eb6f92 #3e8fb0 #f6c177 #9ccfd8 #c4a7e7 #ea9a97 #e0def4 #6e6a86 #eb6f92 #3e8fb0 #f6c177 #9ccfd8 #c4a7e7 #ea9a97 #e0def4
monokai|Monokai|#272822|#f8f8f2|#f8f8f2|#49483e|#272822 #f92672 #a6e22e #f4bf75 #66d9ef #ae81ff #a1efe4 #f8f8f2 #75715e #f92672 #a6e22e #f4bf75 #66d9ef #ae81ff #a1efe4 #f9f8f5
ayu-dark|Ayu Dark|#0b0e14|#b3b1ad|#e6b450|#273747|#01060e #ea6c73 #91b362 #f9af4f #53bdfa #fae994 #90e1c6 #c7c7c7 #686868 #f07178 #c2d94c #ffb454 #59c2ff #ffee99 #95e6cb #ffffff
ayu-mirage|Ayu Mirage|#1f2430|#cbccc6|#ffcc66|#33415e|#191e2a #ed8274 #a6cc70 #fad07b #6dcbfa #cfbafa #90e1c6 #c7c7c7 #686868 #f28779 #bae67e #ffd580 #73d0ff #d4bfff #95e6cb #ffffff
night-owl|Night Owl|#011627|#d6deeb|#80a4c2|#1d3b53|#011627 #ef5350 #22da6e #addb67 #82aaff #c792ea #21c7a8 #ffffff #575656 #ef5350 #22da6e #ffeb95 #82aaff #c792ea #7fdbca #ffffff
github-dark|GitHub Dark|#0d1117|#c9d1d9|#58a6ff|#264f78|#484f58 #ff7b72 #3fb950 #d29922 #58a6ff #bc8cff #39c5cf #b1bac4 #6e7681 #ffa198 #56d364 #e3b341 #79c0ff #d2a8ff #56d4dd #f0f6fc
palenight|Palenight|#292d3e|#a6accd|#ffcc00|#3c435e|#292d3e #f07178 #c3e88d #ffcb6b #82aaff #c792ea #89ddff #d0d0d0 #676e95 #f07178 #c3e88d #ffcb6b #82aaff #c792ea #89ddff #ffffff
synthwave-84|Synthwave 84|#262335|#ffffff|#03edf9|#463465|#262335 #fe4450 #72f1b8 #fede5d #03edf9 #ff7edb #03edf9 #ffffff #614d85 #fe4450 #72f1b8 #f3e70f #03edf9 #ff7edb #03edf9 #ffffff
solarized-dark|Solarized Dark|#002b36|#839496|#93a1a1|#073642|#073642 #dc322f #859900 #b58900 #268bd2 #d33682 #2aa198 #eee8d5 #002b36 #cb4b16 #586e75 #657b83 #839496 #6c71c4 #93a1a1 #fdf6e3
solarized-light|Solarized Light|#fdf6e3|#657b83|#586e75|#eee8d5|#073642 #dc322f #859900 #b58900 #268bd2 #d33682 #2aa198 #eee8d5 #002b36 #cb4b16 #586e75 #657b83 #839496 #6c71c4 #93a1a1 #fdf6e3
gruvbox-light|Gruvbox Light|#fbf1c7|#3c3836|#3c3836|#d5c4a1|#fbf1c7 #cc241d #98971a #d79921 #458588 #b16286 #689d6a #7c6f64 #928374 #9d0006 #79740e #b57614 #076678 #8f3f71 #427b58 #3c3836
one-light|One Light|#fafafa|#383a42|#526fff|#e5e5e6|#383a42 #e45649 #50a14f #c18401 #4078f2 #a626a4 #0184bc #a0a1a7 #4f525d #e45649 #50a14f #c18401 #4078f2 #a626a4 #0184bc #fafafa
EOF
}

# (sem grep -q nos pipes deste script: ele fecha o pipe cedo e o pipefail acusaria erro)
has_gnome_terminal() {
    command -v gsettings >/dev/null 2>&1 && gsettings list-schemas | grep -x "$PROFILES" >/dev/null
}

has_font() {
    command -v fc-list >/dev/null 2>&1 && fc-list : family | grep -x "$PROFILE_FONT_FAMILY" >/dev/null
}

# A transparência do fundo é um acréscimo de algumas distros (Ubuntu, Debian, Fedora).
has_transparency() {
    gsettings list-keys "$PROFILE_SCHEMA" | grep -x use-transparent-background >/dev/null
}

profile_get() { gsettings get "$PROFILE_SCHEMA:$PROFILE_PATH/:$1/" "$2"; }
profile_set() { gsettings set "$PROFILE_SCHEMA:$PROFILE_PATH/:$1/" "$2" "$3"; }

default_id() { gsettings get "$PROFILES" default | tr -d "'"; }

check_transparency() {
    case "$1" in
        ''|*[!0-9]*) die "Transparência inválida: '$1' (use um número de 0 a 100)" ;;
    esac
    [ "$1" -le 100 ] || die "Transparência inválida: '$1' (use um número de 0 a 100)"
}

# Transparência do fundo de um perfil: set_transparency <id> <0 a 100> (0 desliga)
set_transparency() {
    if ! has_transparency; then
        warn "Este GNOME Terminal não tem a opção de transparência; ficou sem"
        return 0
    fi
    profile_set "$1" use-theme-transparency false
    if [ "$2" -eq 0 ]; then
        profile_set "$1" use-transparent-background false
        info "Transparência desligada"
    else
        profile_set "$1" use-transparent-background true
        profile_set "$1" background-transparency-percent "$2"
        info "Transparência do fundo: $2%"
    fi
}

# Nome do perfil padrão do GNOME Terminal (vazio se não houver).
current_name() {
    local id name
    has_gnome_terminal || return 0
    id="$(default_id)"
    [ -n "$id" ] || return 0
    name="$(profile_get "$id" visible-name)"
    name="${name#\'}"
    printf '%s\n' "${name%\'}"
}

# '#rrggbb' -> 'r;g;b', para as sequências de cor do terminal.
rgb() { printf '%d;%d;%d' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }

list_themes() {
    local current n=0 id name bg fg cursor sel palette color mark
    current="$(current_name)"
    while IFS='|' read -r id name bg fg cursor sel palette; do
        n=$((n + 1))
        mark=""
        [ "$name" = "$current" ] && mark=" (atual)"
        printf '%2d) %-21s \033[48;2;%sm\033[38;2;%sm  %-20s  ' "$n" "$id" "$(rgb "$bg")" "$(rgb "$fg")" "$name"
        for color in $palette; do
            printf '\033[48;2;%sm  ' "$(rgb "$color")"
        done
        printf '\033[0m%s\n' "$mark"
    done < <(themes)
}

# Acha o tema pelo número da lista, pelo id ou pelo nome; imprime a linha dele.
find_theme() {
    local want n=0 id name rest
    want="$(printf '%s' "$1" | tr '[:upper:] ' '[:lower:]-')"
    while IFS='|' read -r id name rest; do
        n=$((n + 1))
        if [ "$want" = "$n" ] || [ "$want" = "$id" ]; then
            printf '%s|%s|%s\n' "$id" "$name" "$rest"
            return 0
        fi
    done < <(themes)
    return 1
}

# apply_theme <tema> [transparência]: sem a transparência, a do perfil fica como está.
apply_theme() {
    local line id name bg fg cursor sel palette profile_id other other_name old_list new_list created=0
    line="$(find_theme "$1")" || die "Tema desconhecido: $1 (veja a lista com ./temas.sh --list)"
    IFS='|' read -r id name bg fg cursor sel palette <<< "$line"

    has_gnome_terminal || die "GNOME Terminal não encontrado: este script só configura o GNOME Terminal"

    profile_id=""
    for other in $(gsettings get "$PROFILES" list | grep -oE '[0-9a-f-]{36}' || true); do
        other_name="$(profile_get "$other" visible-name)"
        [ "$other_name" = "'$name'" ] && profile_id="$other"
    done
    if [ -z "$profile_id" ]; then
        profile_id="$(cat /proc/sys/kernel/random/uuid)"
        created=1
    fi

    profile_set "$profile_id" visible-name "$name"
    profile_set "$profile_id" use-theme-colors false
    profile_set "$profile_id" background-color "$bg"
    profile_set "$profile_id" foreground-color "$fg"
    profile_set "$profile_id" bold-color-same-as-fg true
    profile_set "$profile_id" cursor-colors-set true
    profile_set "$profile_id" cursor-background-color "$cursor"
    profile_set "$profile_id" cursor-foreground-color "$bg"
    profile_set "$profile_id" highlight-colors-set true
    profile_set "$profile_id" highlight-background-color "$sel"
    profile_set "$profile_id" highlight-foreground-color "$fg"
    profile_set "$profile_id" palette "['${palette// /\', \'}']"
    if [ "$created" -eq 1 ] && has_font; then   # num perfil que já existe, a fonte escolhida fica
        profile_set "$profile_id" use-system-font false
        profile_set "$profile_id" font "$PROFILE_FONT_FAMILY $PROFILE_FONT_SIZE"
    fi

    if [ "$created" -eq 1 ]; then
        # Acrescenta à lista de perfis (os perfis existentes não mudam).
        old_list="$(gsettings get "$PROFILES" list)"
        case "$old_list" in
            *"'"*) new_list="${old_list%]}, '$profile_id']" ;;
            *)     new_list="['$profile_id']" ;;
        esac
        gsettings set "$PROFILES" list "$new_list"
        info "Perfil '$name' criado no GNOME Terminal e definido como padrão"
    else
        info "Perfil '$name' atualizado no GNOME Terminal e definido como padrão"
    fi
    gsettings set "$PROFILES" default "$profile_id"
    if [ -n "${2:-}" ]; then
        set_transparency "$profile_id" "$2"
    fi
    info "Vale para janelas novas do terminal; nas abertas, troque em Terminal > Alterar perfil"
}

THEME=""
TRANSPARENCY=""
LIST=0
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -l|--list) LIST=1 ;;
        -t|--transparencia)
            [ $# -ge 2 ] || die "Faltou o valor de $1 (de 0 a 100)"
            TRANSPARENCY="$2"
            check_transparency "$TRANSPARENCY"
            shift ;;
        -*) usage; die "Opção desconhecida: $1" ;;
        *)  [ -z "$THEME" ] || { usage; die "Informe um tema só"; }
            THEME="$1" ;;
    esac
    shift
done

if [ "$LIST" -eq 1 ]; then
    list_themes
elif [ -n "$THEME" ]; then
    apply_theme "$THEME" "$TRANSPARENCY"
elif [ -n "$TRANSPARENCY" ]; then
    has_gnome_terminal || die "GNOME Terminal não encontrado: este script só configura o GNOME Terminal"
    profile_id="$(default_id)"
    [ -n "$profile_id" ] || die "O GNOME Terminal não tem um perfil padrão; aplique um tema primeiro"
    set_transparency "$profile_id" "$TRANSPARENCY"
else
    list_themes
    [ -t 0 ] || exit 0   # sem terminal para perguntar, só lista
    read -r -p "Número ou nome do tema (Enter cancela): " THEME
    [ -n "$THEME" ] || exit 0
    find_theme "$THEME" >/dev/null || die "Tema desconhecido: $THEME"
    read -r -p "Transparência do fundo, de 0 a 100 (Enter mantém como está): " TRANSPARENCY
    [ -z "$TRANSPARENCY" ] || check_transparency "$TRANSPARENCY"
    apply_theme "$THEME" "$TRANSPARENCY"
fi

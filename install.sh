#!/usr/bin/env bash
# Instala e configura o tmux do zero: pacotes, ~/.tmux.conf, TPM, plugins, fonte Hack Nerd
# Font, tema Catppuccin Mocha (barra do tmux e perfil do GNOME Terminal) e autocomplete
# (do comando tmux e, com o ble.sh, de qualquer comando enquanto se digita).
# Pode ser executado quantas vezes quiser (não refaz o que já está pronto).
#
# Uso:
#   ./install.sh            instala tudo
#   ./install.sh --update   instala tudo, atualiza os plugins e reinstala tema e autocompletes
#   ./install.sh --help     mostra esta ajuda
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_SRC="$REPO_DIR/tmux.conf"
CONF_DST="$HOME/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"
TPM_REPO="https://github.com/tmux-plugins/tpm"
MIN_TMUX="3.2"   # a config usa terminal-features, que só existe a partir do 3.2

# Tema da barra do tmux. Fica fora do TPM por causa da ordem de carga (ver tmux.conf).
THEME_REPO="https://github.com/catppuccin/tmux"
THEME_TAG="v2.3.1"
THEME_DIR="$HOME/.tmux/plugins/catppuccin-tmux"

# Perfil do GNOME Terminal com as mesmas cores do tema e uma Nerd Font (ícones da barra).
PROFILE_NAME="Catppuccin Mocha"
PROFILE_FONT_FAMILY="Hack Nerd Font Mono"
PROFILE_FONT_SIZE="16"

# Fonte com os ícones da barra. O sha256 confere o download; ao trocar a versão, troque os dois.
FONT_VERSION="v3.5.1"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/$FONT_VERSION/Hack.zip"
FONT_SHA256="fa24da7de7cefe7766614d27762570b20453c852fc1d5b657111666df9a5e449"
if [ "$(uname)" = "Darwin" ]; then
    FONT_DIR="$HOME/Library/Fonts"
else
    FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
fi

# Autocomplete do comando `tmux` no bash (o Ubuntu não traz um). Fixado em um commit
# porque o arquivo é carregado pelo shell: atualizar exige trocar o hash aqui.
COMPLETION_REPO="https://github.com/imomaliev/tmux-bash-completion"
COMPLETION_COMMIT="cd965a8d5e6adaf829b8d10e74fb20db001dec86"
COMPLETION_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
COMPLETION_DST="$COMPLETION_DIR/tmux"
# Autocomplete de nomes de sessão para os atalhos ta, tk e t (ver completions/tmux-sessions).
ALIAS_COMPLETION_SRC="$REPO_DIR/completions/tmux-sessions"
ALIAS_COMPLETION_NAMES="ta tk t"

# ble.sh: sugestões e menu de autocomplete no bash enquanto se digita, como num editor.
# Também fixado em um commit, pelo mesmo motivo.
BLESH_REPO="https://github.com/akinomyoga/ble.sh"
BLESH_COMMIT="d81fd54feb0d996fdff20dca27eaf0201f7015cc"
BLESH_PREFIX="$HOME/.local"
BLESH_DST="$BLESH_PREFIX/share/blesh/ble.sh"
BASHRC="$HOME/.bashrc"

info() { printf '\033[1;35m>>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,10s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }

UPDATE=0
for arg in "$@"; do
    case "$arg" in
        -u|--update) UPDATE=1 ;;
        -h|--help)   usage; exit 0 ;;
        *)           usage; die "Opção desconhecida: $arg" ;;
    esac
done

[ -f "$CONF_SRC" ] || die "Não achei $CONF_SRC"

# (sem grep -q nos pipes deste script: ele fecha o pipe cedo e o pipefail acusaria erro)
has_font() {
    if command -v fc-list >/dev/null 2>&1; then
        fc-list : family | grep -x "$PROFILE_FONT_FAMILY" >/dev/null
    else
        [ -f "$FONT_DIR/HackNerdFont/HackNerdFontMono-Regular.ttf" ]
    fi
}

# --- 1. Pacotes ---
# Ferramenta de clipboard usada pelo tmux-yank depende do servidor gráfico.
if [ "$(uname)" = "Darwin" ]; then
    clip_cmd="" clip_pkg=""                      # macOS já tem pbcopy
elif [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    clip_cmd="wl-copy" clip_pkg="wl-clipboard"
else
    clip_cmd="xclip" clip_pkg="xclip"
fi

packages=()
command -v tmux >/dev/null 2>&1 || packages+=(tmux)
command -v git  >/dev/null 2>&1 || packages+=(git)
command -v fzf  >/dev/null 2>&1 || packages+=(fzf)      # busca de janelas (Ctrl+b F)
if [ -n "$clip_cmd" ] && ! command -v "$clip_cmd" >/dev/null 2>&1; then
    packages+=("$clip_pkg")
fi
if [ ! -f "$BLESH_DST" ] || [ "$UPDATE" -eq 1 ]; then   # só para compilar o ble.sh
    command -v gawk >/dev/null 2>&1 || packages+=(gawk)
    command -v make >/dev/null 2>&1 || packages+=(make)
fi
if ! has_font; then                                     # só para baixar a fonte
    command -v curl  >/dev/null 2>&1 || packages+=(curl)
    command -v unzip >/dev/null 2>&1 || packages+=(unzip)
fi

if [ ${#packages[@]} -gt 0 ]; then
    info "Instalando pacotes: ${packages[*]}"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y "${packages[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "${packages[@]}"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "${packages[@]}"
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "${packages[@]}"
    elif command -v brew >/dev/null 2>&1; then
        brew install "${packages[@]}"
    else
        die "Gerenciador de pacotes não reconhecido. Instale manualmente: ${packages[*]}"
    fi
else
    info "Pacotes já instalados"
fi

tmux_version="$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -n1)"
if [ "$(printf '%s\n' "$MIN_TMUX" "$tmux_version" | sort -V | head -n1)" != "$MIN_TMUX" ]; then
    warn "tmux $tmux_version é mais antigo que o $MIN_TMUX; partes da config podem não funcionar."
else
    info "tmux $tmux_version"
fi

# --- 2. Config: backup da antiga e link para a do repositório ---
if [ "$(readlink -f "$CONF_DST" 2>/dev/null || true)" = "$CONF_SRC" ]; then
    info "$CONF_DST já aponta para o repositório"
else
    if [ -e "$CONF_DST" ] || [ -L "$CONF_DST" ]; then
        backup="$CONF_DST.bak.$(date +%Y%m%d-%H%M%S)"
        mv "$CONF_DST" "$backup"
        info "Config antiga salva em $backup"
    fi
    ln -s "$CONF_SRC" "$CONF_DST"
    info "$CONF_DST -> $CONF_SRC"
fi

# --- 3. TPM (gerenciador de plugins) e tema ---
if [ -d "$TPM_DIR/.git" ]; then
    info "TPM já instalado"
else
    info "Clonando o TPM"
    mkdir -p "$(dirname "$TPM_DIR")"
    git clone --depth 1 "$TPM_REPO" "$TPM_DIR"
fi

if [ -d "$THEME_DIR/.git" ] && [ "$UPDATE" -eq 0 ]; then
    info "Tema Catppuccin já instalado"
else
    info "Baixando o tema Catppuccin ($THEME_TAG)"
    rm -rf "$THEME_DIR"
    git clone -q --depth 1 --branch "$THEME_TAG" -c advice.detachedHead=false "$THEME_REPO" "$THEME_DIR"
fi

# --- 4. Plugins ---
# O TPM precisa de um servidor tmux rodando com a config carregada.
temp_session=""
temp_dir="$(mktemp -d)"
no_restore="$HOME/tmux_no_auto_restore"   # o tmux-continuum não restaura se este arquivo existir
made_no_restore=0
cleanup() {
    if [ -n "$temp_session" ]; then
        tmux kill-session -t "$temp_session" 2>/dev/null || true
    fi
    if [ "$made_no_restore" -eq 1 ]; then
        rm -f "$no_restore"
    fi
    rm -rf "$temp_dir"
}
trap cleanup EXIT

# Baixa um único commit de um repositório: fetch_commit <repo> <commit> <pasta>
fetch_commit() {
    git init -q "$3"
    git -C "$3" remote add origin "$1"   # submódulos com URL relativa dependem do origin
    git -C "$3" fetch -q --depth 1 origin "$2"
    git -C "$3" checkout -q FETCH_HEAD
}

if ! tmux list-sessions >/dev/null 2>&1; then
    # Sem isto, abrir o tmux aqui restauraria as sessões salvas só para instalar plugins.
    if [ ! -e "$no_restore" ]; then
        touch "$no_restore"
        made_no_restore=1
    fi
    temp_session="__install_$$"
    tmux new-session -d -s "$temp_session"
fi

tmux source-file "$CONF_DST"
info "Instalando plugins"
"$TPM_DIR/bin/install_plugins"
if [ "$UPDATE" -eq 1 ]; then
    info "Atualizando plugins"
    "$TPM_DIR/bin/update_plugins" all
fi
tmux source-file "$CONF_DST"   # recarrega com o tema e os atalhos dos plugins

# --- 5. Fonte Hack Nerd Font (ícones da barra) ---
if has_font; then
    info "Fonte '$PROFILE_FONT_FAMILY' já instalada"
else
    info "Baixando a fonte Hack Nerd Font ($FONT_VERSION)"
    curl -fsSL -o "$temp_dir/Hack.zip" "$FONT_URL"
    if command -v sha256sum >/dev/null 2>&1; then
        echo "$FONT_SHA256  $temp_dir/Hack.zip" | sha256sum -c --quiet - \
            || die "O arquivo da fonte não confere com o sha256 esperado"
    fi
    mkdir -p "$FONT_DIR/HackNerdFont"
    unzip -q -o "$temp_dir/Hack.zip" '*.ttf' -d "$FONT_DIR/HackNerdFont"
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "$FONT_DIR"
    fi
    has_font || warn "A fonte foi copiada para $FONT_DIR, mas o sistema ainda não a enxerga."
fi

# --- 6. Autocomplete do comando tmux no bash ---
# O bash-completion carrega sozinho os arquivos dessa pasta, sem mexer no ~/.bashrc.
if [ -f "$COMPLETION_DST" ] && [ "$UPDATE" -eq 0 ]; then
    info "Autocomplete do tmux já instalado"
else
    info "Instalando o autocomplete do tmux para o bash"
    fetch_commit "$COMPLETION_REPO" "$COMPLETION_COMMIT" "$temp_dir/completion"
    mkdir -p "$(dirname "$COMPLETION_DST")"
    cp "$temp_dir/completion/completions/tmux" "$COMPLETION_DST"
fi
for name in $ALIAS_COMPLETION_NAMES; do
    cp "$ALIAS_COMPLETION_SRC" "$COMPLETION_DIR/$name"
done

# --- 7. ble.sh: autocomplete de comandos enquanto se digita ---
if [ -f "$BLESH_DST" ] && [ "$UPDATE" -eq 0 ]; then
    info "ble.sh já instalado"
else
    info "Instalando o ble.sh"
    fetch_commit "$BLESH_REPO" "$BLESH_COMMIT" "$temp_dir/blesh"
    git -C "$temp_dir/blesh" submodule --quiet update --init --recursive --depth 1
    make -C "$temp_dir/blesh" install PREFIX="$BLESH_PREFIX" >/dev/null
fi

# O ble.sh precisa de uma linha no começo do ~/.bashrc e outra no fim.
if grep -qs 'blesh/ble.sh' "$BASHRC"; then
    info "$BASHRC já carrega o ble.sh"
else
    if [ -f "$BASHRC" ]; then
        backup="$BASHRC.bak.$(date +%Y%m%d-%H%M%S)"
        cp -p "$BASHRC" "$backup"
        info "$BASHRC antigo salvo em $backup"
    fi
    {
        echo '# ble.sh: autocomplete de comandos enquanto digita (primeira parte; a segunda fica no fim do arquivo)'
        echo '[[ $- == *i* ]] && source -- ~/.local/share/blesh/ble.sh --attach=none'
        echo
        [ -f "$BASHRC" ] && cat "$BASHRC"
        echo
        echo '# ble.sh: ativa depois que todo o resto do ~/.bashrc carregou (manter no fim do arquivo)'
        echo '[[ ! ${BLE_VERSION-} ]] || ble-attach'
    } > "$temp_dir/bashrc"
    cat "$temp_dir/bashrc" > "$BASHRC"   # cat em vez de mv: preserva permissões e link, se houver
    info "ble.sh adicionado ao $BASHRC"
fi

# --- 8. Perfil do GNOME Terminal (cores e fonte do terminal) ---
PROFILES="org.gnome.Terminal.ProfilesList"
PROFILE_SCHEMA="org.gnome.Terminal.Legacy.Profile"
PROFILE_PATH="/org/gnome/terminal/legacy/profiles:"
profile_set() { gsettings set "$PROFILE_SCHEMA:$PROFILE_PATH/:$1/" "$2" "$3"; }

if ! command -v gsettings >/dev/null 2>&1 || ! gsettings list-schemas | grep -x "$PROFILES" >/dev/null; then
    info "GNOME Terminal não encontrado: perfil de cores não criado"
else
    profile_id=""
    for id in $(gsettings get "$PROFILES" list | grep -oE '[0-9a-f-]{36}' || true); do
        name="$(gsettings get "$PROFILE_SCHEMA:$PROFILE_PATH/:$id/" visible-name)"
        [ "$name" = "'$PROFILE_NAME'" ] && profile_id="$id"
    done

    if [ -n "$profile_id" ]; then
        info "Perfil '$PROFILE_NAME' do GNOME Terminal já existe"
    else
        profile_id="$(cat /proc/sys/kernel/random/uuid)"
        profile_set "$profile_id" visible-name "$PROFILE_NAME"
        profile_set "$profile_id" use-theme-colors false
        profile_set "$profile_id" background-color '#1e1e2e'
        profile_set "$profile_id" foreground-color '#cdd6f4'
        profile_set "$profile_id" bold-color-same-as-fg true
        profile_set "$profile_id" cursor-colors-set true
        profile_set "$profile_id" cursor-background-color '#f5e0dc'
        profile_set "$profile_id" cursor-foreground-color '#1e1e2e'
        profile_set "$profile_id" highlight-colors-set true
        profile_set "$profile_id" highlight-background-color '#585b70'
        profile_set "$profile_id" highlight-foreground-color '#cdd6f4'
        profile_set "$profile_id" palette "['#45475a', '#f38ba8', '#a6e3a1', '#f9e2af', '#89b4fa', '#f5c2e7', '#94e2d5', '#bac2de', '#585b70', '#f38ba8', '#a6e3a1', '#f9e2af', '#89b4fa', '#f5c2e7', '#94e2d5', '#a6adc8']"
        if has_font; then
            profile_set "$profile_id" use-system-font false
            profile_set "$profile_id" font "$PROFILE_FONT_FAMILY $PROFILE_FONT_SIZE"
        fi

        # Acrescenta à lista de perfis e deixa como padrão (os perfis existentes não mudam).
        old_list="$(gsettings get "$PROFILES" list)"
        case "$old_list" in
            *"'"*) new_list="${old_list%]}, '$profile_id']" ;;
            *)     new_list="['$profile_id']" ;;
        esac
        gsettings set "$PROFILES" list "$new_list"
        gsettings set "$PROFILES" default "$profile_id"
        info "Perfil '$PROFILE_NAME' criado no GNOME Terminal e definido como padrão"
        info "Vale para janelas novas do terminal; nas abertas, troque em Terminal > Alterar perfil"
    fi
fi

info "Pronto! Abra o tmux com 'tmux' (sessões já abertas foram recarregadas)."
info "Os autocompletes valem a partir do próximo terminal aberto."

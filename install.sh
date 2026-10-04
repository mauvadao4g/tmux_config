#!/usr/bin/env bash
# Instala e configura o tmux do zero: pacotes, ~/.tmux.conf, TPM, plugins, fonte Hack Nerd
# Font, tema Catppuccin Mocha (barra do tmux e perfil do GNOME Terminal) e autocomplete
# do comando tmux. O ble.sh (autocomplete de qualquer comando enquanto se digita) é opcional.
# Pode ser executado quantas vezes quiser (não refaz o que já está pronto).
#
# Uso:
#   ./install.sh            instala tudo, menos o ble.sh
#   ./install.sh --blesh    instala também o ble.sh (as opções podem ser combinadas)
#   ./install.sh --dev      instala também ferramentas de terminal: ripgrep, fd, bat, zoxide e delta
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
# As cores vêm do temas.sh, que também serve para trocar de tema depois.
THEMES_SCRIPT="$REPO_DIR/temas.sh"
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

# Scripts chamados pelo tmux.conf (ver bin/) e o lazygit, usado pelo Ctrl+b g.
BIN_DIR="$HOME/.local/bin"
PROJECTS_SRC="$REPO_DIR/bin/tmux-projetos"
PROJECTS_DST="$BIN_DIR/tmux-projetos"
# No Linux o lazygit vem do GitHub (poucas distros o empacotam); o sha256 confere o
# download. Ao trocar a versão, troque também os dois sha256 (estão no checksums.txt dela).
LAZYGIT_VERSION="0.65.1"
LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/v$LAZYGIT_VERSION"
LAZYGIT_SHA256_X86_64="02beacbcda0fa342e50ae3480ba8147307353af3fb28e1d5f790e02329c201a6"
LAZYGIT_SHA256_ARM64="49abecdf6adf4f2dfdb11bf7b9bfada267ea523612ed809d1c6d87f6c04000a7"

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
# Também fixado em um commit, pelo mesmo motivo. Só é instalado com --blesh.
BLESH_REPO="https://github.com/akinomyoga/ble.sh"
BLESH_COMMIT="d81fd54feb0d996fdff20dca27eaf0201f7015cc"
BLESH_PREFIX="$HOME/.local"
BLESH_DST="$BLESH_PREFIX/share/blesh/ble.sh"
BASHRC="$HOME/.bashrc"

info() { printf '\033[1;35m>>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,12s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }

UPDATE=0
BLESH=0
DEV=0
for arg in "$@"; do
    case "$arg" in
        -u|--update) UPDATE=1 ;;
        -b|--blesh)  BLESH=1 ;;
        -d|--dev)    DEV=1 ;;
        -h|--help)   usage; exit 0 ;;
        *)           usage; die "Opção desconhecida: $arg" ;;
    esac
done

[ -f "$CONF_SRC" ] || die "Não achei $CONF_SRC"

# Instala pacotes com o gerenciador do sistema: pkg_install <pacote>...
pkg_install() {
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y "$@"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$@"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "$@"
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "$@"
    elif command -v brew >/dev/null 2>&1; then
        brew install "$@"
    else
        die "Gerenciador de pacotes não reconhecido. Instale manualmente: $*"
    fi
}

# O lazygit baixado pelo script fica em $BIN_DIR, que pode não estar no PATH.
has_lazygit() { command -v lazygit >/dev/null 2>&1 || [ -x "$BIN_DIR/lazygit" ]; }

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
command -v fzf  >/dev/null 2>&1 || packages+=(fzf)      # busca de janelas e de projetos
command -v python3 >/dev/null 2>&1 || packages+=(python3)   # plugin extrakto (Ctrl+b e)
if [ -n "$clip_cmd" ] && ! command -v "$clip_cmd" >/dev/null 2>&1; then
    packages+=("$clip_pkg")
fi
if [ "$BLESH" -eq 1 ] && { [ ! -f "$BLESH_DST" ] || [ "$UPDATE" -eq 1 ]; }; then   # só para compilar o ble.sh
    command -v gawk >/dev/null 2>&1 || packages+=(gawk)
    command -v make >/dev/null 2>&1 || packages+=(make)
fi
if ! has_font; then                                     # só para baixar a fonte
    command -v curl  >/dev/null 2>&1 || packages+=(curl)
    command -v unzip >/dev/null 2>&1 || packages+=(unzip)
fi
if ! has_lazygit; then
    if [ "$(uname)" = "Darwin" ]; then
        packages+=(lazygit)
    else                                                # só para baixar o lazygit
        command -v curl >/dev/null 2>&1 || [[ " ${packages[*]} " == *" curl "* ]] || packages+=(curl)
    fi
fi

if [ ${#packages[@]} -gt 0 ]; then
    info "Instalando pacotes: ${packages[*]}"
    pkg_install "${packages[@]}"
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

# Script do Ctrl+b f (abrir projeto): o tmux.conf o chama por este caminho.
mkdir -p "$BIN_DIR"
ln -sfn "$PROJECTS_SRC" "$PROJECTS_DST"

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

# --- 6. lazygit (git flutuante do Ctrl+b g) ---
if command -v lazygit >/dev/null 2>&1 && [ ! -x "$BIN_DIR/lazygit" ]; then
    info "lazygit já instalado pelo sistema"
elif [ -x "$BIN_DIR/lazygit" ] && [ "$UPDATE" -eq 0 ]; then
    info "lazygit já instalado"
else
    case "$(uname -m)" in
        x86_64)        lazygit_arch="x86_64" lazygit_sha256="$LAZYGIT_SHA256_X86_64" ;;
        aarch64|arm64) lazygit_arch="arm64"  lazygit_sha256="$LAZYGIT_SHA256_ARM64" ;;
        *)             lazygit_arch="" ;;
    esac
    if [ -z "$lazygit_arch" ]; then
        warn "Sem lazygit pronto para $(uname -m); instale manualmente para usar o Ctrl+b g."
    else
        info "Baixando o lazygit ($LAZYGIT_VERSION)"
        curl -fsSL -o "$temp_dir/lazygit.tar.gz" \
            "$LAZYGIT_URL/lazygit_${LAZYGIT_VERSION}_linux_${lazygit_arch}.tar.gz"
        if command -v sha256sum >/dev/null 2>&1; then
            echo "$lazygit_sha256  $temp_dir/lazygit.tar.gz" | sha256sum -c --quiet - \
                || die "O arquivo do lazygit não confere com o sha256 esperado"
        fi
        tar -xzf "$temp_dir/lazygit.tar.gz" -C "$temp_dir" lazygit
        install -m 755 "$temp_dir/lazygit" "$BIN_DIR/lazygit"
    fi
fi

# --- 7. Autocomplete do comando tmux no bash ---
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

# --- 8. ble.sh: autocomplete de comandos enquanto se digita (opcional, com --blesh) ---
if [ "$BLESH" -eq 0 ]; then
    info "ble.sh não instalado (use --blesh para instalar)"
else
    if [ -f "$BLESH_DST" ] && [ "$UPDATE" -eq 0 ]; then
        info "ble.sh já instalado"
    else
        info "Instalando o ble.sh"
        fetch_commit "$BLESH_REPO" "$BLESH_COMMIT" "$temp_dir/blesh"
        git -C "$temp_dir/blesh" submodule --quiet update --init --recursive --depth 1
        make -C "$temp_dir/blesh" install PREFIX="$BLESH_PREFIX" >/dev/null
    fi

    # O ble.sh precisa de uma linha no começo do ~/.bashrc e outra no fim.
    # (linhas comentadas não contam: quem desativou na mão pode reativar com --blesh)
    if grep -qs '^[^#]*blesh/ble\.sh' "$BASHRC"; then
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
fi

# --- 9. Ferramentas de terminal para programar (opcional, com --dev) ---
if [ "$DEV" -eq 1 ]; then
    # No apt e no dnf o pacote do fd se chama fd-find.
    if command -v apt-get >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        fd_pkg="fd-find"
    else
        fd_pkg="fd"
    fi
    dev_packages=()
    command -v rg >/dev/null 2>&1 || dev_packages+=(ripgrep)
    command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1 || dev_packages+=("$fd_pkg")
    command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1 || dev_packages+=(bat)
    command -v zoxide >/dev/null 2>&1 || dev_packages+=(zoxide)
    command -v delta  >/dev/null 2>&1 || dev_packages+=(git-delta)

    if [ ${#dev_packages[@]} -eq 0 ]; then
        info "Ferramentas de terminal já instaladas"
    else
        info "Instalando ferramentas de terminal: ${dev_packages[*]}"
        pkg_install "${dev_packages[@]}" \
            || warn "Não consegui instalar todas; veja a mensagem acima e instale as que faltaram."
    fi

    # O Debian/Ubuntu instala o fd como fdfind e o bat como batcat: cria os nomes usuais.
    for pair in "fdfind:fd" "batcat:bat"; do
        if ! command -v "${pair#*:}" >/dev/null 2>&1 && command -v "${pair%:*}" >/dev/null 2>&1; then
            ln -sfn "$(command -v "${pair%:*}")" "$BIN_DIR/${pair#*:}"
        fi
    done
    info "zoxide e delta precisam ser ativados; veja 'Ferramentas de terminal' no README."
fi

# --- 10. Perfil do GNOME Terminal (cores e fonte do terminal) ---
# Só cria na primeira vez; depois, o tema do terminal é trocado com o temas.sh.
PROFILES="org.gnome.Terminal.ProfilesList"
PROFILE_SCHEMA="org.gnome.Terminal.Legacy.Profile"
PROFILE_PATH="/org/gnome/terminal/legacy/profiles:"

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
        PROFILE_FONT_FAMILY="$PROFILE_FONT_FAMILY" PROFILE_FONT_SIZE="$PROFILE_FONT_SIZE" \
            "$THEMES_SCRIPT" "$PROFILE_NAME"
    fi
fi

info "Pronto! Abra o tmux com 'tmux' (sessões já abertas foram recarregadas)."
info "Os autocompletes valem a partir do próximo terminal aberto."
info "Para trocar as cores do terminal, rode ./temas.sh"

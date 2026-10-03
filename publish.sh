#!/usr/bin/env bash
# Publica este repositório no GitHub: cria o repositório remoto na primeira vez,
# faz o commit do que mudou e envia (push).
#
# Uso:
#   ./publish.sh                     commit com mensagem padrão e push
#   ./publish.sh "minha mensagem"    commit com a mensagem dada e push
#   ./publish.sh --public            cria o repositório como público (o padrão é privado)
#   ./publish.sh --help              mostra esta ajuda
#
# A opção --public só vale na criação; depois, mude a visibilidade com:
#   gh repo edit --visibility public --accept-visibility-change-consequences
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_NAME="$(basename "$REPO_DIR")"
README="$REPO_DIR/README.md"
URL_PLACEHOLDER="<url-deste-repositorio>"   # trocado pela URL real no README na primeira publicação

info() { printf '\033[1;35m>>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,11s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }

VISIBILITY="--private"
MESSAGE=""
for arg in "$@"; do
    case "$arg" in
        --public)  VISIBILITY="--public" ;;
        -h|--help) usage; exit 0 ;;
        -*)        usage; die "Opção desconhecida: $arg" ;;
        *)         MESSAGE="$arg" ;;
    esac
done

command -v git >/dev/null 2>&1 || die "git não encontrado"
command -v gh  >/dev/null 2>&1 || die "gh (GitHub CLI) não encontrado: https://cli.github.com"
gh auth status >/dev/null 2>&1 || die "Faça login no GitHub primeiro: gh auth login"

cd "$REPO_DIR"

# --- 1. Repositório local ---
if [ ! -d .git ]; then
    info "Criando o repositório git local"
    git init -q -b main
fi

# O commit precisa de nome e e-mail; se faltarem, usa os da conta do GitHub (só neste repositório).
login="$(gh api user --jq .login)"
if [ -z "$(git config user.name || true)" ]; then
    git config user.name "$(gh api user --jq '.name // .login')"
fi
if [ -z "$(git config user.email || true)" ]; then
    git config user.email "$(gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"')"
fi

# --- 2. Repositório no GitHub ---
if git remote get-url origin >/dev/null 2>&1; then
    info "Remoto: $(git remote get-url origin)"
elif gh repo view "$login/$REPO_NAME" >/dev/null 2>&1; then
    git remote add origin "https://github.com/$login/$REPO_NAME.git"
    info "Remoto já existia no GitHub: $(git remote get-url origin)"
else
    info "Criando $login/$REPO_NAME no GitHub (${VISIBILITY#--})"
    gh repo create "$login/$REPO_NAME" "$VISIBILITY" --source . --remote origin \
        --description "Configuração do tmux com instalação automática"
fi

# --- 3. URL de clone no README ---
url="$(git remote get-url origin)"
if [ -f "$README" ] && grep -F "$URL_PLACEHOLDER" "$README" >/dev/null; then
    sed -i.tmp "s|$URL_PLACEHOLDER|$url|" "$README" && rm -f "$README.tmp"
    info "README atualizado com a URL de clone"
fi

# --- 4. Commit e push ---
git add -A
if git diff --cached --quiet; then
    info "Nada novo para o commit"
else
    git commit -q -m "${MESSAGE:-Atualiza a configuração do tmux ($(date +%d/%m/%Y))}"
    info "Commit: $(git log -1 --format='%h %s')"
fi

git push -q -u origin "$(git branch --show-current)"
info "Publicado: ${url%.git}"

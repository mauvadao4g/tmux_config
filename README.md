# tmux_config

Minha configuração do [tmux](https://github.com/tmux/tmux): focada em teclado, com atalhos no estilo vim e tema [Catppuccin Mocha](https://catppuccin.com) na barra do tmux e no terminal. Um único script instala e configura tudo.

## O que é o tmux

O tmux é um *multiplexador de terminal*: ele roda dentro do terminal e permite ter vários terminais em uma só janela, além de manter tudo rodando mesmo depois de fechar o terminal ou cair a conexão SSH.

Ele se organiza em três níveis:

| Nível | O que é |
|---|---|
| **Sessão** | Um conjunto de janelas. Continua viva em segundo plano quando você sai dela (*detach*) e pode ser retomada depois (*attach*). |
| **Janela** | Uma "aba" dentro da sessão. Aparece na barra de status, embaixo. |
| **Painel** | Uma divisão da janela. Cada painel é um terminal independente. |

Quase todo atalho começa pelo **prefixo**, que aqui é `Ctrl+b`: aperte `Ctrl+b`, solte, e então aperte a tecla do comando.

## Instalação

```bash
git clone <url-deste-repositorio> tmux_config
cd tmux_config
./install.sh
```

O script pode ser executado quantas vezes quiser. Ele:

1. instala os pacotes que faltarem, usando `apt`, `dnf`, `pacman`, `zypper` ou `brew`: `tmux`, `git`, `fzf`, a ferramenta de clipboard (`xclip` no X11, `wl-clipboard` no Wayland), `gawk` e `make` (para compilar o ble.sh), `curl` e `unzip` (para baixar a fonte);
2. guarda o `~/.tmux.conf` atual em `~/.tmux.conf.bak.<data>` e cria um link de `~/.tmux.conf` para o `tmux.conf` deste repositório;
3. baixa o [TPM](https://github.com/tmux-plugins/tpm), o gerenciador de plugins, e o tema da barra;
4. instala os plugins e recarrega a config nas sessões abertas;
5. baixa a fonte [Hack Nerd Font](https://www.nerdfonts.com) para `~/.local/share/fonts/HackNerdFont`, se ela ainda não estiver instalada;
6. instala o autocomplete do comando `tmux` e dos atalhos `ta`, `tk` e `t` em `~/.local/share/bash-completion/completions/` (vale a partir do próximo terminal aberto);
7. instala o [ble.sh](https://github.com/akinomyoga/ble.sh) em `~/.local/share/blesh` e adiciona duas linhas ao `~/.bashrc` (uma no começo, uma no fim), guardando o original em `~/.bashrc.bak.<data>`;
8. cria no GNOME Terminal o perfil `Catppuccin Mocha` (cores e fonte `Hack Nerd Font Mono 16`) e o define como padrão, sem alterar os perfis que já existem.

Para também atualizar os plugins já instalados e reinstalar o tema e os autocompletes:

```bash
./install.sh --update
```

Requisito: tmux 3.2 ou mais novo (o script avisa se o instalado for mais antigo).

## Comandos básicos

| Comando | Ação |
|---|---|
| `tmux` | abre uma sessão nova |
| `tmux new -s nome` | abre uma sessão com nome |
| `tmux ls` | lista as sessões |
| `tmux attach -t nome` | volta para uma sessão |
| `tmux kill-session -t nome` | encerra uma sessão |
| `tmux kill-server` | encerra todas as sessões |

### Autocomplete

**Do comando `tmux`.** No shell, `Tab` completa os subcomandos e os nomes das sessões:

```bash
tmux att<Tab>            # completa para attach-session
tmux attach -t <Tab>     # lista as sessões abertas
```

Dentro do tmux, o prompt de comandos (`prefixo` `:`) também completa com `Tab`.

**Dos atalhos `ta`, `tk` e `t`.** Se você tiver no `~/.bashrc` atalhos com esses nomes que recebem o nome de uma sessão, o `Tab` completa as sessões abertas. O script não cria os atalhos, só o autocomplete deles; um exemplo de definição:

```bash
alias ta='tmux attach -t'                       # ta nome -> volta para a sessão
alias tk='tmux kill-session -t'                 # tk nome -> encerra a sessão
t() { tmux new-session -A -s "${1:-main}"; }    # t nome  -> entra na sessão, criando se não existir
```

**De qualquer comando, enquanto digita.** O ble.sh dá ao bash um autocomplete parecido com o de um editor:

| Tecla | Ação |
|---|---|
| (digitando) | aparece em cinza a sugestão do resto do comando, tirada do histórico |
| `→` ou `End` | aceita a sugestão inteira |
| `Alt+f` | aceita só a próxima palavra da sugestão |
| `Tab` | abre o menu com as opções (comandos, arquivos, flags); `Tab` e as setas navegam |

A linha de comando também ganha cores: um comando que não existe fica vermelho antes do `Enter`.

## Atalhos

`prefixo` = `Ctrl+b`.

### Sessões e janelas

| Atalho | Ação |
|---|---|
| `prefixo` `d` | sai da sessão, deixando ela rodando |
| `prefixo` `s` | lista e troca de sessão |
| `prefixo` `F` | busca uma janela de qualquer sessão pelo nome ou pela pasta e vai até ela |
| `prefixo` `$` | renomeia a sessão |
| `prefixo` `c` | nova janela, na mesma pasta |
| `prefixo` `,` | renomeia a janela |
| `prefixo` `n` / `p` | próxima janela / janela anterior |
| `Alt+1` … `Alt+9` | vai direto para a janela, sem prefixo |
| `prefixo` `&` | fecha a janela |

### Painéis

| Atalho | Ação |
|---|---|
| `prefixo` `\|` | divide lado a lado, na mesma pasta |
| `prefixo` `-` | divide em cima e embaixo, na mesma pasta |
| `Alt+h` `j` `k` `l` | muda de painel, sem prefixo (esquerda, baixo, cima, direita) |
| `Alt+\` | volta para o painel anterior, sem prefixo |
| `prefixo` `h` `j` `k` `l` | muda de painel |
| `Alt+setas` | muda de painel, sem prefixo |
| `prefixo` `H` `J` `K` `L` | redimensiona o painel (pode repetir a tecla) |
| `prefixo` `Shift+setas` | redimensiona o painel (pode repetir a tecla) |
| `prefixo` `z` | alterna o painel em tela cheia |
| `prefixo` `t` | abre um terminal flutuante na pasta atual (`exit` ou `Ctrl+d` fecha) |
| `prefixo` `S` | liga/desliga a digitação em todos os painéis da janela ao mesmo tempo (aparece `SYNC` em vermelho na barra) |
| `prefixo` `x` | fecha o painel |

### Modo cópia (estilo vim)

| Atalho | Ação |
|---|---|
| `prefixo` `[` | entra no modo cópia |
| `prefixo` `/` | entra no modo cópia já com a busca aberta (para trás no histórico) |
| `h` `j` `k` `l`, `w`, `b`, `gg`, `G` | movimenta, como no vim |
| `/` e `?` | busca para frente e para trás (`n` / `N` repetem) |
| `v` | começa a seleção |
| `Ctrl+v` | alterna a seleção em bloco |
| `y` | copia para a área de transferência do sistema e sai |
| `q` | sai sem copiar |
| `prefixo` `]` | cola o que foi copiado |

### Outros

| Atalho | Ação |
|---|---|
| `prefixo` `r` | recarrega o `~/.tmux.conf` |
| `prefixo` `Ctrl+s` | salva as sessões agora |
| `prefixo` `Ctrl+r` | restaura as sessões salvas |
| `prefixo` `:` | abre o prompt de comandos do tmux |
| `prefixo` `?` | lista todos os atalhos |
| `prefixo` `I` | instala plugins novos |
| `prefixo` `U` | atualiza plugins |

Duas diferenças em relação ao tmux padrão: `prefixo` `l` vai para o painel da direita, em vez de voltar para a última janela, e `prefixo` `t` abre o terminal flutuante, em vez de mostrar o relógio.

A navegação sem prefixo usa `Alt` em vez de `Ctrl` para deixar livres os atalhos do shell (`Ctrl+h` apaga caractere, `Ctrl+k` apaga até o fim da linha, `Ctrl+l` limpa a tela, `Ctrl+j` confirma).

## Plugins

| Plugin | Para que serve |
|---|---|
| [tpm](https://github.com/tmux-plugins/tpm) | gerencia os outros plugins |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | `Alt+h/j/k/l` navega entre painéis do tmux e splits do vim |
| [tmux-yank](https://github.com/tmux-plugins/tmux-yank) | copia do modo cópia para a área de transferência do sistema |
| [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu) | números de CPU e RAM da barra de status |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | salva e restaura sessões, janelas, painéis e pastas |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | salva sozinho a cada 15 minutos e restaura ao abrir o tmux |

Fora do TPM, o `install.sh` também instala o tema [catppuccin/tmux](https://github.com/catppuccin/tmux) (numa versão fixa, definida no topo do script), o [tmux-bash-completion](https://github.com/imomaliev/tmux-bash-completion), que dá o autocomplete do comando `tmux` no bash, e o [ble.sh](https://github.com/akinomyoga/ble.sh), que dá as sugestões enquanto se digita. Esses dois ficam fixados em um commit no topo do `install.sh`; para pegar uma versão mais nova, troque o hash e rode `./install.sh --update`.

Para adicionar um plugin, inclua uma linha `set -g @plugin 'autor/nome'` no `tmux.conf`, antes da linha do TPM no final, e aperte `prefixo` `I`.

### Integração com o vim / neovim

Para o `Alt+h/j/k/l` atravessar também os splits de dentro do editor, instale o mesmo plugin nele e aponte os atalhos para `Alt`, já que o padrão do plugin é `Ctrl`.

Com [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "christoomey/vim-tmux-navigator",
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  keys = {
    { "<M-h>", "<cmd>TmuxNavigateLeft<cr>" },
    { "<M-j>", "<cmd>TmuxNavigateDown<cr>" },
    { "<M-k>", "<cmd>TmuxNavigateUp<cr>" },
    { "<M-l>", "<cmd>TmuxNavigateRight<cr>" },
    { "<M-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
  },
}
```

Com [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'christoomey/vim-tmux-navigator'

let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <M-h> :<C-U>TmuxNavigateLeft<cr>
nnoremap <silent> <M-j> :<C-U>TmuxNavigateDown<cr>
nnoremap <silent> <M-k> :<C-U>TmuxNavigateUp<cr>
nnoremap <silent> <M-l> :<C-U>TmuxNavigateRight<cr>
nnoremap <silent> <M-\> :<C-U>TmuxNavigatePrevious<cr>
```

## Sessões que sobrevivem a reiniciar

O tmux salva sozinho, a cada 15 minutos, as sessões, janelas, painéis, pastas e o texto que estava em cada painel. Depois de reiniciar o computador, basta abrir o `tmux`: tudo volta como estava.

- `prefixo` `Ctrl+s` salva na hora, sem esperar os 15 minutos.
- `prefixo` `Ctrl+r` restaura manualmente.
- Os programas que estavam rodando não voltam, com exceção de alguns simples (`vi`, `vim`, `nvim`, `man`, `less`, `tail`, `top`, `htop`). O nvim só reabre os arquivos se houver um `Session.vim` na pasta.
- Para abrir o tmux sem restaurar, crie o arquivo `~/tmux_no_auto_restore`.
- Os salvamentos ficam em `~/.local/share/tmux/resurrect`.

## Tema

O tema é o Catppuccin Mocha, aplicado em dois lugares.

### Barra do tmux

Mostra o nome da sessão à esquerda e uso de CPU, uso de RAM e data/hora à direita. É controlada pelas opções `@catppuccin_*` e pelas linhas `status-left` / `status-right` do `tmux.conf`:

| Opção | Efeito |
|---|---|
| `@catppuccin_flavor` | variação das cores: `mocha` (a mais escura), `macchiato`, `frappe` ou `latte` (clara) |
| `@catppuccin_window_status_style` | formato das abas de janela: `rounded`, `basic`, `slanted` ou `none` |
| `@catppuccin_window_text` | texto de cada aba (`#W` é o nome da janela) |
| `@catppuccin_date_time_text` | formato da data/hora, na sintaxe do `date` |
| linhas `status-right` | blocos da direita, na ordem. Outros disponíveis: `battery`, `directory`, `host`, `uptime`, `user`, `application`, `load` |

A lista completa está na [documentação do tema](https://github.com/catppuccin/tmux/tree/main/docs).

### Terminal (GNOME Terminal)

As cores de fundo, do texto e a fonte são do terminal, não do tmux. O `install.sh` cria o perfil `Catppuccin Mocha` e o deixa como padrão; ele vale para as janelas abertas depois disso. Numa janela já aberta, troque pelo menu **Terminal > Alterar perfil**.

Para voltar ao perfil antigo ou mudar o tamanho da fonte, use **Preferências** no menu do GNOME Terminal. Em outros terminais (Alacritty, Kitty, etc.), o tema está disponível em [catppuccin.com/ports](https://catppuccin.com/ports).

## Personalização

Como `~/.tmux.conf` é um link, basta editar o `tmux.conf` deste repositório e recarregar com `prefixo` `r`.

## Problemas comuns

| Sintoma | Solução |
|---|---|
| Quadradinhos no lugar dos ícones da barra | use o perfil `Catppuccin Mocha` do terminal, ou escolha a `Hack Nerd Font Mono` no seu perfil |
| Cores lavadas ou erradas | confira se o terminal suporta *true color* e se `echo $TERM` fora do tmux mostra `xterm-256color` |
| Tema ou atalhos dos plugins não aparecem | aperte `prefixo` `I` para instalar os plugins e depois `prefixo` `r` |
| `y` não copia para o sistema | instale `xclip` (X11) ou `wl-clipboard` (Wayland) |

## Desinstalação

```bash
rm ~/.tmux.conf                                  # remove o link
mv ~/.tmux.conf.bak.<data> ~/.tmux.conf          # restaura a config antiga, se houver
rm -rf ~/.tmux/plugins                           # remove o TPM e os plugins
cd ~/.local/share/bash-completion/completions && rm tmux ta tk t   # remove os autocompletes
rm -rf ~/.local/share/blesh                      # remove o ble.sh
tmux kill-server                                 # encerra as sessões para limpar a config carregada
```

Depois, apague do `~/.bashrc` as duas linhas marcadas com o comentário `ble.sh` (a primeira e a última do arquivo).

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `tmux.conf` | a configuração |
| `install.sh` | instalação e configuração automáticas |
| `completions/tmux-sessions` | autocomplete de nomes de sessão para os atalhos `ta`, `tk` e `t` |

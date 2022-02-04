# arm優先のための設定
typeset -U path PATH
path=(
  /opt/homebrew/bin(N-/)
  /opt/homebrew/sbin(N-/)
  /usr/bin
  /usr/sbin
  /bin
  /sbin
  /usr/local/bin(N-/)
  /usr/local/sbin(N-/)
  /Library/Apple/usr/bin
)

plugins=(
  zsh-autosuggestions
)
# NOTE(okubo): autosuggestionsで必要
autoload -U compinit && compinit
# NOTE(okubo): 色を有効化
autoload -Uz colors && colors

# NOTE(okubo): プロンプトカスタマイズ
PROMPT='
[%B%F{green}%n@%m%f%b %F{cyan}($(arch))%f:%F{blue}%~%f]$vcs_info_msg_0_%f'
PROMPT+=""$'\n'"%# "
precmd(){ vcs_info }

export PATH="/usr/local/Cellar/git/2.5.0/bin:$PATH"

alias ide="~/.ide.sh"
alias t="arch -arm64 tmux"
alias tk="tmux kill-server"
alias arm="arch -arm64 zsh"

alias gc="git checkout"
alias gp="git push"
alias gf="git fetch"

# dockerとlocalのpsgl行き来するため
alias psglstart="brew services start postgresql"
alias psglstop="brew services stop postgresql"
alias mystart="mysql.server restart"

alias ctags="ctags -R -f .tags"

# rails系コマンド
alias bi="bundle install"
alias rs="rails s"
alias rc="rails c"
alias rubo="bundle exec rubocop"
alias haml="bundle exec haml-lint app/views/"
alias best="bundle exec rails_best_practices -e node_modules"

alias rsp="bundle exec rspec"
alias rw="bin/webpack-dev-server"

# yarn/npmコマンド
alias ys="yarn start"
alias yi="yarn install"
alias nr="npm run start"
alias ni="npm install"

# docker系コマンド
alias d="docker-compose"
alias dcu="docker-compose up"
alias dcb="docker-compose build --no-cache"

# heroku系コマンド
alias hi="heroku login"
alias hr="heroku run"

alias ctags="`brew --prefix`/bin/ctags"

# git設定
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'

# nvim
alias vim='nvim'
alias vi='nvim'

# M1の場合はこちららしい
export PATH="/opt/homebrew/bin:$PATH"

# Settings for fzf
export PATH="$PATH:$HOME/.fzf/bin"
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'

export FZF_DEFAULT_OPTS="--height 50% --layout=reverse --border --inline-info --preview 'head -100 {}'"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# pythonの設定
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# zlib, pyenv入れる際の問題解消で挿入
# export LDFLAGS="-L/usr/local/opt/zlib/lib"
# export CPPFLAGS="-I/usr/local/opt/zlib/include"

# tesserocrをinstallする際の回避策
# export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

# gitの設定
# PATH="/usr/local/git/bin:$PATH"
# export PATH

# posgreの設定
export PGDATA=/usr/local/var/postgres
export PATH=/usr/local/opt/postgresql/bin:$PATH

# nodeの設定
export NODE_PATH='/usr/local/lib/node_modules'
export PATH=~/.npm-global/bin:$PATH

# androidの設定
export ANDROID_SDK=/Users/masahirookubo/Library/Android/sdk
export PATH=/Users/masahirookubo/Library/Android/sdk/platform-tools:$PATH

# flutter
# export PATH="/Users/masahirookubo/development/flutter/bin/:$PATH"

# go
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"
export GOPATH=$HOME/go;
export PATH=$PATH:$GOPATH/bin;

# terraform
export PATH="$HOME/.tfenv/bin:$PATH"

export PATH="$(brew --prefix openssl@1.1)/bin:$PATH"

export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

eval "$(rbenv init -)"

# NOTE: nvim + fzf.nvimのpreviewをいい感じにするための設定
export BAT_THEME="Dracula"


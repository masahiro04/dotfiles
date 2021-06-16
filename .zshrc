export PATH="/usr/local/Cellar/git/2.5.0/bin:$PATH"

alias ide="~/.ide.sh"

# git設定
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
# プロンプトカスタマイズ
PROMPT='
[%B%F{red}%n@%m%f%b:%F{green}%~%f]%F{cyan}$vcs_info_msg_0_%f
%F{yellow}$%f '
precmd(){ vcs_info }

# nvim
alias vim='nvim'

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
export LDFLAGS="-L/usr/local/opt/zlib/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include"

# tesserocrをinstallする際の回避策
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

# gitの設定
PATH="/usr/local/git/bin:$PATH"
export PATH

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
export PATH="/Users/masahirookubo/development/flutter/bin/:$PATH"

# go
export GOPATH=$HOME/go
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"

# dockerのため
export PATH="$PATH:/usr/local/bin"

# terraform
export PATH="$HOME/.tfenv/bin:$PATH"

# rbenv
[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"

# ctags
# alias ctags_ruby='ctags --langmap=RUBY:.rb --exclude="*.js" --exclude=".git*" --exclude="*.sql" --exclude="node_modules*" -R .'


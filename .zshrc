# NOTE: ターミナルをいい感じする機能なので削除しないこと
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# NOTE: ここまで

# 小杉さんの設定
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
# PROMPT='%n@%m %c'\$vcs_info_msg_0_' %# '
# プロンプトカスタマイズ
PROMPT='
[%B%F{red}%n@%m%f%b:%F{green}%~%f]%F{cyan}$vcs_info_msg_0_%f
%F{yellow}$%f '
precmd(){ vcs_info }

# # startshipを起動
# eval "$(starship init bash)"
# nvim
alias vim='nvim'

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
# export PATH="/Users/masahirookubo/development/flutter/bin/:$PATH"

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
# [[ -d ~/.rbenv  ]] && \
#   export PATH=${HOME}/.rbenv/bin:${PATH} && \
#   eval "$(rbenv init -)"
#

export PATH="$(brew --prefix openssl@1.1)/bin:$PATH"

export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

eval "$(rbenv init -)"

# NOTE: ターミナルをいい感じする機能なので削除しないこと
source /opt/homebrew/opt/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# NOTE: ここまで

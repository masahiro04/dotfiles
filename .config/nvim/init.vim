source ~/.vimrc

" file名の認識
autocmd BufNewFile,BufRead *.tsx let b:tsx_ext_found = 1
autocmd BufNewFile,BufRead *.tsx set filetype=typescript.tsx
autocmd BufNewFile,BufRead *.ts set filetype=typescript
autocmd BufNewFile,BufRead *.rs set filetype=rust
autocmd BufNewFile,BufRead *.rb set filetype=ruby
autocmd BufReadPost *.kt setlocal filetype=kotlin
autocmd BufNewFile,BufRead *.nim, set filetype=nim
autocmd BufNewFile,BufRead *.slim, set filetype=slim
autocmd BufNewFile,BufRead *.haml, set filetype=haml
autocmd BufNewFile,BufRead *.swift, set filetype=swift
autocmd BufNewFile,BufRead *.dart, set filetype=dart
autocmd BufNewFile,BufRead *.go, set filetype=go
autocmd BufNewFile,BufRead *.csv, set filetype=csv
autocmd BufRead,BufNewFile tsconfig.json set filetype=jsonc
autocmd BufRead,BufNewFile package.json set filetype=jsonc

"-------------------------------------------------------------------------------
" Cursor line
"-------------------------------------------------------------------------------
" 横線
set cursorline

if &term =~ "screen"
  autocmd BufEnter * if bufname("") !~ "^?[A-Za-z0-9?]*://" | silent! exe '!echo -n "\ek[`hostname`:`basename $PWD`/`basename %`]\e\\"' | endif
  autocmd VimLeave * silent!  exe '!echo -n "\ek[`hostname`:`basename $PWD`]\e\\"'
endif
"-------------------------------------------------------------------------------
" Dein
"-------------------------------------------------------------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

let s:dein_dir = expand('~/.cache/dein')
let g:dein#install_github_api_token = 'GITHUB_API_TOKEN'

" プラグインリストを収めた TOML ファイル
" 予め TOML ファイル（後述）を用意しておく
let g:rc_dir         = expand('~/.config/plugins')
let g:dein_toml      = g:rc_dir . '/dein.toml'
let g:dein_lazy_toml = g:rc_dir . '/dein_lazy.toml'

" Required:
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir, [$MYVIMRC, g:dein_toml, g:dein_lazy_toml])

  call dein#load_toml(g:dein_toml,      {'lazy': 0})
  call dein#load_toml(g:dein_lazy_toml, {'lazy': 1})

  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif
"-------------------------------------------------------------------------------
" Color scheme
"-------------------------------------------------------------------------------
" deinの後でないとpluginが効かない
syntax enable
set t_Co=256
set background=dark
colorscheme tokyonight
" ハイライトの色変更, deinの後でないと適用されない
hi Search ctermfg=255 ctermbg=160

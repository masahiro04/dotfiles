"-------------------------------------------------------------------------------
" basic 
"-------------------------------------------------------------------------------
" シェルを指定してください
set shell=/bin/zsh

" encoding
set encoding=utf8
scriptencoding utf8
set fileencoding=utf-8
set termencoding=utf8
set fileencodings=utf-8,ucs-boms,euc-jp,ep932
set fileformats=unix,dos,mac
set ambiwidth=double
set nobomb
set t_Co=256

" スワップファイルの作成先を変更
set noswapfile

" ヤンクをクリップボードへ繋ぐ
set clipboard=unnamed

" ビープ音を消す
set belloff=all

" 行番号系
" set number

" タイトル系
set title

" インデント系
filetype plugin indent on
set expandtab
set tabstop=2
set softtabstop=2
set autoindent
set smartindent
set shiftwidth=2
au FileType go setlocal sw=4 ts=4 sts=4 noet
set list listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

" 挿入モードでバックスペース削除を有効
set backspace=indent,eol,start

" 検索するときに大文字小文字を区別しない
set ignorecase

" 検索した時にハイライト
set hlsearch

"-------------------------------------------------------------------------------
" キーバインド
"-------------------------------------------------------------------------------
" xで削除した時はヤンクしない
vnoremap x "_x
nnoremap x "_x

" 括弧の補完
inoremap {<Enter> {}<Left><CR><ESC><S-o>
inoremap [<Enter> []<Left><CR><ESC><S-o>
inoremap (<Enter> ()<Left><CR><ESC><S-o>

" クオーテーションの補完
inoremap ' ''<LEFT>
inoremap " ""<LEFT>

" 画面分割系
nnoremap sj <C-w>j
nnoremap sk <C-w>k
nnoremap sl <C-w>l
nnoremap sh <C-w>h
nnoremap ss :<C-u>sp<CR><C-w>j
nnoremap sv :<C-u>vs<CR><C-w>l


" jj
inoremap <silent> jj <ESC>

"-------------------------------------------------------------------------------
" Cursor line
"-------------------------------------------------------------------------------

set cursorline

" Set cursor line color on visual mode
highlight Visual cterm=NONE ctermbg=236 ctermfg=NONE guibg=Grey40

highlight LineNr       cterm=none ctermfg=240 guifg=#2b506e guibg=#000000

augroup BgHighlight
  autocmd!
  autocmd WinEnter * set cul
  autocmd WinLeave * set nocul
augroup END

if &term =~ "screen"
  autocmd BufEnter * if bufname("") !~ "^?[A-Za-z0-9?]*://" | silent! exe '!echo -n "\ek[`hostname`:`basename $PWD`/`basename %`]\e\\"' | endif
  autocmd VimLeave * silent!  exe '!echo -n "\ek[`hostname`:`basename $PWD`]\e\\"'
endif

"-------------------------------------------------------------------------------
" Other plugins
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" Color scheme
"-------------------------------------------------------------------------------

colorscheme solarized

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
let g:rc_dir         = expand('~/.vim/rc')
let g:dein_toml      = g:rc_dir . '/dein.toml'
let g:dein_lazy_toml = g:rc_dir . '/dein_lazy.toml'

" Required:
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir, [$MYVIMRC, g:dein_toml, g:dein_lazy_toml])

  call dein#load_toml(g:dein_toml,      {'lazy': 0})
  call dein#load_toml(g:dein_lazy_toml, {'lazy': 1})

  call dein#add('junegunn/fzf', { 'do': 'fzf#install()', 'build': './install --all', 'merged': 0 })
  call dein#add('junegunn/fzf.vim', { 'depends': 'fzf' })

  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif


"-------------------------------------------------------------------------------
" FZF
"-------------------------------------------------------------------------------
fun! FzfOmniFiles()
  let is_git = system('git status')
  if v:shell_error
    call fzf#run(fzf#wrap({'source': 'find . -type d -name .git -prune -o ! -name .DS_Store', 'sink': 'e'}))
  else
    call fzf#run(fzf#wrap({'source': 'git ls-files', 'sink': 'e'}))
  endif
endfun

nnoremap <C-b> :Buffers<CR>
nnoremap <C-g> :Rg<CR>
nnoremap <C-p> :call FzfOmniFiles()<CR>

set rtp+=/usr/local/opt/fzf

"-------------------------------------------------------------------------------
" coc 
"-------------------------------------------------------------------------------
" Extensions
let g:coc_global_extensions = [
  \ 'coc-solargraph',
  \ 'coc-json',
  \ 'coc-tsserver',
  \ 'coc-prettier',
  \ 'coc-eslint',
  \ 'coc-go',
  \ ]

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction


"-------------------------------------------------------------------------------
" airline
"-------------------------------------------------------------------------------
" , キーで次タブのバッファを表示
nnoremap <silent> , :bprev<CR>
" . キーで前タブのバッファを表示
nnoremap <silent> . :bnext<CR>
" bdで現在のバッファを削除
nnoremap bd :bd<CR>

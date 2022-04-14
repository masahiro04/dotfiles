"-------------------------------------------------------------------------------
" basic
"-------------------------------------------------------------------------------
" シェルを指定してください
set shell=/bin/zsh
set mouse=a

" encoding
set encoding=utf8
scriptencoding utf8
set fileencoding=utf-8
set termencoding=utf8
set fileencodings=utf-8,sjis,ucs-boms,euc-jp,ep932
set fileformats=unix,dos,mac
set ambiwidth=double
set nobomb

" スワップファイルの作成先を変更
set noswapfile

" ヤンクをクリップボードへ繋ぐ
set clipboard=unnamed

" ビープ音を消す
set belloff=all

" 行番号系
set number

" タイトル系
set title

" インデント系
filetype plugin indent on

" kotlin認識しないので、こちらで対応
autocmd BufReadPost *.kt setlocal filetype=kotlin
autocmd BufNewFile,BufRead *.nim, set filetype=nim

set expandtab
set tabstop=2
set softtabstop=2
set autoindent
set smartindent
set shiftwidth=2
au FileType go setlocal sw=4 ts=4 sts=4 noet
set list listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

" Git mergeの際にこれがないと編集できないぽい
set modifiable

" 検索するときに大文字小文字を区別しない
set ignorecase

" 検索した時にハイライト
set hlsearch

nnoremap nh :nohl<CR>
"-------------------------------------------------------------------------------
" キーバインド
"-------------------------------------------------------------------------------
" xやdeで削除した時はヤンクしない
nnoremap x "_x

" 画面分割系
nnoremap sj <C-w>j
nnoremap sk <C-w>k
nnoremap sl <C-w>l
nnoremap sh <C-w>h
nnoremap ss :<C-u>sp<CR><C-w>j
nnoremap sv :<C-u>vs<CR><C-w>l

" 挿入モードからexit
inoremap <silent> jj <ESC>

" バッファ移動
"次タブのバッファを表示
nnoremap <silent> bp :bprev<CR>
"前タブのバッファを表示
nnoremap <silent> bn :bnext<CR>
"直前バッファを表示
nnoremap <silent> bb :b#<CR>
" bdで現在のバッファを削除
nnoremap bd :bdelete<CR>

set timeoutlen=200 ttimeoutlen=0

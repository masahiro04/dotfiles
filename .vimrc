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
" set t_Co=256

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

" tagファイルの指定
" set tags=~/.tags

" 保存時に自動で生成
let g:auto_ctags = 1

function! s:execute_ctags() abort
  " 探すタグファイル名
  let tag_name = '.tags'
  " ディレクトリを遡り、タグファイルを探し、パス取得
  let tags_path = findfile(tag_name, '.;')
  " タグファイルパスが見つからなかった場合
  if tags_path ==# ''
    return
  endif

  " タグファイルのディレクトリパスを取得
  " `:p:h`の部分は、:h filename-modifiersで確認
  let tags_dirpath = fnamemodify(tags_path, ':p:h')
  " 見つかったタグファイルのディレクトリに移動して、ctagsをバックグラウンド実行（エラー出力破棄）
  execute 'silent !cd' tags_dirpath '&& ctags -R -f' tag_name '2> /dev/null &'
endfunction

augroup ctags
  autocmd!
  autocmd BufWritePost * call s:execute_ctags()
augroup END

" 挿入モードでバックスペース削除を有効
set backspace=indent,eol,start

" 検索するときに大文字小文字を区別しない
set ignorecase

" 検索した時にハイライト
set hlsearch

"-------------------------------------------------------------------------------
" キーバインド
"-------------------------------------------------------------------------------
" xやdeで削除した時はヤンクしない
vnoremap x "_x
nnoremap x "_x
nnoremap de "_de
nnoremap dd "_dd

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
"-------------------------------------------------------------------------------
" Cursor line
"-------------------------------------------------------------------------------

set cursorline

" Set cursor line color on visual mode
highlight Visual cterm=NONE ctermbg=236 ctermfg=NONE guibg=Grey40

highlight LineNr cterm=none ctermfg=240 guifg=#2b506e guibg=#000000

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
" Color scheme
"-------------------------------------------------------------------------------
let g:solarized_termcolors=256 "ここ重要、絶対入れること、とdocumentにあった"
syntax enable
set background=dark
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
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif


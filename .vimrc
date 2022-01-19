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
" let g:auto_ctags = 1

" function! s:execute_ctags() abort
"   " 探すタグファイル名
"   let tag_name = '.tags'
"   " ディレクトリを遡り、タグファイルを探し、パス取得
"   let tags_path = findfile(tag_name, '.;')
"   " タグファイルパスが見つからなかった場合
"   if tags_path ==# ''
"     return
"   endif
"
"   " タグファイルのディレクトリパスを取得
"   " `:p:h`の部分は、:h filename-modifiersで確認
"   let tags_dirpath = fnamemodify(tags_path, ':p:h')
"   " 見つかったタグファイルのディレクトリに移動して、ctagsをバックグラウンド実行（エラー出力破棄）
"   execute 'silent !cd' tags_dirpath '&& ctags -R -f' tag_name '2> /dev/null &'
" endfunction

" augroup ctags
"   autocmd!
"   autocmd BufWritePost * call s:execute_ctags()
" augroup END

" 挿入モードでバックスペース削除を有効
" set backspace=indent,eol,start

" 検索するときに大文字小文字を区別しない
set ignorecase

" 検索した時にハイライト
set hlsearch
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


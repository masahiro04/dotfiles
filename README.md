### 概要
大久保のvimの設定ファイルです

### 使い方
```
git pull
cd dotfiles
# deinをinstall
# https://github.com/Shougo/dein.vim
# deinをinstallしていなくて正常に機能しなかったこともあるので、これ重要
source install.sh
```


### tmuxでのコマンド
```
<C-q + -> 水平ペイン追加
<C-q + |> 垂直ペイン追加
<C-q + space> ペイン入れ替え

```

### 文字列操作
ビジュアルモードで選択後 S を入力し
```
b (
B {
r [
a <
" ""
' ''
```

### Vim起動後コマンド
```
# treeを開く
<C-e>
# ファイル検索
<C-p>
# 文字検索(正規表現)
<C-g>
# ctagsを生成した後に定義元にジャンプ
<C-]>
# 定義元にジャンプした後に、元の場所に戻る
<C-t>

# git blameを起動
:Gblame
# prettierでフォーマット修正
:Prettier

# 横に画面追加
sv
# 下に画面追加
ss
# 左に移動
sh
# 下に移動
sj
# 上に移動
sk
# 右に移動
sl

# 前にバッファに移動
bp
# 次のバッファに移動
bn
# 直前バッファに移動
bb
# 現在のバッファ削除
bd
```


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


### 基本コマンド
```
<C-q + -> 水平ペイン追加
<C-q + |> 垂直ペイン追加
<C-q + space> ペイン入れ替え
<C-e> tree
<C-p> ファイル検索
<C-g> 文字検索
<C-]> 定義元ジャンプ
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
:Gblame git blameを起動
sv 垂直にタグ作成
ss 水平にタグ作成
sh 左に移動
sj 下に移動
sk 上に移動
sl 右に移動
<t> 左のタブに移動
<r> 右のタブに移動
:bd 現在のバッファを削除
```

その他あると思うけど調べてください


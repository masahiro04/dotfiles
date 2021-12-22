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

### 括弧系の扱い
原則`ysiw`を入れて、囲みたい文字を入力してください
```
# シングルクオートで囲む
ysiw'
# ダブルクオテーションで囲む
ysiw"
# ()で囲む, )はスペースなし
ysiw)
# {}で囲む、}はスペースなし
ysiw}
# <>で囲む、>はスペースなし
ysiw>

# 囲む文字の置換、最初に元文字で、次に置換したい文字
cs'"

# 囲んでいる文字列の削除
ds'

# 囲んでいる文字の中を削除
di'
```
### COC
```
# 定義元にジャンプ
gd
# 定義元から元に戻る
ctrl + o
# 参照先一覧
gr
# 自動import . 自動的にimportしたい関数やclassの上で実行
ctrl + y
```

### Vim起動後コマンド
```
# treeを開く
<C-e>
# ファイル検索
fp
# 文字検索(正規表現)
fg
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

# 挿入モードから抜ける
jj
```


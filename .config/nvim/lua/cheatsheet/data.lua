-- Vim / Neovim チートシートのデータ。
--
-- 各エントリ:
--   keys : 覚えたいキー、または `:` で始まる Ex コマンド
--   desc : 日本語の説明
--   mode : "n"(既定) / "i" / "v" / "c" / "x" など。表示用のラベル
--   tags : 検索用の追加キーワード(日本語・英語どちらでも書ける)
--   help : `<C-h>` で開く `:help` のタグ
--
-- `:` で始まるエントリは <CR> でコマンドラインに流し込まれる(実行はされない)ので、
-- プレースホルダ(old/new など)を書いておくとテンプレートとして使える。

---@class CheatItem
---@field keys string
---@field desc string
---@field mode? string
---@field tags? string
---@field help? string

---@class CheatGroup
---@field name string
---@field items CheatItem[]

---@type CheatGroup[]
return {
  {
    name = "自分の設定",
    items = {
      { keys = "x", desc = "1文字削除(レジスタを汚さない)", tags = "delete yank レジスタ" },
      { keys = "+", desc = "カーソル下の数値をインクリメント", tags = "increment 数値 増やす" },
      { keys = "-", desc = "カーソル下の数値をデクリメント", tags = "decrement 数値 減らす" },
      { keys = "dw", desc = "カーソル前の単語を削除(vb\"_d)", tags = "word delete 単語" },
      { keys = "<C-a>", desc = "ファイル全体を選択", tags = "select all 全選択" },
      { keys = "te", desc = "新しいタブを開く", tags = "tab tabedit タブ" },
      { keys = "ss", desc = "水平分割して新ウィンドウへ移動", tags = "split 分割 横" },
      { keys = "sv", desc = "垂直分割して新ウィンドウへ移動", tags = "vsplit 分割 縦" },
      { keys = "bp", desc = "前のバッファへ", tags = "buffer 前 previous" },
      { keys = "bn", desc = "次のバッファへ", tags = "buffer 次 next" },
      { keys = "bd", desc = "バッファを閉じる", tags = "buffer delete 閉じる" },
      { keys = "<Space>", desc = "次のウィンドウへ移動(<C-w>w)", tags = "window 移動" },
      { keys = "sh / sj / sk / sl", desc = "左/下/上/右のウィンドウへ移動", tags = "window 移動 左右上下" },
      { keys = "s<left> …", desc = "矢印でもウィンドウ移動できる", tags = "window 移動 矢印" },
      { keys = "<C-w><left/right/up/down>", desc = "ウィンドウをリサイズ", tags = "resize サイズ 幅 高さ" },
      { keys = "nh", desc = "検索ハイライトを消す(:nohl)", tags = "highlight 消す nohlsearch" },
      { keys = "jj", desc = "インサートモードを抜ける", mode = "i", tags = "escape esc 抜ける" },
      { keys = "qq", desc = "Pounce で画面内ジャンプ", tags = "jump easymotion pounce 飛ぶ" },
      { keys = "dr", desc = "シンボルをリネーム(renamer.nvim)", tags = "rename リネーム 名前変更" },
      { keys = "<C-j>", desc = "次の診断(エラー)へ移動", tags = "diagnostic error エラー 次" },
      { keys = "<leader>y", desc = "現在ファイルの相対パスをコピー", tags = "path copy パス コピー クリップボード" },
      { keys = "<leader>ob", desc = "現在のファイルをブラウザで開く(:BrowserPreview)", help = "browser-preview", tags = "browser png 画像 プレビュー 開く" },
      { keys = ";g", desc = "Storyline: PR の diff を章に分けてレビュー", help = "storyline", tags = "storyline review レビュー pr diff 章" },
      { keys = ";G", desc = "Storyline: base ブランチを選んでレビュー", help = "storyline", tags = "storyline base ブランチ 比較" },
      { keys = ";l", desc = "Storyline: トピック単位でコードを読む", help = "storyline", tags = "storyline read 読解 トピック キャッチアップ" },
      { keys = "<leader>an", desc = "付箋: カーソル行/シンボル(v で選択範囲)に貼る", help = "code-annotations", tags = "annotation 付箋 メモ コメント TODO" },
      { keys = "<leader>al", desc = "付箋: 一覧を Telescope で開く", help = "code-annotations", tags = "annotation 付箋 一覧 list" },
      { keys = "<leader>ar", desc = "付箋: 解決済み/未解決を切り替え", help = "code-annotations", tags = "annotation 付箋 resolve 解決" },
      { keys = "<leader>ad", desc = "付箋: カーソル位置の付箋を削除", help = "code-annotations", tags = "annotation 付箋 delete 削除" },
      { keys = "<leader>ak", desc = "付箋: LSP hover に付箋の内容を並べて表示", help = "code-annotations", tags = "annotation 付箋 hover" },
      { keys = "<leader>ax", desc = "付箋: 未解決分をコード断片つき JSON で書き出す", help = "code-annotations", tags = "annotation 付箋 export 書き出し ai" },
      { keys = "<leader>ap", desc = "付箋: 保存先パスを表示してコピー", help = "code-annotations", tags = "annotation 付箋 path パス 保存先" },
      { keys = ";?", desc = "このチートシートをあいまい検索", tags = "cheatsheet help ヘルプ 検索" },
      { keys = ";k", desc = "チートシート一覧をフローティング表示", tags = "cheatsheet list 一覧" },
      { keys = "<C-e> / <C-r>", desc = "winresizer でウィンドウ操作モード", tags = "resize winresizer サイズ" },
    },
  },

  {
    name = "検索/Telescope",
    items = {
      { keys = ";f", desc = "ファイル検索(隠しファイル含む)", tags = "find files ファイル 探す" },
      { keys = ";r", desc = "プロジェクト全文検索(live grep)", tags = "grep 検索 文字列 全文" },
      { keys = "\\\\", desc = "開いているバッファ一覧", tags = "buffer 一覧 バッファ" },
      { keys = ";t", desc = "ヘルプタグを検索", tags = "help ヘルプ タグ" },
      { keys = ";;", desc = "直前の Telescope を再開", tags = "resume 再開 前回" },
      { keys = ";e", desc = "診断(エラー)一覧", tags = "diagnostics エラー 一覧" },
      { keys = ";s", desc = "Treesitter のシンボル一覧(関数・変数)", tags = "symbol 関数 変数 一覧" },
      { keys = ";c", desc = "現在ファイルのディレクトリをファイルブラウザで開く", tags = "file browser ディレクトリ" },
      { keys = "O", desc = "ファイルブラウザ内: カーソル下のファイルをブラウザで開く(PNGプレビュー)", help = "browser-preview", tags = "browser png 画像 プレビュー 開く" },
      { keys = "<C-y>", desc = "Telescope 内: 選択エントリの相対パスをコピー", mode = "i/n", tags = "path copy パス" },
      { keys = "<Tab>", desc = "Telescope 内: 複数選択 → <CR> でまとめて開く", mode = "i", tags = "multi select 複数" },
      { keys = "<leader>sk", desc = "実際に有効なキーマップを全部検索(Telescope keymaps)", tags = "keymap キーマップ 一覧 忘れた" },
      { keys = ":Telescope", desc = "Telescope のピッカー一覧を表示", tags = "telescope 一覧" },
    },
  },

  {
    name = "カーソル移動",
    items = {
      { keys = "0 / ^ / $", desc = "行頭 / 最初の非空白 / 行末", help = "0", tags = "line start end 行頭 行末" },
      { keys = "w / b / e / ge", desc = "次の単語頭 / 前の単語頭 / 単語末 / 前の単語末", help = "w", tags = "word 単語" },
      { keys = "W / B / E", desc = "空白区切りで単語移動", help = "W", tags = "word 単語 空白" },
      { keys = "f{char} / F{char}", desc = "行内で次/前の {char} へジャンプ", help = "f", tags = "find char 文字 移動" },
      { keys = "t{char} / T{char}", desc = "{char} の直前/直後まで移動", help = "t", tags = "till char 文字" },
      { keys = "; / ,", desc = "直前の f/t を再実行 / 逆方向に再実行", help = ";", tags = "repeat 繰り返し" },
      { keys = "gg / G", desc = "ファイル先頭 / 末尾へ", help = "G", tags = "top bottom 先頭 末尾" },
      { keys = "{count}G / :{count}", desc = "指定行へジャンプ", help = "G", tags = "line 行 移動 何行目" },
      { keys = "{ / }", desc = "前/次の段落へ", help = "}", tags = "paragraph 段落" },
      { keys = "( / )", desc = "前/次の文へ", help = ")", tags = "sentence 文" },
      { keys = "%", desc = "対応する括弧へジャンプ", help = "%", tags = "bracket 括弧 対応" },
      { keys = "H / M / L", desc = "画面の上 / 中央 / 下へ", help = "H", tags = "screen 画面" },
      { keys = "zz / zt / zb", desc = "カーソル行を画面中央 / 上 / 下に", help = "zz", tags = "scroll センタリング 画面" },
      { keys = "<C-d> / <C-u>", desc = "半画面下 / 上スクロール", help = "CTRL-D", tags = "scroll スクロール" },
      { keys = "<C-o> / <C-i>", desc = "ジャンプリストを戻る / 進む", help = "CTRL-O", tags = "jumplist 戻る 進む 履歴" },
      { keys = "g; / g,", desc = "変更箇所を戻る / 進む", help = "g;", tags = "changelist 変更 履歴" },
      { keys = "``", desc = "直前の位置へ戻る", help = "``", tags = "back 戻る 前の場所" },
    },
  },

  {
    name = "編集",
    items = {
      { keys = "d{motion}", desc = "モーション範囲を削除 (dw, d$, dj …)", help = "d", tags = "delete 削除" },
      { keys = "dd / D", desc = "1行削除 / カーソルから行末まで削除", help = "dd", tags = "delete 行 削除" },
      { keys = "c{motion} / cc / C", desc = "削除してインサート(変更)", help = "c", tags = "change 変更 書き換え" },
      { keys = "y{motion} / yy", desc = "ヤンク(コピー)", help = "y", tags = "yank copy コピー" },
      { keys = "p / P", desc = "カーソル後 / 前に貼り付け", help = "p", tags = "paste 貼り付け" },
      { keys = "\"+y / \"+p", desc = "OSクリップボードにコピー / から貼り付け", help = "quotestar", tags = "clipboard クリップボード" },
      { keys = "u / <C-r>", desc = "アンドゥ / リドゥ", help = "u", tags = "undo redo 元に戻す やり直し" },
      { keys = ".", desc = "直前の変更を繰り返す", help = ".", tags = "repeat 繰り返し ドット" },
      { keys = "J / gJ", desc = "次の行を連結(空白あり / なし)", help = "J", tags = "join 連結 結合" },
      { keys = ">> / <<", desc = "行をインデント / アンインデント", help = ">>", tags = "indent インデント" },
      { keys = "== / =G", desc = "自動インデント整形(行 / 以降すべて)", help = "=", tags = "indent format 整形" },
      { keys = "~ / g~{motion}", desc = "大文字小文字を反転", help = "~", tags = "case 大文字 小文字" },
      { keys = "gU{motion} / gu{motion}", desc = "大文字化 / 小文字化 (gUiw など)", help = "gU", tags = "upper lower 大文字 小文字" },
      { keys = "r{char} / R", desc = "1文字置換 / 置換モード", help = "r", tags = "replace 置換 上書き" },
      { keys = "xp / ddp", desc = "文字 / 行を下と入れ替える", tags = "swap 入れ替え" },
      { keys = "<C-a> / <C-x>", desc = "数値をインクリメント / デクリメント(既定)", help = "CTRL-A", tags = "increment 数値" },
      { keys = "g<C-a>", desc = "ビジュアル選択した数値を連番にする", mode = "v", help = "v_g_CTRL-A", tags = "連番 increment 番号" },
      { keys = "gq{motion}", desc = "テキストを textwidth で折り返し整形", help = "gq", tags = "format 整形 折り返し" },
    },
  },

  {
    name = "インサートモード",
    items = {
      { keys = "i / a / I / A", desc = "前 / 後 / 行頭 / 行末から挿入", help = "i", tags = "insert 挿入" },
      { keys = "o / O", desc = "下 / 上に行を追加して挿入", help = "o", tags = "insert new line 改行" },
      { keys = "gi", desc = "最後に挿入した位置から再開", help = "gi", tags = "insert 再開" },
      { keys = "<C-r>{reg}", desc = "レジスタの内容を挿入", mode = "i", help = "i_CTRL-R", tags = "register 貼り付け 挿入" },
      { keys = "<C-r>%", desc = "現在のファイルパスを挿入", mode = "i", help = "i_CTRL-R", tags = "path パス 挿入" },
      { keys = "<C-w> / <C-u>", desc = "直前の単語 / 行を削除", mode = "i", help = "i_CTRL-W", tags = "delete 削除" },
      { keys = "<C-o>{cmd}", desc = "1回だけノーマルモードのコマンドを実行", mode = "i", help = "i_CTRL-O", tags = "normal 一時" },
      { keys = "<C-n> / <C-p>", desc = "単語補完(次 / 前)", mode = "i", help = "i_CTRL-N", tags = "complete 補完" },
      { keys = "<C-x><C-f>", desc = "ファイルパス補完", mode = "i", help = "i_CTRL-X_CTRL-F", tags = "complete 補完 パス" },
    },
  },

  {
    name = "ビジュアルモード",
    items = {
      { keys = "v / V / <C-v>", desc = "文字 / 行 / 矩形ビジュアル", help = "v", tags = "visual 選択 矩形" },
      { keys = "gv", desc = "直前の選択範囲を復元", help = "gv", tags = "visual 再選択" },
      { keys = "o", desc = "選択範囲の反対端へ移動", mode = "v", help = "v_o", tags = "visual 端" },
      { keys = "<C-v> → I → <Esc>", desc = "矩形選択して複数行の先頭に同時挿入", help = "v_b_I", tags = "矩形 複数行 挿入 マルチカーソル" },
      { keys = "<C-v> → $ → A", desc = "矩形選択して各行の行末に同時追記", help = "v_b_A", tags = "矩形 複数行 追記" },
      { keys = ": → '<,'>", desc = "選択範囲に対して Ex コマンドを実行", help = "v_:", tags = "range 範囲 コマンド" },
      { keys = "J / < / >", desc = "選択範囲を連結 / インデント調整", mode = "v", tags = "join indent インデント" },
      { keys = "u / U", desc = "選択範囲を小文字化 / 大文字化", mode = "v", help = "v_u", tags = "case 大文字 小文字" },
    },
  },

  {
    name = "テキストオブジェクト",
    items = {
      { keys = "iw / aw", desc = "単語(内側 / 空白込み)", help = "iw", tags = "word 単語" },
      { keys = "i\" / a\"", desc = "ダブルクォートの中身 / 含む", help = "i\"", tags = "quote 引用符 文字列" },
      { keys = "i( / a( （ib/ab）", desc = "丸括弧の中身 / 含む", help = "i(", tags = "paren 括弧" },
      { keys = "i{ / a{ （iB/aB）", desc = "波括弧の中身 / 含む", help = "i{", tags = "brace ブロック" },
      { keys = "i[ / a[", desc = "角括弧の中身 / 含む", help = "i[", tags = "bracket 配列" },
      { keys = "it / at", desc = "HTMLタグの中身 / タグ含む", help = "it", tags = "tag html タグ" },
      { keys = "ip / ap", desc = "段落", help = "ip", tags = "paragraph 段落" },
      { keys = "if / af", desc = "関数(Treesitter textobject)", tags = "function 関数" },
      { keys = "ci\" / da( / yi{", desc = "組み合わせ例: 変更 / 削除 / コピー", tags = "組み合わせ example 例" },
    },
  },

  {
    name = "surround(nvim-surround)",
    items = {
      { keys = "ys{motion}{char}", desc = "囲む (ysiw\" で単語をクォート)", tags = "surround 囲む add" },
      { keys = "yss{char}", desc = "行全体を囲む", tags = "surround 行 囲む" },
      { keys = "ds{char}", desc = "囲みを削除 (ds\" )", tags = "surround delete 削除" },
      { keys = "cs{old}{new}", desc = "囲みを変更 (cs\"' )", tags = "surround change 変更" },
      { keys = "S{char}", desc = "ビジュアル選択を囲む", mode = "v", tags = "surround visual 囲む" },
      { keys = "ysiwt", desc = "単語をHTMLタグで囲む(タグ名を入力)", tags = "surround tag html" },
    },
  },

  {
    name = "検索・置換",
    items = {
      { keys = "/pattern / ?pattern", desc = "前方 / 後方検索", help = "/", tags = "search 検索" },
      { keys = "n / N", desc = "次 / 前の検索結果へ", help = "n", tags = "search 次 前" },
      { keys = "* / #", desc = "カーソル下の単語を前方 / 後方検索", help = "star", tags = "search 単語 検索" },
      { keys = ":%s/old/new/g", desc = "ファイル全体を置換", help = ":substitute", tags = "replace 置換 全体" },
      { keys = ":%s/old/new/gc", desc = "確認しながら全体置換", help = ":s_flags", tags = "replace 置換 確認" },
      { keys = ":'<,'>s/old/new/g", desc = "選択範囲だけ置換", help = ":range", tags = "replace 置換 範囲" },
      { keys = ":%s/\\<word\\>/new/g", desc = "単語単位で完全一致置換", help = "/\\<", tags = "replace 置換 単語 完全一致" },
      { keys = ":g/pattern/d", desc = "パターンに一致する行を全削除", help = ":global", tags = "global 削除 行 grep" },
      { keys = ":v/pattern/d", desc = "一致しない行を全削除", help = ":vglobal", tags = "global 削除 逆" },
      { keys = ":noh", desc = "検索ハイライトを消す", help = ":nohlsearch", tags = "highlight 消す" },
      { keys = ":vim /pattern/ **/*.rb", desc = "複数ファイルを grep して quickfix へ", help = ":vimgrep", tags = "grep quickfix 複数ファイル" },
      { keys = ":cdo s/old/new/g | update", desc = "quickfix の全ファイルを一括置換", help = ":cdo", tags = "replace 一括 置換 quickfix" },
    },
  },

  {
    name = "ウィンドウ/タブ/バッファ",
    items = {
      { keys = "<C-w>s / <C-w>v", desc = "水平 / 垂直分割", help = "CTRL-W_s", tags = "split 分割" },
      { keys = "<C-w>q / <C-w>o", desc = "ウィンドウを閉じる / 1つだけ残す", help = "CTRL-W_o", tags = "close only 閉じる" },
      { keys = "<C-w>H / J / K / L", desc = "ウィンドウを左/下/上/右へ移動配置", help = "CTRL-W_H", tags = "move 移動 配置" },
      { keys = "<C-w>= / <C-w>_ / <C-w>|", desc = "サイズ均等 / 高さ最大 / 幅最大", help = "CTRL-W_=", tags = "resize サイズ 最大" },
      { keys = "<C-w>T", desc = "現在のウィンドウを新しいタブへ", help = "CTRL-W_T", tags = "tab タブ" },
      { keys = "gt / gT / {n}gt", desc = "次 / 前 / n番目のタブへ", help = "gt", tags = "tab タブ 移動" },
      { keys = ":tabclose / :tabonly", desc = "タブを閉じる / 1つだけ残す", help = ":tabclose", tags = "tab 閉じる" },
      { keys = ":ls / :b {name}", desc = "バッファ一覧 / 名前でバッファ切替", help = ":ls", tags = "buffer 一覧 切替" },
      { keys = "<C-^>", desc = "直前のバッファへトグル", help = "CTRL-^", tags = "buffer 前 交互" },
      { keys = ":e {file} / :e!", desc = "ファイルを開く / 変更を捨てて再読込", help = ":edit", tags = "open reload 開く 再読込" },
      { keys = ":w / :wa / :x", desc = "保存 / 全部保存 / 保存して閉じる", help = ":write", tags = "save 保存" },
      { keys = ":q! / :qa!", desc = "保存せず閉じる / 全部閉じる", help = ":quit", tags = "quit 終了 破棄" },
      { keys = ":sav {file}", desc = "別名で保存して以降そのファイルを編集", help = ":saveas", tags = "saveas 別名 保存" },
      { keys = ":w !sudo tee %", desc = "sudo で強制保存", tags = "sudo 権限 保存" },
    },
  },

  {
    name = "レジスタ・マクロ",
    items = {
      { keys = "\"{reg}y / \"{reg}p", desc = "指定レジスタにコピー / から貼り付け", help = "registers", tags = "register レジスタ" },
      { keys = ":reg", desc = "レジスタの中身を一覧表示", help = ":registers", tags = "register 一覧" },
      { keys = "\"0p", desc = "最後にヤンクした内容を貼り付け(削除で上書きされない)", help = "quote0", tags = "yank register 貼り付け" },
      { keys = "q{reg} … q", desc = "マクロ記録の開始 … 終了", help = "q", tags = "macro マクロ 記録" },
      { keys = "@{reg} / @@", desc = "マクロ実行 / 直前のマクロを再実行", help = "@", tags = "macro 実行" },
      { keys = "{count}@{reg}", desc = "マクロを count 回実行(100@q など)", help = "@", tags = "macro 繰り返し" },
      { keys = ":%normal @q", desc = "全行にマクロを適用", help = ":normal", tags = "macro 全行 一括" },
      { keys = ":let @a='...'", desc = "レジスタに直接値を入れる", help = ":let-@", tags = "register 代入" },
    },
  },

  {
    name = "マーク・quickfix・折りたたみ",
    items = {
      { keys = "m{a-z} / '{a-z}", desc = "マークを付ける / マークへジャンプ", help = "mark", tags = "mark マーク" },
      { keys = "'\" / '.", desc = "最後の編集位置 / 最後の変更位置へ", help = "'quote", tags = "mark 前回 位置" },
      { keys = ":marks / :delm!", desc = "マーク一覧 / マーク全削除", help = ":marks", tags = "mark 一覧" },
      { keys = ":copen / :cclose", desc = "quickfix を開く / 閉じる", help = ":copen", tags = "quickfix 一覧" },
      { keys = "]q / [q", desc = "次 / 前の quickfix 項目へ(LazyVim)", tags = "quickfix 次 前" },
      { keys = "za / zR / zM", desc = "折りたたみ切替 / 全部開く / 全部閉じる", help = "za", tags = "fold 折りたたみ" },
      { keys = "zf{motion} / zd", desc = "折りたたみを作る / 削除", help = "zf", tags = "fold 作成" },
      { keys = "zj / zk", desc = "次 / 前の折りたたみへ", help = "zj", tags = "fold 移動" },
    },
  },

  {
    name = "LSP・コード(LazyVim既定)",
    items = {
      { keys = "gd / gD", desc = "定義へ / 宣言へジャンプ", tags = "lsp definition 定義 ジャンプ" },
      { keys = "gr", desc = "参照一覧", tags = "lsp references 参照 使用箇所" },
      { keys = "gI / gy", desc = "実装へ / 型定義へ", tags = "lsp implementation 実装 型" },
      { keys = "K / gK", desc = "ホバードキュメント / シグネチャヘルプ", tags = "lsp hover ドキュメント 説明" },
      { keys = "<leader>ca", desc = "コードアクション", tags = "lsp code action 修正" },
      { keys = "<leader>cr", desc = "シンボルをリネーム(LSP)", tags = "lsp rename リネーム" },
      { keys = "<leader>cf", desc = "フォーマット", tags = "format 整形" },
      { keys = "]d / [d", desc = "次 / 前の診断へ", tags = "diagnostic エラー 次 前" },
      { keys = "<leader>cd", desc = "カーソル行の診断を表示", tags = "diagnostic エラー 表示" },
      { keys = "<leader>xx", desc = "Trouble で診断一覧", tags = "trouble diagnostics 一覧 エラー" },
      { keys = "<leader>ss", desc = "ドキュメント内のシンボル検索", tags = "symbol シンボル 関数" },
      { keys = "gcc / gc{motion}", desc = "行 / 範囲をコメントアウト", tags = "comment コメント" },
      { keys = ":LspInfo / :Mason", desc = "LSPの状態 / LSP・ツール管理画面", tags = "lsp mason インストール" },
      { keys = ":ConformInfo", desc = "フォーマッタの状態を確認", tags = "format conform 整形" },
    },
  },

  {
    name = "Git",
    items = {
      { keys = "]h / [h", desc = "次 / 前の変更(hunk)へ", tags = "gitsigns hunk 変更 差分" },
      { keys = "<leader>ghs / <leader>ghr", desc = "hunk をステージ / 取り消し", tags = "gitsigns stage reset" },
      { keys = "<leader>ghp", desc = "hunk の差分をプレビュー", tags = "gitsigns preview 差分" },
      { keys = "<leader>ghb", desc = "行の blame を表示", tags = "blame 誰が いつ" },
      { keys = "<leader>gg", desc = "LazyGit を開く", tags = "lazygit git" },
      { keys = ":G", desc = "fugitive の status を新しいタブで全画面表示(gq で閉じる)", tags = "fugitive status git 全画面" },
      { keys = "<CR> (:G status内)", desc = "カーソル下のファイルを新しいタブで全画面で開く", tags = "fugitive open 開く 全画面" },
      { keys = ":G diff / :G log / :G show", desc = "新しいタブで全画面表示", tags = "fugitive diff log 差分 全画面" },
      { keys = ":Git", desc = "fugitive の status を分割で開く", tags = "fugitive status git" },
      { keys = ":Gdiffsplit", desc = "作業ツリーとの差分を分割表示", tags = "fugitive diff 差分" },
      { keys = ":Gblame", desc = "fugitive の blame", tags = "fugitive blame" },
      { keys = ":Git log -- %", desc = "現在ファイルのコミット履歴", tags = "fugitive log 履歴" },
    },
  },

  {
    name = "ヘルプ・調べ方",
    items = {
      { keys = ":h {topic}", desc = "ヘルプを引く (:h :substitute など)", help = ":help", tags = "help ヘルプ 調べる" },
      { keys = "K (ヘルプ内) / <C-]>", desc = "ヘルプ内のタグへジャンプ", help = "help-context", tags = "help タグ ジャンプ" },
      { keys = ":h index", desc = "全キーマップの索引を見る", help = "index", tags = "help index 一覧 キー" },
      { keys = ":map / :nmap / :imap", desc = "現在有効なマッピング一覧", help = ":map", tags = "keymap 一覧 マッピング 忘れた" },
      { keys = ":verbose map {key}", desc = "そのキーが何にどこで割り当てられたか調べる", help = ":verbose", tags = "keymap 調べる 競合 どこ" },
      { keys = ":set {option}?", desc = "オプションの現在値を確認", help = ":set", tags = "option 設定 確認" },
      { keys = ":checkhealth", desc = "Neovim の健全性チェック", help = ":checkhealth", tags = "health 診断 確認" },
      { keys = ":messages", desc = "過去のメッセージを再表示", help = ":messages", tags = "message ログ 通知" },
      { keys = ":Lazy", desc = "プラグイン管理画面(lazy.nvim)", tags = "lazy plugin プラグイン 更新" },
      { keys = ":LazyExtras", desc = "LazyVim の Extras を有効化/無効化", tags = "lazyvim extras 追加" },
      { keys = "g?", desc = "各プラグインのUI内でヘルプを表示(Lazy/Neo-tree等)", tags = "help ヘルプ ui" },
      { keys = ":so %", desc = "現在のLuaファイルを読み込み直す", help = ":source", tags = "source reload 再読込 設定" },
    },
  },

  {
    name = "その他 Ex コマンド",
    items = {
      { keys = ":r {file} / :r !{cmd}", desc = "ファイル / コマンド出力を挿入", help = ":read", tags = "insert 読み込み コマンド出力" },
      { keys = ":!{cmd}", desc = "シェルコマンドを実行", help = ":!cmd", tags = "shell 実行" },
      { keys = ":%!{cmd}", desc = "バッファ全体をコマンドに通す(:%!jq . など)", help = ":range!", tags = "filter 整形 jq sort" },
      { keys = ":sort / :sort u", desc = "行をソート / 重複を除いてソート", help = ":sort", tags = "sort ソート 重複" },
      { keys = ":set paste! / :set list!", desc = "貼り付けモード / 不可視文字表示をトグル", help = ":set", tags = "paste list 設定" },
      { keys = ":set wrap! / :set number!", desc = "折り返し / 行番号をトグル", help = ":set", tags = "wrap number 行番号" },
      { keys = ":e ++enc=cp932 %", desc = "エンコーディングを指定して開き直す", help = "++enc", tags = "encoding 文字化け sjis" },
      { keys = ":set ff=unix", desc = "改行コードを LF に変更", help = "fileformat", tags = "改行 crlf lf 改行コード" },
      { keys = ":earlier 10m / :later", desc = "10分前の状態に戻す / 進める", help = ":earlier", tags = "undo 時間 履歴 戻す" },
      { keys = ":diffthis / :diffoff", desc = "ウィンドウ間で差分表示 / 解除", help = ":diffthis", tags = "diff 差分 比較" },
      { keys = ":retab", desc = "タブ/スペースを設定に合わせて変換", help = ":retab", tags = "tab space インデント 変換" },
      { keys = ":Inspect", desc = "カーソル位置のハイライトグループを調べる", tags = "highlight 色 syntax 調べる" },
    },
  },
}

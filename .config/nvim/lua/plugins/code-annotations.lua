-- コードに「付箋」を貼るプラグイン。ソースは書き換えず、
-- ~/.code-annotations/<プロジェクト名>/annotations.json に外付けで保存される。
-- (パスは <leader>ap で確認・クリップボードにコピーできる)
--
--   <leader>an  カーソル行 / LSP シンボルに付箋を貼る (v なら選択範囲)
--   <leader>al  付箋一覧を Telescope で開く
--   <leader>ar  解決済み / 未解決を切り替える (解決済みはインライン表示されなくなる)
--   <leader>ad  カーソル位置の付箋を削除
--   <leader>ak  LSP hover に付箋の内容をくっつけて表示
--   <leader>ax  未解決の付箋をコード断片つき JSON で書き出す (AI に渡す用)
--   <leader>ap  保存先パスを表示してコピー
--
-- <leader>a 系は LazyVim だと copilot-chat / octo extra が使う prefix だが、
-- どちらも lazyvim.json で有効化していないので README のデフォルトのまま使う。

-- キーマップ用。lazy のロード前に require しないよう関数で包む。
local function call(fn)
  return function()
    require("code-annotations")[fn]()
  end
end

return {
  {
    "killinsun/code-annotations.nvim",
    -- 一覧 (list) は telescope があればそれを使い、無ければ quickfix になる。
    -- dependencies に telescope を足すと LazyFile 時に telescope が先に読まれ、
    -- editor.lua 側の opts(_, opts) が opts.defaults=nil で落ちるので書かない。
    -- (<leader>al 時点で lazy の require フックが telescope を読んでくれる)
    -- setup() は BufEnter で描画する autocmd を張るだけで初回描画はしないため、
    -- keys 遅延ではなくファイルを開いた時点でロードし、config 側で render_all する。
    event = "LazyFile",
    keys = {
      { "<leader>an", call("add_at_cursor"), desc = "Annotation: 行/シンボルに貼る" },
      {
        "<leader>an",
        function()
          -- '< '> は visual mode を抜けた時点で確定するので、先に <Esc> を送る
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
          require("code-annotations").add_visual()
        end,
        mode = "v",
        desc = "Annotation: 選択範囲に貼る",
      },
      { "<leader>al", call("list"), desc = "Annotation: 一覧" },
      { "<leader>ar", call("toggle_resolve_at_cursor"), desc = "Annotation: 解決トグル" },
      { "<leader>ad", call("delete_at_cursor"), desc = "Annotation: 削除" },
      -- このプラグインの hover は border="single" を強制するので、
      -- lsp-hover.lua で整えた枠 (K / gK) とは見た目が変わる。
      { "<leader>ak", call("hover"), desc = "Annotation: hover と一緒に見る" },
      { "<leader>ax", call("export_to_file"), desc = "Annotation: JSON 書き出し" },
      { "<leader>ap", call("show_path"), desc = "Annotation: 保存先パス" },
    },
    opts = {
      store_dir = nil, -- nil = ~/.code-annotations/<project-slug>/
      -- 未解決の付箋があるファイルを開くたびに通知が出る。うるさければ false。
      notify_unresolved = true,
      render_debounce_ms = 200,
    },
    config = function(_, opts)
      local ca = require("code-annotations")
      ca.setup(opts)
      -- setup より前に開き終わっているバッファにも付箋を描く
      ca.render_all()
    end,
  },
}

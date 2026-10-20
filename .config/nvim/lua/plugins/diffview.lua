-- GitHub の PR「Files changed」相当の diff ビューア。
--
-- fugitive の :Git diff は filetype=diff の1枚バッファなので、+/- の行色しか
-- 付かず(言語のシンタックスハイライトは原理的に効かない)、全ファイルが連結
-- されてファイル単位の移動もできない。
-- diffview は実ファイルのバッファを2枚並べるので treesitter がそのまま効く。
--
--   :G diff                 作業ツリー vs index/HEAD
--   :G diff HEAD~1          特定のコミットとの差分
--   :G diff main...HEAD     PR の diff と同じ3点リーチ
--   :G diffmain             上と同じ範囲を base 自動判定(origin/main 等)で開く
--   :G diffparent           stacked PR 用。親 PR のブランチ(PR の base)との差分だけを開く
--   :DiffviewFileHistory %  現在ファイルの履歴を同じ UI で追う
--
-- :G のルーティングは lua/plugins/editor.lua の fugitive 側にある。

return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewFileHistory",
    "DiffviewFocusFiles",
    "DiffviewToggleFiles",
    "DiffviewRefresh",
  },
  opts = function()
    local actions = require("diffview.actions")

    -- diff2_horizontal(左=変更前 / 右=変更後)と file_panel の tree 表示は
    -- どちらも diffview の既定値なので、ここでは上書きしていない。
    return {
      -- 行まるごとではなく、行内で実際に変わった箇所だけを強調する。
      -- GitHub の intra-line ハイライト相当。
      enhanced_diff_hl = true,
      view = {
        default = { winbar_info = true }, -- 各ペインが a/ か b/ かを winbar に出す
        file_history = { winbar_info = true },
      },
      file_panel = {
        win_config = { width = 40 },
      },
      keymaps = {
        view = {
          -- fugitive の status を gq で閉じている癖に合わせる。
          -- 右ペインは編集可能な実ファイルなので q(マクロ記録)は潰さない。
          { "n", "gq", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "<leader>gb", actions.toggle_files, { desc = "Toggle the file panel" } },
        },
        file_panel = {
          -- 既定の <CR> は set_file(item, false) で「開くがフォーカスはパネルに
          -- 残る」ため、そのまま j/<C-d> を押しても diff がスクロールしない。
          -- focus_entry (= set_file(item, true)) は右ペインまでカーソルを運ぶ。
          -- 一覧を眺めるだけの o / l は既定のまま(パネルに留まる)。
          { "n", "<cr>", actions.focus_entry, { desc = "Open the diff and jump into it" } },
          { "n", "<2-LeftMouse>", actions.focus_entry, { desc = "Open the diff and jump into it" } },
          -- パネルに居たまま diff を流し読みしたいときは既定の <C-f> / <C-b>。
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "gq", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "<leader>gb", actions.toggle_files, { desc = "Toggle the file panel" } },
        },
        file_history_panel = {
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "gq", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        },
      },
    }
  end,
}

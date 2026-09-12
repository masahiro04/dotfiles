-- PR の diff を AI CLI に「章」へ分割させて読み順にレビューするプラグイン。
--
--   ;g  :Storyline      base 自動検出(gh)でレビュー開始
--   ;G  :StorylinePick  base ブランチを選んでレビュー
--   ;l  :StorylineRead  diff なしでトピック単位にコードを読む
--   ;d  unified / split 切替 (storyline が開いたバッファ内のみ)
--
-- README のデフォルトキー(<leader>gs / <leader>sl / <leader>gl)は
-- Telescope Status / Location List / Lazygit Log と衝突するため ; 系に寄せている。

return {
  {
    "killinsun/storyline.nvim",
    dependencies = {
      "lewis6991/gitsigns.nvim",
      "sindrets/diffview.nvim", -- サイドバーの v でチャプター全体を diff 表示 (設定は plugins/diffview.lua)
    },
    cmd = {
      "Storyline",
      "StorylinePick",
      "StorylineRead",
      "StorylineRefresh",
      "StorylineClose",
      "StorylineBackend",
    },
    keys = {
      { ";g", "<cmd>Storyline<cr>", desc = "Storyline: レビュー開始" },
      { ";G", "<cmd>StorylinePick<cr>", desc = "Storyline: base を選んでレビュー" },
      { ";l", "<cmd>StorylineRead<cr>", desc = "Storyline: トピックでコードを読む" },
    },
    opts = {
      backend = "claude",
      keymaps = {
        toggle_layout = ";d", -- 既定の <leader>gl は Lazygit Log と衝突
        preview = "<Tab>",
      },
      prompts = {
        analyze_extra = "チャプターのタイトル・要約・レビュー観点はすべて日本語で書いてください。",
        read_extra = "トピック名と説明はすべて日本語で書いてください。",
        ask_extra = "日本語で回答してください。",
      },
    },
  },
}

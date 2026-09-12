-- markdown を装飾表示する。通常の .md バッファに加えて、
-- LSP hover (K) のフロートにも効く。
--
-- nvim 0.12 の open_floating_preview は hover のバッファに filetype=markdown を
-- 立てるので (runtime/lua/vim/lsp/util.lua)、render-markdown がそのまま attach する。
-- hover フロートは buftype=nofile なので overrides.buftype.nofile で個別に詰める。
-- 器 (枠・背景・タイトル) 側は lua/plugins/lsp-hover.lua を参照。
--
-- 色は lua/plugins/colorschema.lua の on_highlights で tokyonight に合わせている
-- (既定は H1Bg=DiffText のように diff 色にリンクされていて浮くため)。

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    -- hover フロートでも使うので ft 遅延ロードにはしない
    event = "VeryLazy",
    opts = {
      -- LazyVim の markdown extra が入れる headlines.nvim と役割が被るので、
      -- そちらは下で無効化している
      code = {
        -- コードブロックの背景をブロック幅のカードにする
        width = "block",
        min_width = 40,
        left_pad = 1,
        right_pad = 2,
        -- 上端に言語アイコン+名前を出し、``` の行は隠す (行数は増えない)
        border = "hide",
        language_pad = 1,
      },
      heading = {
        width = "block",
        min_width = 30,
        left_pad = 1,
        right_pad = 2,
      },
      bullet = {
        icons = { "●", "○", "◆", "◇" },
      },
      -- latex パーサも utftex/latex2text も入れていないので切る
      -- (:checkhealth render-markdown の警告対策)
      latex = { enabled = false },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
      overrides = {
        buftype = {
          -- LSP hover / signature help / cmp のドキュメントフロート
          nofile = {
            -- カーソル行だけ装飾が剥がれるのは、読み物としては邪魔なので切る
            -- (KK でフロートに入ってスクロールしたときにちらつく)
            anti_conceal = { enabled = false },
            -- フロートは横幅が狭いのでカード幅の下限を下げる
            code = { min_width = 20, left_pad = 1, right_pad = 1 },
            heading = { min_width = 10, left_pad = 1, right_pad = 1 },
            -- 余白の色をフロート本体の背景に合わせる
            -- (既定の RenderMarkdownPadding は Normal リンク = 透過)
            padding = { highlight = "LspFloatNormal" },
          },
        },
      },
    },
  },

  -- LazyVim の markdown extra が入れる headlines.nvim は
  -- render-markdown.nvim と見出し/コードブロック装飾が二重になるため無効化
  { "lukas-reineke/headlines.nvim", enabled = false },
}

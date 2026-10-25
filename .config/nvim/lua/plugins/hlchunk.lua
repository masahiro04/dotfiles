-- カーソル位置のブロック (関数・if・テーブルなど) を treesitter で判定し、
-- その範囲を ┌─┐ の線で囲って見せる。あわせてインデントガイドも
-- hlchunk 側に寄せるので、LazyVim 標準の indent-blankline は無効化する。
-- https://github.com/shellRaining/hlchunk.nvim

return {
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      chunk = {
        enable = true,
        -- tokyonight のアクセントに近い青。文法エラー中のブロックは赤
        style = {
          { fg = "#7aa2f7" },
          { fg = "#f7768e" },
        },
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = "─",
        },
        -- 移動のたびに線を描き直すアニメーションは切る
        duration = 0,
        delay = 0,
        exclude_filetypes = { review = true },
      },
      indent = {
        enable = true,
        chars = { "│" },
        style = { { fg = "#3b4261" } },
        exclude_filetypes = { review = true, markdown = true },
      },
      line_num = { enable = false },
      blank = { enable = false },
    },
  },
}

-- rounded な上下枠 + 左右は空白1桁 (= 内側パディング)。
-- FloatBorder の bg をフロート本体と同色にすることで余白として見える。
local BORDER = {
  { "╭", "FloatBorder" },
  { "─", "FloatBorder" },
  { "╮", "FloatBorder" },
  { " ", "FloatBorder" }, -- 右パディング
  { "╯", "FloatBorder" },
  { "─", "FloatBorder" },
  { "╰", "FloatBorder" },
  { " ", "FloatBorder" }, -- 左パディング
}

-- focus_id で hover / signature help を判別できる
-- (buf.lua: hover は "textDocument/hover"、signature_help は method 名)
local TITLES = {
  ["textDocument/hover"] = " 󰋖 Hover ",
  ["textDocument/signatureHelp"] = " 󰊕 Signature ",
}

local WINHL = table.concat({
  "Normal:LspFloatNormal",
  "FloatBorder:LspFloatBorder",
  "FloatTitle:LspFloatTitle",
  "CursorLine:LspFloatCursorLine",
}, ",")

return {
  "neovim/nvim-lspconfig",
  -- config ではなく init で仕込む (ラッパーは冪等でないため二重適用を避ける)
  init = function()
    local orig = vim.lsp.util.open_floating_preview

    vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
      opts = opts or {}
      -- 呼び出し側が明示している場合はそちらを尊重する
      opts.border = opts.border or BORDER
      opts.max_width = opts.max_width or 90
      opts.max_height = opts.max_height or 25
      if not opts.title and opts.focus_id and TITLES[opts.focus_id] then
        opts.title = TITLES[opts.focus_id]
        opts.title_pos = "center"
      end

      local buf, win = orig(contents, syntax, opts, ...)
      if win and vim.api.nvim_win_is_valid(win) then
        vim.wo[win].winhighlight = WINHL
        vim.wo[win].winblend = 0
        vim.wo[win].cursorline = false
        vim.wo[win].signcolumn = "no"
        vim.wo[win].scrolloff = 0
      end
      return buf, win
    end
  end,
}

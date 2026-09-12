-- LSP hover (K) / signature help (gK) のフロートの見た目を整える。
--
-- nvim 0.12 の vim.lsp.buf.hover() は vim.lsp.handlers["textDocument/hover"] を
-- 経由せず、buf_request_all + vim.lsp.util.open_floating_preview を直接呼ぶ
-- (runtime/lua/vim/lsp/buf.lua)。そのため noice の presets.lsp_doc_border は
-- 効かず、vim.o.winborder も未設定なので枠なし・背景なしのフロートになっていた。
--
-- 中身の描画自体は 0.12 が filetype=markdown + treesitter でやってくれるので、
-- ここでは「器」(枠・余白・タイトル・サイズ・専用ハイライト) だけを与える。
-- open_floating_preview は hover と signature help の共通経路なので、
-- ここ1点のラップで両方に効く。
-- noice が上書きするのは convert_input_to_markdown_lines だけなので競合しない。
-- LazyVim/noice を新しい版に更新できたら見直し可。

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

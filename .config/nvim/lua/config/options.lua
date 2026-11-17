-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Ruby extraでruby_lspではなく既存のsolargraphを使う
vim.g.lazyvim_ruby_lsp = "solargraph"

-- カーソルの色を Cursor ハイライトで決める(定義は lua/plugins/colorschema.lua)。
-- 既定の guicursor はハイライト未指定なので、Warp のテーマ色(赤)のまま描かれる
vim.opt.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor,t:block-blinkon500-blinkoff500-TermCursor"

-- nvim 0.11で削除された vim.lsp.util._str_utfindex_enc の互換シム。
-- lazy-lockで2024-07に固定しているtelescope.nvimが、LSPジャンプ
-- (telescope/builtin/__lsp.lua の item_to_location) でこれを呼ぶため。
-- telescope を vim.lsp.util.show_document ベースの版に更新できたら削除可。
if not vim.lsp.util._str_utfindex_enc then
  ---@diagnostic disable-next-line: inject-field
  vim.lsp.util._str_utfindex_enc = function(line, index, encoding)
    return vim.str_utfindex(line, encoding or "utf-16", index, false)
  end
end

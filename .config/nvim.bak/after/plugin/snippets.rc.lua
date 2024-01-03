local status, luasnip = pcall(require, 'luasnip')
if (not status) then return end

luasnip.filetype_extend("ruby", { "rails" })
luasnip.filetype_extend("javascript", { "javascriptreact" })
luasnip.filetype_extend("typescript", { "typescriptreact" })
luasnip.filetype_extend("typescript", { "typescript" })

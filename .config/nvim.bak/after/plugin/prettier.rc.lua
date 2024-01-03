local status, prettier = pcall(require, 'prettier')
if (not status) then return end

prettier.setup({
  bin = 'prettierd', -- or `'prettierd'` (v0.22+)
  filetypes = {
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "less",
    "markdown",
    "scss",
    "typescript",
    "typescriptreact",
    "yaml",
  },
})


-- vim.api.nvim_set_keymap('n', '<leader>f', [[:'<,'>! prettier --parser html --stdin-filepath<cr>]], { noremap = true, silent = true })

-- vim.api.nvim_set_keymap('v', '<leader>f', [[:'<,'>! prettier --parser html --stdin-filepath %<cr>]], { noremap = true, silent = true })

-- YewのHTMLparse用
vim.api.nvim_set_keymap('v', '<leader>f', [[:'<,'>! prettier --parser html --use-tabs --tab-width 4 --stdin-filepath %<cr>]], { noremap = true, silent = true })

local status, rust = pcall(require, 'rust-lang/rust.vim')
if (not rust) then return end

vim.g.rustfmt_autosave = 1

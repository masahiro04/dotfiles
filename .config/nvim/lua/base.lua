vim.cmd('autocmd!')

vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'
vim.opt.fileformats = 'dos,unix,mac'
vim.opt.mouse = 'a'
vim.wo.number = true

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.hlsearch = true
vim.opt.backup = false
vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.expandtab = true
vim.opt.backupskip = '/tmp/*,/private/tmp/*'

vim.opt.inccommand = 'split'
vim.opt.ignorecase = true
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ai = true -- auto indent
vim.opt.si = true -- smart indent
vim.opt.wrap = false -- no wrap lines
vim.opt.backspace = 'start,eol,indent'
vim.opt.path:append { '**' } -- Finding files - search down into subfolders
vim.opt.wildignore:append { '*/node_modules/*' } -- Finding files - search down into subfolders

vim.opt.timeoutlen = 200

-- undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
-- but this doesn't work on iTerm2

-- turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = '*',
  command = "set nopaste"
})

-- Add asterisks in block comments
vim.opt.formatoptions:append { 'r' }


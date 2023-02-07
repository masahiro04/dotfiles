local status, packer = pcall(require, 'packer')
if (not status) then
  print('Packer is not installed')
  return
end

vim.cmd [[packadd packer.nvim]]

packer.startup(function(use)
  use 'wbthomason/packer.nvim' -- Package manager
  use 'folke/tokyonight.nvim' -- Theme
  use 'hoob3rt/lualine.nvim' -- Statusline
  use 'nvim-lua/plenary.nvim' -- Common utilities
  use 'onsails/lspkind-nvim' -- vscode-like pictograms
  use 'hrsh7th/cmp-buffer' -- nvim-cmp source for buffer words
  use 'hrsh7th/cmp-nvim-lsp' -- nvim-cmp source for neovim's built-in LSP
  use 'hrsh7th/nvim-cmp' -- Completion
  use 'hrsh7th/cmp-nvim-lsp-signature-help' -- Shows sigunature help messages
  use 'neovim/nvim-lspconfig' -- LSP
  use { 'glepnir/lspsaga.nvim' } -- LSP UIs
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'
  use 'j-hui/fidget.nvim' -- Lsp loading indicator
  use 'MunifTanjim/prettier.nvim'
  use 'jose-elias-alvarez/null-ls.nvim' -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
  use 'kyazdani42/nvim-web-devicons' -- File icons
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-file-browser.nvim'
  use 'nvim-telescope/telescope-media-files.nvim'

  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' } -- Code color scheme
  -- use 'windwp/nvim-autopairs'
  use 'windwp/nvim-ts-autotag'
  use 'kylechui/nvim-surround' -- Surround text with selected charactors
  use 'akinsho/bufferline.nvim'
  use 'norcalli/nvim-colorizer.lua'
  use 'L3MON4D3/LuaSnip'
  use 'rafamadriz/friendly-snippets'
  use { 'numToStr/Comment.nvim', requires = { 'JoosepAlviste/nvim-ts-context-commentstring' } }
  use 'akinsho/toggleterm.nvim'
  use 'rlane/pounce.nvim' -- Easy motion
  use 'p00f/nvim-ts-rainbow' -- Rainbow parentheses
  use 'lewis6991/gitsigns.nvim' -- Show git change on buffers on left
  -- use { 'TimUntersberger/neogit', requires = 'nvim-lua/plenary.nvim' } -- Git client
  use 'akinsho/git-conflict.nvim' -- Git client to fix conflict
  use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' } -- Git diff view

  -- Vim scripts under this line
  use { 'ntpeters/vim-better-whitespace' }
  use { 'ElmCast/elm-vim', ft = { 'elm' } }
  use { 'simeji/winresizer' } -- Change buffer size
  use { 'tpope/vim-fugitive' }
  use { 'jiangmiao/auto-pairs' } -- Auto pairs
  use { 'nathanaelkane/vim-indent-guides' } -- Show indent
  use { 'iberianpig/tig-explorer.vim' }
  use { 'slim-template/vim-slim' } -- TODO: Add ft
  use { 'tpope/vim-rails' } -- TODO: Add ft
  use { 'rust-lang/rust.vim' }
-- [[plugins]]
-- repo = 'rust-lang/rust.vim'
-- on_ft = ['rust']
-- hook_add = '''
--   let g:rustfmt_autosave = 1
-- '''
  -- use {
  --   'prettier/vim-prettier',
  --   run = function()
  --     print('luadesu!!!')
  --     vim.g['prettier#autoformat'] = 1
  --     vim.g['prettier#quickfix_enabled'] = 0
  --   end,
  --   ft = { 'tsx', 'ts', 'js', 'typescript', 'typescriptreact' }
  --
  -- } -- Prettier
end)

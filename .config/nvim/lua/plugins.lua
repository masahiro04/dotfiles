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
  use 'hrsh7th/cmp-path' -- nvim-cmp source for filesystem paths.
  use 'hrsh7th/cmp-nvim-lsp' -- nvim-cmp source for neovim's built-in LSP
  use 'hrsh7th/nvim-cmp' -- Completion
  use 'hrsh7th/cmp-nvim-lsp-signature-help' -- Shows sigunature help messages
  use 'neovim/nvim-lspconfig' -- LSP
  -- 最新版だとエラーが出るのでcommit指定してる
  use { 'glepnir/lspsaga.nvim', commit = '335805d4f591f5bb71cabb6aa4dc58ccef8e8617' } -- LSP UIs
  -- use { 'glepnir/lspsaga.nvim' } -- LSP UIs
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'
  use { 'j-hui/fidget.nvim', tag = 'legacy' } -- Lsp loading indicator
  use 'MunifTanjim/prettier.nvim'
  use 'jose-elias-alvarez/null-ls.nvim' -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
  use 'kyazdani42/nvim-web-devicons' -- File icons
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-file-browser.nvim'
  -- use { 'nvim-treesitter/nvim-treesitter' } -- Code color scheme
  use {
    'nvim-treesitter/nvim-treesitter',
  }
  use 'windwp/nvim-autopairs'
  use 'kylechui/nvim-surround' -- Surround text with selected charactors
  use 'akinsho/bufferline.nvim'
  use 'norcalli/nvim-colorizer.lua'
  -- use 'L3MON4D3/LuaSnip'
  use 'rafamadriz/friendly-snippets'
  use { 'numToStr/Comment.nvim', requires = { 'JoosepAlviste/nvim-ts-context-commentstring' } }
  -- use { 'numToStr/Comment.nvim' }
  use 'akinsho/toggleterm.nvim'
  use 'rlane/pounce.nvim' -- Easy motion
  use 'lewis6991/gitsigns.nvim' -- Show git change on buffers on left
  use 'akinsho/git-conflict.nvim' -- Git client to fix conflict
  use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' } -- Git diff view
  -- Image viewer
  use { 'samodostal/image.nvim', requires = { 'nvim-lua/plenary.nvim' } }
  use { 'github/copilot.vim' }

  -- Vim scripts under this line
  use { 'ntpeters/vim-better-whitespace' }
  use { 'ElmCast/elm-vim', ft = { 'elm' } }
  use { 'simeji/winresizer' } -- Change buffer size
  use { 'tpope/vim-fugitive' } -- git
  -- use { 'jiangmiao/auto-pairs' } -- Auto pairs
  use { 'nathanaelkane/vim-indent-guides' } -- Show indent
  use { 'iberianpig/tig-explorer.vim' }
  use { 'slim-template/vim-slim' } -- TODO: Add ft
  use { 'tpope/vim-rails' } -- TODO: Add ft
  use { 'rust-lang/rust.vim' }
  use { 'zah/nim.vim' } -- Nim syntax highlighter
  use { 'hashivim/vim-terraform' } -- Terraform formatter
  use { 'chrisbra/csv.vim' } -- CSV visualizer
end)

return {
  -- Rubyのtreesitterパーサーを追加
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "ruby" })
    end,
  },
  -- Masonでsolargraphを自動インストール・管理
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "solargraph" })
    end,
  },
  -- solargraphのLSP設定
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        solargraph = {
          settings = {
            solargraph = {
              diagnostics = true,
              completion = true,
              formatting = false, -- rubocop側で管理するため無効
            },
          },
        },
      },
    },
  },
}

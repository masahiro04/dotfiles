return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })
      opts.presets.lsp_doc_border = true
    end,
  },
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 10000,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        -- globalstatus = false,
        theme = "solarized_dark",
      },
    },
  },
  {
    "b0o/incline.nvim",
    event = "BufReadPre",
    priority = 1200,
    config = function()
      require("incline").setup({})
    end,
  },
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function(_, opts)
      local logo = [[
        ███╗   ███╗    ██████╗ ██╗  ██╗██╗   ██╗██████╗  ██████╗ 
        ████╗ ████║   ██╔═══██╗██║ ██╔╝██║   ██║██╔══██╗██╔═══██╗
        ██╔████╔██║   ██║   ██║█████╔╝ ██║   ██║██████╔╝██║   ██║
        ██║╚██╔╝██║   ██║   ██║██╔═██╗ ██║   ██║██╔══██╗██║   ██║
        ██║ ╚═╝ ██║██╗╚██████╔╝██║  ██╗╚██████╔╝██████╔╝╚██████╔╝
        ╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ 
      ]]

      logo = string.rep("\n", 8) .. logo .. "\n\n"
      opts.config.header = vim.split(logo, "\n")
    end,
  },
}

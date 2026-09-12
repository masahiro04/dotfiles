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
      -- `:` のコマンドラインを画面上端から少し下げる。
      local cmdline_row = 10
      opts.views = vim.tbl_deep_extend("force", opts.views or {}, {
        cmdline_popup = { position = { row = cmdline_row } },
        cmdline_popupmenu = { position = { row = cmdline_row + 3 } },
      })
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
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      window = {
        mappings = {
          -- カーソル下のファイルをブラウザで開く(PNGプレビュー用)
          -- LazyVim標準の O(システムアプリで開く)を上書きしている
          ["O"] = {
            function(state)
              local node = state.tree:get_node()
              if node and node.type == "file" then
                require("browser_preview").open(node.path)
              end
            end,
            desc = "Open in browser",
          },
        },
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

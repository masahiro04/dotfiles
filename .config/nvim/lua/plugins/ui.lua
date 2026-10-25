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
      -- 通知を右上ではなく右下に出す(上端だとコードが隠れて読みにくいため)
      top_down = false,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        -- globalstatus = false,
        theme = "nightfly",
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      close_if_last_window = true,
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
      local helpers = require("incline.helpers")
      -- LazyVim は mini.icons を nvim-web-devicons として package.preload 済みなので、
      -- nvim-tree/nvim-web-devicons を別途入れる必要はない
      local devicons = require("nvim-web-devicons")

      require("incline").setup({
        window = {
          padding = 0,
          margin = { horizontal = 0 },
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if filename == "" then
            filename = "[No Name]"
          end
          local ft_icon, ft_color = devicons.get_icon_color(filename)
          local modified = vim.bo[props.buf].modified

          -- tokyonight は transparent なので、incline だけ不透明な帯にして浮かせる
          local bg = "#292e42" -- tokyonight bg_highlight

          return {
            -- devicons はアイコンだけ返して色が nil のことがあるので、両方揃った時だけ色付きにする
            (ft_icon and ft_color)
                and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) }
              or "",
            " ",
            { filename, gui = modified and "bold,italic" or "bold" },
            " ",
            guibg = bg,
          }
        end,
      })
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

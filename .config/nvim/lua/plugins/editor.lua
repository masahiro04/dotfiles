return {
  {
    enabled = false,
    "folke/flash.nvim",
    ---@type Flash.Config
    opts = {
      search = {
        forward = true,
        multi_window = false,
        wrap = false,
        incremental = true,
      },
    },
  },
  -- easy motion
  { "rlane/pounce.nvim" },
  {
    -- window resizer
    "simeji/winresizer",
  },
  {
    -- show whitespace -> vim script not lua
    "ntpeters/vim-better-whitespace",
    -- vimscript プラグインなので、読み込み前に g: を立てる必要がある
    init = function()
      -- プラグイン側は「buftype が空のバッファのみ対象」という作りだが、
      -- dashboard のように filetype 確定と buftype 設定のタイミングがずれる
      -- UI バッファは判定をすり抜けて全面が赤くなる。
      -- (dashboard は中央寄せのため各行を空白でパディングしている)
      -- ブラックリストは上書き指定なので、プラグイン既定値も含めて並べる。
      vim.g.better_whitespace_filetypes_blacklist = {
        -- プラグイン既定
        "diff",
        "git",
        "gitcommit",
        "unite",
        "qf",
        "help",
        "markdown",
        "fugitive",
        -- 編集対象ではない UI バッファ
        "dashboard",
        "alpha",
        "snacks_dashboard",
        "lazy",
        "mason",
        "neo-tree",
        "TelescopePrompt",
        "TelescopeResults",
        "trouble",
        "toggleterm",
        "checkhealth",
        "lspinfo",
        "man",
        "notify",
        "noice",
      }
    end,
  },
  {
    -- nvim-surroundを利用するので使わない方で
    "echasnovski/mini.surround",
    enabled = false,
  },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end,
  },
  {
    "tpope/vim-fugitive",
    config = function()
      -- :G(引数なし)は新しいタブで全画面表示する。
      -- log / show も全画面タブで開く。
      -- diff だけは diffview.nvim に流す(設定は plugins/diffview.lua)。
      --   fugitive の diff は filetype=diff の1枚バッファでシンタックス
      --   ハイライトが効かないため、GitHub の PR に近い2カラム表示にしている。
      --   fugitive 版が欲しいときは :G! diff で従来どおり。
      -- :G blame などそれ以外の引数ありは従来どおり fugitive の :Git に流す
      local fullscreen_subcommands = { log = true, show = true }

      -- :G diffmain 用の base ブランチ解決。
      -- origin/main → origin/master → origin/HEAD(リモートの既定ブランチ)の順で
      -- 最初に存在したものを返す。repo によって base が main とは限らないため。
      local function resolve_base_branch()
        for _, ref in ipairs({ "origin/main", "origin/master" }) do
          vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", ref })
          if vim.v.shell_error == 0 then
            return ref
          end
        end
        local head = vim.fn.system({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })
        if vim.v.shell_error == 0 then
          return vim.trim(head)
        end
        return nil
      end

      vim.api.nvim_create_user_command("G", function(cmd)
        local sub, rest = cmd.args:match("^(%S+)%s*(.*)$")
        if cmd.args == "" then
          vim.cmd("tab Git")
        elseif sub == "diff" and not cmd.bang then
          -- 引数はそのまま渡す (:G diff HEAD~1 / :G diff main...HEAD)
          vim.cmd("DiffviewOpen " .. rest)
        elseif sub == "diffmain" then
          -- 現在ブランチと base ブランチの3点リーチ差分(= GitHub の PR と同じ範囲)。
          -- リモート基準なので、手元が古いときは先に git fetch しておくこと
          -- (待ち時間を嫌ってコマンド側では fetch しない)。
          -- 作業ツリーの未コミット分は含まない(HEAD までの比較)。
          local base = resolve_base_branch()
          if not base then
            vim.notify("base ブランチ(origin/main など)が見つかりません", vim.log.levels.ERROR)
            return
          end
          local range = base .. "...HEAD"
          if cmd.bang then
            -- :G! diff と同じく、bang は従来の fugitive 版 diff に流す
            vim.cmd("Git! diff " .. range)
          else
            vim.cmd("DiffviewOpen " .. range)
          end
        elseif fullscreen_subcommands[sub] then
          vim.cmd("tab Git " .. cmd.args)
        else
          vim.cmd("Git" .. (cmd.bang and "!" or "") .. " " .. cmd.args)
        end
      end, { nargs = "*", bang = true, complete = "customlist,fugitive#Complete" })

      -- status画面(:G)で <CR>・ダブルクリックしたファイルは
      -- 分割ではなく新しいタブで全画面表示する(fugitive の O と同じ動き)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fugitive",
        callback = function(ev)
          vim.keymap.set("n", "<CR>", "O", { buffer = ev.buf, remap = true, desc = "Open in new tab" })
          vim.keymap.set("n", "<2-LeftMouse>", "O", { buffer = ev.buf, remap = true, desc = "Open in new tab" })
        end,
      })
    end,
  },
  -- {
  --   "smjonas/inc-rename.nvim",
  --   config = function()
  --     require("inc_rename").setup()
  --   end,
  -- },
  {
    "filipdutescu/renamer.nvim",
    config = function()
      require("renamer").setup()
    end,
  },
  {
    "telescope.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      "nvim-telescope/telescope-file-browser.nvim",
    },
    keys = {
      {
        "<leader>fP",
        function()
          require("telescope.builtin").find_files({
            cwd = require("lazy.core.config").options.root,
          })
        end,
        desc = "Find Plugin File",
      },
      {
        ";f",
        function()
          local builtin = require("telescope.builtin")
          builtin.find_files({
            no_ignore = false,
            hidden = true,
          })
        end,
        desc = "Lists files in your current working directory, respects .gitignore",
      },
      {
        ";r",
        function()
          local builtin = require("telescope.builtin")
          builtin.live_grep()
        end,
        desc = "Search for a string in your current working directory and get results live as you type, respects .gitignore",
      },
      {
        "\\\\",
        function()
          local builtin = require("telescope.builtin")
          builtin.buffers({
            initial_mode = "normal",
          })
        end,
        desc = "Lists open buffers",
      },
      {
        ";t",
        function()
          local builtin = require("telescope.builtin")
          builtin.help_tags()
        end,
        desc = "Lists available help tags and opens a new window with the relevant help info on <cr>",
      },
      {
        ";;",
        function()
          local builtin = require("telescope.builtin")
          builtin.resume()
        end,
        desc = "Resume the previous telescope picker",
      },
      {
        ";e",
        function()
          local builtin = require("telescope.builtin")
          builtin.diagnostics()
        end,
        desc = "Lists Diagnostics for all open buffers or a specific buffer",
      },
      {
        ";s",
        function()
          local builtin = require("telescope.builtin")
          builtin.treesitter()
        end,
        desc = "Lists Function names, variables, from Treesitter",
      },
      -- open current dir
      {
        ";c",
        function()
          local telescope = require("telescope")

          local function telescope_buffer_dir()
            return vim.fn.expand("%:p:h")
          end

          local fb_actions = require("telescope").extensions.file_browser.actions

          telescope.extensions.file_browser.file_browser({
            path = "%:p:h",
            cwd = telescope_buffer_dir(),
            respect_gitignore = false,
            hidden = true,
            grouped = true,
            previewer = true,
            initial_mode = "normal",
          })
        end,
        desc = "Open File Browser with the path of the current buffer",
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local fb_actions = require("telescope").extensions.file_browser.actions

      -- telescope のプレビューは filetype "tf" のまま treesitter を起動しようと
      -- するが、パーサー名は "terraform" なので別名として登録しておく
      vim.treesitter.language.register("terraform", "tf")

      -- nvim 0.11+ では vim.treesitter.language.add() がエラーを投げず
      -- nil を返す仕様になったため、pcall だけで判定している telescope の
      -- has_ts_parser がパーサー未インストールでも true を返してしまい、
      -- プレビューで `Parser could not be created` のエラーになる。
      -- 戻り値まで見るように上書きする。telescope 更新後に不要なら削除可。
      require("telescope.utils").has_ts_parser = function(lang)
        local ok, added = pcall(vim.treesitter.language.add, lang)
        return ok and added ~= nil and added ~= false
      end

      -- Tabで複数選択したファイルをEnterでまとめてバッファとして開く
      -- 選択がないときは従来どおり(ファイルを開く/ディレクトリに入る)
      local function fb_open_selected(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        if vim.tbl_isempty(selections) then
          actions.select_default(prompt_bufnr)
          return
        end
        actions.close(prompt_bufnr)
        for _, entry in ipairs(selections) do
          if vim.fn.isdirectory(entry.path) == 0 then
            vim.cmd.edit(vim.fn.fnameescape(entry.path))
          end
        end
      end

      -- カーソル下のエントリをブラウザで開く(PNGプレビュー用。pickerは開いたまま)
      local function open_entry_in_browser()
        local entry = action_state.get_selected_entry()
        if entry == nil then
          return
        end
        local path = entry.path or entry.filename or entry.value
        if path and vim.fn.isdirectory(path) == 0 then
          require("browser_preview").open(path)
        end
      end

      -- カーソル下のエントリの相対パスをクリップボードにコピー(pickerは開いたまま)
      local function copy_entry_path()
        local entry = action_state.get_selected_entry()
        if entry == nil then
          return
        end
        local path = vim.fn.fnamemodify(entry.path or entry.filename or entry.value, ":.")
        vim.fn.setreg("+", path)
        vim.notify("Copied: " .. path)
      end

      opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
        wrap_results = true,
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
          horizontal = {
            width = 0.99,
            height = 0.99,
            preview_width = 0.55,
          },
        },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          i = {
            ["<C-y>"] = copy_entry_path,
          },
          n = {
            ["<C-y>"] = copy_entry_path,
          },
        },
      })
      opts.pickers = {
        diagnostics = {
          theme = "ivy",
          initial_mode = "normal",
          layout_config = {
            preview_cutoff = 9999,
          },
        },
      }
      opts.extensions = {
        file_browser = {
          -- disables netrw and use telescope-file-browser in its place
          hijack_netrw = true,
          mappings = {
            -- your custom insert mode mappings
            ["i"] = {
              ["<CR>"] = fb_open_selected,
            },
            ["n"] = {
              ["<CR>"] = fb_open_selected,
              -- your custom normal mode mappings
              ["O"] = open_entry_in_browser,
              ["N"] = fb_actions.create,
              ["h"] = fb_actions.goto_parent_dir,
              ["/"] = function()
                vim.cmd("startinsert")
              end,
              ["<C-u>"] = function(prompt_bufnr)
                for i = 1, 10 do
                  actions.move_selection_previous(prompt_bufnr)
                end
              end,
              ["<C-d>"] = function(prompt_bufnr)
                for i = 1, 10 do
                  actions.move_selection_next(prompt_bufnr)
                end
              end,
              ["<PageUp>"] = actions.preview_scrolling_up,
              ["<PageDown>"] = actions.preview_scrolling_down,
            },
          },
        },
      }
      telescope.setup(opts)
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("file_browser")
    end,
  },
}

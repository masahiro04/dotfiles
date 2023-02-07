local status, telescope = pcall(require, 'telescope')
if (not status) then return end

local actions = require('telescope.actions')
local builtin = require('telescope.builtin')
local fb_actions = require "telescope".extensions.file_browser.actions
local media_actions = require "telescope".load_extension('media_files')

local function telescope_buffer_dir()
  return vim.fn.expand('%:p:h')
end

telescope.setup {
  defaults = {
    file_ignore_patterns = { "node_modules", ".git/" },
    mappings = {
      n= {
        ["q"] = actions.close,
        ["<C-n>"] = actions.send_selected_to_qflist + actions.open_qflist,
      }
    },
  },
  pickers = {},
  extensions = {
    file_browser = {
      theme = "dropdown",
      -- disables netrw and use telescope-file-browser in its place
      hijack_netrw = true,
      mappings = {
        -- your custom insert mode mappings
        ["i"] = {
          ["<C-w>"] = function() vim.cmd('normal vbd') end,
        },
        ["n"] = {
          -- your custom normal mode mappings
          ["n"] = fb_actions.create,
          ["c"] = fb_actions.copy,
          ["r"] = fb_actions.rename,
          ["d"] = fb_actions.remove,
          ["h"] = fb_actions.goto_parent_dir,
          ["i"] = function()
            vim.cmd('startinsert')
          end
        },
      },
    },
    media_files = {
      -- filetypes whitelist
      -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
      filetypes = {"png", "webp", "jpg", "jpeg"},
      find_cmd = "rg" -- find command (defaults to `fd`)
    }
  },
}

telescope.load_extension("file_browser")

vim.keymap.set('n', 'ff',
  function()
    builtin.find_files({
      no_ignore = false,
      hidden = true
    })
  end)
vim.keymap.set('n', 'fg', function()
  builtin.live_grep()
end)
vim.keymap.set('n', 'fb', function()
  builtin.buffers()
end)
vim.keymap.set('n', 'fh', function()
  builtin.help_tags()
end)
vim.keymap.set('n', ';;', function()
  builtin.resume()
end)
vim.keymap.set('n', ';e', function()
  builtin.diagnostics()
end)

vim.keymap.set('n', ';c', function()
    builtin.git_commits({
      initial_mode = "normal",
    })
end)
vim.keymap.set('n', ';s', function()
    builtin.git_status({
      initial_mode = "normal",
    })
end)

vim.keymap.set("n", "<C-e>", function()
  telescope.extensions.file_browser.file_browser({
    path = "%:p:h",
    cwd = telescope_buffer_dir(),
    respect_gitignore = false,
    hidden = true,
    grouped = true,
    -- previewer = false,
    initial_mode = "normal",
    layout_config = { height = 30 }
  })
end)

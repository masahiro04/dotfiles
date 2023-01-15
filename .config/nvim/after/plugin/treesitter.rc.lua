local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

ts.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = true,
    disable = {},
  },
  ensure_installed = {
    "c",
    "cmake",
    "css",
    "dart",
    "dot",
    "go",
    "gomod",
    "graphql",
    "html",
    "elm",
    "json",
    "java",
    "javascript",
    "kotlin",
    "lua",
    "make",
    "markdown",
    "python",
    "ruby",
    "rust",
    "swift",
    "scss",
    "sql",
    "typescript",
    "tsx",
    "toml",
    "vim",
    "yaml"
  },
  autotag = {
    enable = true,
  },
}

local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }

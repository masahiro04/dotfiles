-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- local dscipline = require("discipline")
-- dscipline.cowboy()
-- local discipline = require("masahiro.disciplie")
-- discipline.cowboy()

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

--- Do not yank with x
keymap.set("n", "x", '"_x')

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Delete a word backwards
keymap.set("n", "dw", 'vb"_d')

-- Select alL
keymap.set("n", "<C-a>", "gg<S-v>G")

-- New tab
keymap.set("n", "te", ":tabedit<Return>", { silent = true })
-- Split window
keymap.set("n", "ss", ":split<Return><C-w>w", opts)
keymap.set("n", "sv", ":vsplit<Return><C-w>w", opts)

-- Change buffers
keymap.set("n", "bp", ":bprev<CR>", { silent = true })
keymap.set("n", "bn", ":bnext<CR>", { silent = true })
keymap.set("n", "bd", ":bdelete<CR>", { silent = true })

-- Move window
keymap.set("n", "<Space>", "<C-w>w")
keymap.set("", "s<left>", "<C-w>h")
keymap.set("", "s<up>", "<C-w>k")
keymap.set("", "s<down>", "<C-w>j")
keymap.set("", "s<right>", "<C-w>l")
keymap.set("", "sh", "<C-w>h")
keymap.set("", "sk", "<C-w>k")
keymap.set("", "sj", "<C-w>j")
keymap.set("", "sl", "<C-w>l")

-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- Highlight
keymap.set("n", "nh", ":nohl<CR>")

-- Escape
keymap.set("i", "jj", "<ESC>", { silent = true })

-- Pounce
keymap.set("", "qq", "<cmd>Pounce<CR>")

-- NeoGit
keymap.set("", "git", "<cmd>Neogit<CR>")

-- DiffView
keymap.set("", "do", "<cmd>DiffviewOpen<CR>")
keymap.set("", "dc", "<cmd>DiffviewClose<CR>")

-- Diagnostics
keymap.set("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)

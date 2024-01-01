local status, tokyonight = pcall(require, 'tokyonight')
if (not status) then return end

tokyonight.setup ({
  style = 'moon',
  light_style = 'day',
  transparent = true, -- Enable this to disable setting the background color
})

vim.cmd[[colorscheme tokyonight]]

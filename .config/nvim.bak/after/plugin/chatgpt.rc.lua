local status, chatgpt = pcall(require, 'chatgpt')
if (not status) then return end

chatgpt.setup({
  disable_filetype = { 'TelescopePrompt' , 'vim' },
})

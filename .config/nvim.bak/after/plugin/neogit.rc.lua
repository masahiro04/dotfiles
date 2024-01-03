local status, git = pcall(require, 'neogit')
if (not status) then return end

git.setup {}

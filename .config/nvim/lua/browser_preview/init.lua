-- ファイル(PNG等の画像)をブラウザで開くための自前プラグイン。
--
--   <leader>ob            現在のバッファのファイルをブラウザで開く
--   :BrowserPreview [path] 指定パス(省略時は現在のファイル)をブラウザで開く
--
-- neo-tree / telescope-file-browser からは `O` で
-- カーソル下のファイルをブラウザで開ける(各プラグイン側で配線)。

local M = {}

M.config = {
  -- 上から順に /Applications・~/Applications を探して最初に見つかったものを使う。
  -- 特定のブラウザに固定したい場合は setup({ browsers = { "Safari" } }) のように上書きする
  browsers = { "Google Chrome", "Arc", "Brave Browser", "Microsoft Edge", "Safari" },
}

---インストール済みのブラウザ名を返す(macOS用)
---@return string|nil
local function find_browser()
  for _, name in ipairs(M.config.browsers) do
    local app = name .. ".app"
    if
      vim.fn.isdirectory("/Applications/" .. app) == 1
      or vim.fn.isdirectory(vim.fn.expand("~/Applications/") .. app) == 1
    then
      return name
    end
  end
  return nil
end

---ファイルをブラウザで開く
---@param path? string 省略時は現在のバッファのファイル
function M.open(path)
  path = path and vim.fn.expand(path) or vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("BrowserPreview: 開くファイルがありません", vim.log.levels.WARN)
    return
  end
  path = vim.fn.fnamemodify(path, ":p")
  if vim.fn.filereadable(path) == 0 then
    vim.notify("BrowserPreview: ファイルが読めません: " .. path, vim.log.levels.ERROR)
    return
  end

  if vim.fn.has("mac") == 0 then
    -- macOS以外はOSのデフォルトの開き方に任せる
    vim.ui.open(path)
    return
  end

  local browser = find_browser()
  if not browser then
    vim.notify("BrowserPreview: ブラウザが見つかりません", vim.log.levels.ERROR)
    return
  end
  vim.fn.jobstart({ "open", "-a", browser, path }, { detach = true })
  vim.notify("BrowserPreview: " .. browser .. " で開きました: " .. vim.fn.fnamemodify(path, ":."))
end

---@param opts? { browsers?: string[] }
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.api.nvim_create_user_command("BrowserPreview", function(cmd)
    M.open(cmd.args ~= "" and cmd.args or nil)
  end, { nargs = "?", complete = "file", desc = "Open file in browser" })

  vim.keymap.set("n", "<leader>ob", function()
    M.open()
  end, { desc = "Open current file in browser" })
end

return M

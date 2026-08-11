-- 「あのコマンド何だっけ」を引くための自前チートシート。
--
--   ;?            あいまい検索(Telescope。無ければ一覧にフォールバック)
--   ;k            全件をフローティングウィンドウで一覧(`/` で検索できる)
--   :Cheat [語]   ;? と同じ。引数があれば検索語をプリセット
--   :CheatList [カテゴリ]  一覧。カテゴリ名は <Tab> 補完できる
--
-- ピッカー内:
--   <CR>   `:` コマンドならコマンドラインに流し込む(実行はしない) / キーならクリップボードへ
--   <C-y>  キー・コマンドをクリップボードにコピー
--   <C-h>  対応する :help を開く

local M = {}

local GROUPS = require("cheatsheet.data")

---すべてのエントリを1次元配列にして返す
---@param category? string カテゴリ名(部分一致)で絞り込む
---@return table[]
function M.items(category)
  local items = {}
  for _, group in ipairs(GROUPS) do
    if not category or category == "" or group.name:lower():find(category:lower(), 1, true) then
      for _, item in ipairs(group.items) do
        table.insert(items, {
          cat = group.name,
          keys = item.keys,
          desc = item.desc,
          mode = item.mode or "n",
          tags = item.tags,
          help = item.help,
        })
      end
    end
  end
  return items
end

---カテゴリ名の一覧
---@return string[]
function M.categories()
  return vim.tbl_map(function(group)
    return group.name
  end, GROUPS)
end

---エントリを選んだときの動作
---@param item table
local function on_select(item)
  if item.keys:sub(1, 1) == ":" then
    -- コマンドラインに流し込むだけ。<CR> は送らないので編集してから実行できる
    vim.schedule(function()
      vim.api.nvim_feedkeys(item.keys, "n", false)
    end)
  else
    vim.fn.setreg("+", item.keys)
    vim.notify(item.keys .. "  →  " .. item.desc .. "  (クリップボードにコピー)")
  end
end

---:help を開く
---@param item table
local function open_help(item)
  if not item.help then
    vim.notify("このエントリには :help タグが登録されていません", vim.log.levels.WARN)
    return
  end
  local ok, err = pcall(vim.cmd, "help " .. item.help)
  if not ok then
    vim.notify("ヘルプが見つかりません: " .. item.help .. " (" .. tostring(err) .. ")", vim.log.levels.WARN)
  end
end

---Telescope でのあいまい検索
---@param query? string
---@return boolean 起動できたか
local function open_telescope(query)
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    return false
  end
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  local items = M.items()

  local keys_width, cat_width = 0, 0
  for _, item in ipairs(items) do
    keys_width = math.max(keys_width, vim.fn.strdisplaywidth(item.keys))
    cat_width = math.max(cat_width, vim.fn.strdisplaywidth(item.cat))
  end

  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = math.min(keys_width, 26) },
      { width = cat_width },
      { remaining = true },
    },
  })

  local function with_selected(prompt_bufnr, fn, close)
    local entry = action_state.get_selected_entry()
    if not entry then
      return
    end
    if close then
      actions.close(prompt_bufnr)
    end
    fn(entry.value)
  end

  pickers
    .new({}, {
      prompt_title = "Vim チートシート",
      default_text = query,
      finder = finders.new_table({
        results = items,
        entry_maker = function(item)
          return {
            value = item,
            ordinal = table.concat({ item.keys, item.desc, item.tags or "", item.cat, item.mode }, " "),
            display = function(entry)
              return displayer({
                { entry.value.keys, "TelescopeResultsIdentifier" },
                { entry.value.cat, "TelescopeResultsComment" },
                entry.value.desc,
              })
            end,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = false,
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          with_selected(prompt_bufnr, on_select, true)
        end)
        for _, mode in ipairs({ "i", "n" }) do
          -- 他の picker では相対パスのコピーに使っているキーを、ここではエントリのコピーに使う
          map(mode, "<C-y>", function()
            with_selected(prompt_bufnr, function(item)
              vim.fn.setreg("+", item.keys)
              vim.notify("Copied: " .. item.keys)
            end, false)
          end)
          map(mode, "<C-h>", function()
            with_selected(prompt_bufnr, open_help, true)
          end)
        end
        return true
      end,
    })
    :find()

  return true
end

---フローティングウィンドウでの一覧表示
---@param category? string
function M.list(category)
  local lines = {}
  local current = nil

  if category and category ~= "" then
    table.insert(lines, "# チートシート: " .. category)
  else
    table.insert(lines, "# Vim チートシート  (`/` で検索、`q` で閉じる)")
  end
  table.insert(lines, "")
  table.insert(lines, "※ <leader> は Space。`<Space>` 単体にウィンドウ移動が割り当ててあるので、")
  table.insert(lines, "  leader 系は timeoutlen(300ms) 以内に続けて押すこと。")
  table.insert(lines, "")

  for _, item in ipairs(M.items(category)) do
    if item.cat ~= current then
      current = item.cat
      table.insert(lines, "")
      table.insert(lines, "## " .. current)
    end
    local mode = item.mode == "n" and "   " or string.format("%-3s", item.mode)
    table.insert(lines, string.format("  %s %-26s %s", mode, item.keys, item.desc))
  end

  if #M.items(category) == 0 then
    table.insert(lines, "")
    table.insert(lines, "  該当するカテゴリがありません: " .. tostring(category))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width + 2, math.floor(vim.o.columns * 0.9))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.85))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " cheatsheet ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].conceallevel = 0

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, nowait = true, silent = true })
  end
end

---あいまい検索を開く(Telescope が無ければ一覧を出す)
---@param query? string
function M.open(query)
  if not open_telescope(query) then
    vim.notify("Telescope が使えないので一覧表示にします", vim.log.levels.INFO)
    M.list()
  end
end

---コマンドとキーマップを登録する
function M.setup()
  vim.api.nvim_create_user_command("Cheat", function(cmd)
    M.open(cmd.args ~= "" and cmd.args or nil)
  end, { nargs = "*", desc = "Vim チートシートを検索" })

  vim.api.nvim_create_user_command("CheatList", function(cmd)
    M.list(cmd.args ~= "" and cmd.args or nil)
  end, {
    nargs = "?",
    desc = "Vim チートシートを一覧表示",
    complete = function(arg_lead)
      return vim.tbl_filter(function(name)
        return name:find(arg_lead, 1, true) ~= nil
      end, M.categories())
    end,
  })

  vim.keymap.set("n", ";?", function()
    M.open()
  end, { desc = "Cheatsheet: あいまい検索" })

  vim.keymap.set("n", ";k", function()
    M.list()
  end, { desc = "Cheatsheet: 一覧" })
end

return M

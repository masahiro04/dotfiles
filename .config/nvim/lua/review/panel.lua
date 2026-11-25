-- review のサイドパネル。ローカルコメントと PR スレッドをファイル順に並べ、
-- Telescope を閉じずに (開き直さずに) その場で展開・返信・resolve・編集・削除する。
--
--   <leader>aL / :Review panel   パネルを開く / 閉じる (開いていてフォーカスが別なら移動)
--
--   パネル内のキー
--   <CR>          対象行へジャンプ (パネルは開いたまま)
--   o             対象行を表示するがカーソルはパネルに残す
--   <Tab> / za    本文と対象コードを展開 / 折りたたみ      <S-Tab>  全部まとめて
--   <C-n> <C-p>   次 / 前の項目 (]] [[ でも可)
--   r             スレッドに返信 (即時公開・確認あり)
--   x             スレッドを resolved / unresolved
--   a             この行にローカルコメントを付ける (ファイル側へ移動して入力)
--   e / d         ローカルコメントを編集 / 削除 (削除は確認あり)
--   y             本文を Markdown でヤンク (+ レジスタ)
--   gx            GitHub でスレッドを開く
--   P             ローカルコメントを PR にドラフトレビューとして投稿
--   R             PR スレッドを再取得
--   f             resolved なスレッドを隠す / 出す
--   ?             このキー一覧
--   q             閉じる
--
-- 本文は Markdown として treesitter で色付けし、render-markdown が入っていれば
-- その装飾も効く (filetype は "review"、パーサは markdown を流用)。
-- コメントの保存・スレッドの再取得が起きると自動で描き直す (review 側の _listeners)。

local api = vim.api
local M = {}

local ns = api.nvim_create_namespace("review_panel")
local augroup = api.nvim_create_augroup("review_panel", { clear = true })

---本体モジュール。循環 require を避けるため使う時に読む
local function review()
  return require("review")
end
local function A()
  return require("review")._api
end

---@class ReviewPanelItem
---@field kind "thread"|"comment"|"file"
---@field key string
---@field file string
---@field s integer
---@field e integer
---@field thread? ReviewThread
---@field comment? ReviewComment
---@field mine? boolean

---@class ReviewPanelState
---@field root string
---@field buf integer
---@field win integer|nil
---@field main_win integer|nil
---@field expanded table<string, boolean>
---@field hide_resolved boolean
---@field rows table<integer, ReviewPanelItem> バッファ行 (1-origin) -> 項目
---@field heads integer[] 各項目の先頭行 (昇順)
---@field item_row table<string, integer> key -> 先頭行

local state ---@type ReviewPanelState|nil

local function is_open()
  return state ~= nil
    and state.win ~= nil
    and api.nvim_win_is_valid(state.win)
    and api.nvim_buf_is_valid(state.buf)
    and api.nvim_win_get_buf(state.win) == state.buf
end

-- ---------------------------------------------------------------------------
-- データ
-- ---------------------------------------------------------------------------

---@param t ReviewThread
---@return integer|nil s
---@return integer|nil e
local function thread_range(t)
  local anchor = A().thread_anchor(t) or t.original_line
  if not anchor then
    return nil, nil
  end
  local s = anchor
  if t.start_line and t.line and t.start_line < t.line then
    s = math.max(1, anchor - (t.line - t.start_line))
  end
  return s, anchor
end

---@param root string
---@param c ReviewComment
---@return integer s
---@return integer e
local function comment_range(root, c)
  local bufnr = vim.fn.bufnr(root .. "/" .. c.file)
  if bufnr ~= -1 and api.nvim_buf_is_loaded(bufnr) then
    return A().current_range(bufnr, c)
  end
  return c.line_start, c.line_end
end

---ローカルコメントと PR スレッドをファイル → 行の順に並べた項目一覧
---@param root string
---@param hide_resolved boolean
---@return ReviewPanelItem[]
local function collect(root, hide_resolved)
  local items = {} ---@type ReviewPanelItem[]
  local mine = {}
  for _, c in ipairs(A().store(root).comments) do
    if c.posted and c.posted.comment_id then
      mine[c.posted.comment_id] = true
    end
    local s, e = comment_range(root, c)
    items[#items + 1] = { kind = "comment", key = "c" .. c.id, file = c.file, s = s, e = e, comment = c }
  end
  local data = A().threads(root)
  if data then
    for _, t in ipairs(data.items) do
      if not (hide_resolved and t.resolved) then
        local s, e = thread_range(t)
        items[#items + 1] = {
          kind = "thread",
          key = "t" .. t.id,
          file = t.path,
          s = s or 0,
          e = e or 0,
          thread = t,
          mine = mine[t.comments[1].id] or false,
        }
      end
    end
  end
  table.sort(items, function(a, b)
    if a.file ~= b.file then
      return a.file < b.file
    end
    if a.s ~= b.s then
      return a.s < b.s
    end
    return a.key < b.key
  end)
  return items
end

-- ---------------------------------------------------------------------------
-- 描画
-- ---------------------------------------------------------------------------

---@param item ReviewPanelItem
local function loc_text(item)
  if item.s == 0 then
    return "L?"
  end
  if item.s == item.e then
    return "L" .. item.s
  end
  return string.format("L%d-%d", item.s, item.e)
end

local function fmt_date(s)
  return (s or ""):gsub("T", " "):gsub("Z$", ""):sub(1, 16)
end

---@param t ReviewThread
---@return string[]
local function thread_body(t)
  local lines = {}
  for i, c in ipairs(t.comments) do
    if i > 1 then
      lines[#lines + 1] = ">"
    end
    lines[#lines + 1] = string.format("> **@%s** · %s", c.author, fmt_date(c.created_at))
    for _, l in ipairs(vim.split(c.body, "\n", { plain = true })) do
      lines[#lines + 1] = "> " .. l
    end
  end
  return lines
end

---@param c ReviewComment
---@return string[]
local function comment_body(c)
  local head = "> **ローカル** · " .. fmt_date(c.created_at)
  if c.posted then
    head = head .. string.format(" · posted PR #%d", c.posted.pr)
  end
  local lines = { head }
  for _, l in ipairs(vim.split(c.text, "\n", { plain = true })) do
    lines[#lines + 1] = "> " .. l
  end
  return lines
end

local function render()
  if not state or not api.nvim_buf_is_valid(state.buf) then
    return
  end
  local root = state.root
  local items = collect(root, state.hide_resolved)
  local data = A().threads(root)

  local lines = {} ---@type string[]
  local marks = {} ---@type { row: integer, col: integer, end_col: integer, hl: string }[]
  local codes = {} ---@type table[]
  local rows = {} ---@type table<integer, ReviewPanelItem>
  local heads = {} ---@type integer[]
  local item_row = {} ---@type table<string, integer>

  ---セグメント列を 1 行にして、色の範囲を控える
  ---@param segs { [1]: string, [2]?: string }[]
  local function push(segs)
    local text, col = "", 0
    for _, sg in ipairs(segs) do
      local s = sg[1]
      if sg[2] and #s > 0 then
        marks[#marks + 1] = { row = #lines, col = col, end_col = col + #s, hl = sg[2] }
      end
      text = text .. s
      col = col + #s
    end
    lines[#lines + 1] = text
  end

  -- ヘッダ
  local n_open, n_resolved, n_local = 0, 0, #A().store(root).comments
  if data then
    for _, t in ipairs(data.items) do
      if t.resolved then
        n_resolved = n_resolved + 1
      else
        n_open = n_open + 1
      end
    end
  end
  local head = data and string.format("# Review · PR #%d", data.pr) or "# Review"
  lines[#lines + 1] = head
  local info = {}
  if data then
    info[#info + 1] = string.format("open %d", n_open)
    info[#info + 1] = string.format("resolved %d%s", n_resolved, state.hide_resolved and " (非表示: f)" or "")
  else
    info[#info + 1] = "PR スレッド未取得 (R で取得)"
  end
  info[#info + 1] = string.format("local %d", n_local)
  push({ { table.concat(info, " · "), "ReviewPanelMuted" }, { "   ? でキー一覧", "ReviewPanelMuted" } })
  lines[#lines + 1] = ""

  if #items == 0 then
    push({ { "コメントもスレッドもありません。", "ReviewPanelMuted" } })
    push({
      {
        "ファイル側で <leader>aa を押すとローカルコメントを付けられます。",
        "ReviewPanelMuted",
      },
    })
  end

  -- ファイルごと
  local i = 1
  while i <= #items do
    local file = items[i].file
    local j = i
    local locw = 0
    while j <= #items and items[j].file == file do
      locw = math.max(locw, #loc_text(items[j]))
      j = j + 1
    end
    lines[#lines + 1] = "## " .. file
    rows[#lines] = { kind = "file", key = "f" .. file, file = file, s = 1, e = 1 }
    for k = i, j - 1 do
      local item = items[k]
      local segs = {}
      local loc = string.format("%-" .. locw .. "s", loc_text(item))
      if item.kind == "thread" then
        local t = item.thread
        local dim = t.resolved
        local first = t.comments[1]
        local extra = #t.comments > 1 and string.format(" (+%d)", #t.comments - 1) or ""
        segs[#segs + 1] = { "◆ ", dim and "ReviewPanelMuted" or "ReviewThreadSign" }
        segs[#segs + 1] = { loc, dim and "ReviewPanelMuted" or "ReviewPanelLocation" }
        segs[#segs + 1] = { "  " }
        if item.mine then
          segs[#segs + 1] = { "★ ", "ReviewPanelMine" }
        end
        segs[#segs + 1] = { "@" .. first.author .. " ", dim and "ReviewPanelMuted" or "ReviewThreadAuthor" }
        segs[#segs + 1] = { A().first_line(first.body) .. extra, dim and "ReviewPanelMuted" or "ReviewThreadText" }
        if t.resolved then
          segs[#segs + 1] = { "  resolved", "ReviewPanelMuted" }
        end
        if t.outdated then
          segs[#segs + 1] = { "  outdated", "ReviewPanelMuted" }
        end
      else
        local c = item.comment
        local posted = c.posted ~= nil
        segs[#segs + 1] = { "▎ ", posted and "ReviewCommentPostedSign" or "ReviewCommentSign" }
        segs[#segs + 1] = { loc, posted and "ReviewPanelMuted" or "ReviewPanelLocation" }
        segs[#segs + 1] = { "  " }
        segs[#segs + 1] = { A().first_line(c.text), posted and "ReviewCommentPosted" or "ReviewCommentText" }
        if posted then
          segs[#segs + 1] = { string.format("  posted #%d", c.posted.pr), "ReviewPanelMuted" }
        end
      end
      push(segs)
      local row = #lines
      rows[row] = item
      heads[#heads + 1] = row
      item_row[item.key] = row

      if state.expanded[item.key] then
        local start = #lines
        lines[#lines + 1] = ""
        local body = item.kind == "thread" and thread_body(item.thread) or comment_body(item.comment)
        vim.list_extend(lines, body)
        lines[#lines + 1] = ""
        if item.s > 0 then
          local p = A().append_code(lines, root, item.file, item.s, item.e)
          if p.code then
            codes[#codes + 1] = p.code
          end
          lines[#lines + 1] = ""
        end
        for r = start + 1, #lines do
          rows[r] = item
        end
      end
    end
    lines[#lines + 1] = ""
    rows[#lines] = rows[#lines - 1]
    i = j
  end

  -- カーソル位置の項目を覚えてから書き換える
  local cur_key, cur_row
  if is_open() then
    cur_row = api.nvim_win_get_cursor(state.win)[1]
    local it = state.rows[cur_row]
    cur_key = it and it.key or nil
  end

  local buf = state.buf
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    api.nvim_buf_set_extmark(buf, ns, m.row, m.col, { end_col = m.end_col, hl_group = m.hl, priority = 200 })
  end
  for _, code in ipairs(codes) do
    A().mark_code(buf, ns, code)
  end

  state.rows, state.heads, state.item_row = rows, heads, item_row

  if is_open() then
    local target = (cur_key and item_row[cur_key]) or cur_row or heads[1] or 1
    target = math.max(1, math.min(target, #lines))
    api.nvim_win_set_cursor(state.win, { target, 0 })
  end
end

-- ---------------------------------------------------------------------------
-- 操作
-- ---------------------------------------------------------------------------

---@return ReviewPanelItem|nil
local function item_at_cursor()
  if not is_open() then
    return nil
  end
  return state.rows[api.nvim_win_get_cursor(state.win)[1]]
end

---@param kind "thread"|"comment"|nil nil なら file 以外なんでも
---@return ReviewPanelItem|nil
local function need(kind)
  local item = item_at_cursor()
  if not item or item.kind == "file" then
    vim.notify("Review: 項目の行で押してください", vim.log.levels.WARN)
    return nil
  end
  if kind and item.kind ~= kind then
    if kind == "thread" then
      vim.notify("Review: これはローカルコメントです (e で編集、d で削除)", vim.log.levels.WARN)
    else
      vim.notify("Review: これは PR スレッドです (r で返信、x で resolve)", vim.log.levels.WARN)
    end
    return nil
  end
  return item
end

---パネル以外で使う通常ウィンドウ。無ければ左に作る
---@return integer
local function main_window()
  if state.main_win and api.nvim_win_is_valid(state.main_win) and state.main_win ~= state.win then
    local cfg = api.nvim_win_get_config(state.main_win)
    if cfg.relative == "" then
      return state.main_win
    end
  end
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if w ~= state.win and api.nvim_win_get_config(w).relative == "" then
      state.main_win = w
      return w
    end
  end
  api.nvim_set_current_win(state.win)
  vim.cmd("leftabove vnew")
  state.main_win = api.nvim_get_current_win()
  api.nvim_win_set_width(state.win, review().config.panel.width)
  return state.main_win
end

---@param item ReviewPanelItem
---@param stay boolean カーソルをパネルに残す
local function jump(item, stay)
  local path = state.root .. "/" .. item.file
  if vim.fn.filereadable(path) == 0 then
    vim.notify("Review: ファイルがありません: " .. item.file, vim.log.levels.WARN)
    return false
  end
  local win = main_window()
  api.nvim_set_current_win(win)
  vim.cmd.edit(vim.fn.fnameescape(path))
  if item.kind ~= "file" and item.s > 0 then
    api.nvim_win_set_cursor(win, { math.min(item.s, api.nvim_buf_line_count(0)), 0 })
    vim.cmd("normal! zz")
  end
  if stay and is_open() then
    api.nvim_set_current_win(state.win)
  end
  return true
end

function M.jump()
  local item = item_at_cursor()
  if item then
    jump(item, false)
  end
end

function M.peek()
  local item = item_at_cursor()
  if item then
    jump(item, true)
  end
end

function M.toggle_expand()
  local item = need()
  if not item then
    return
  end
  state.expanded[item.key] = not state.expanded[item.key] or nil
  render()
  api.nvim_win_set_cursor(state.win, { state.item_row[item.key], 0 })
end

function M.toggle_expand_all()
  local any = next(state.expanded) ~= nil
  state.expanded = {}
  if not any then
    for _, item in pairs(state.rows) do
      if item.kind ~= "file" then
        state.expanded[item.key] = true
      end
    end
  end
  render()
end

---@param dir 1|-1
function M.move(dir)
  if not is_open() then
    return
  end
  local cur = api.nvim_win_get_cursor(state.win)[1]
  local target
  if dir > 0 then
    for _, r in ipairs(state.heads) do
      if r > cur then
        target = r
        break
      end
    end
  else
    for idx = #state.heads, 1, -1 do
      if state.heads[idx] < cur then
        target = state.heads[idx]
        break
      end
    end
  end
  if target then
    api.nvim_win_set_cursor(state.win, { target, 0 })
  end
end

function M.reply()
  local item = need("thread")
  if item then
    review().reply_thread(state.root, item.thread)
  end
end

function M.resolve()
  local item = need("thread")
  if item then
    review().resolve_thread(state.root, item.thread)
  end
end

function M.edit()
  local item = need("comment")
  if item then
    review().edit_comment(state.root, item.comment)
  end
end

function M.delete()
  local item = need("comment")
  if not item then
    return
  end
  local answer = vim.fn.confirm(
    string.format(
      "Review: コメントを削除しますか？\n%s\n%s",
      A().location(item.comment),
      A().first_line(item.comment.text)
    ),
    "&Yes\n&No",
    2
  )
  if answer == 1 then
    review().delete_comment(state.root, item.comment)
  end
end

---この項目の行にローカルコメントを付ける。ファイル側へ移動して入力フロートを開く
function M.add()
  local item = need()
  if not item or item.s == 0 then
    if item then
      vim.notify(
        "Review: 行が特定できないスレッドです (削除行への指摘など)",
        vim.log.levels.WARN
      )
    end
    return
  end
  if jump(item, false) then
    review().add({ item.s, item.e })
  end
end

function M.yank()
  local item = need()
  if not item then
    return
  end
  local text
  if item.kind == "thread" then
    text = table.concat(A().thread_markdown(item.thread), "\n")
  else
    text = item.comment.text
  end
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  vim.notify("Review: ヤンクしました")
end

function M.open_in_browser()
  local item = need()
  if not item then
    return
  end
  local url = item.kind == "thread" and item.thread.comments[1].url or (item.comment.posted and item.comment.posted.url)
  if not url or url == "" then
    vim.notify("Review: まだ GitHub に投稿されていません", vim.log.levels.WARN)
    return
  end
  vim.ui.open(url)
end

function M.publish()
  if not is_open() then
    return
  end
  api.nvim_win_call(main_window(), function()
    review().publish()
  end)
end

function M.refetch()
  if not is_open() then
    return
  end
  review().fetch_threads({ root = state.root })
  render()
end

function M.toggle_resolved_filter()
  if not is_open() then
    return
  end
  state.hide_resolved = not state.hide_resolved
  render()
end

function M.help()
  A().open_reader({
    "## Review パネルのキー",
    "",
    "| キー | 動作 |",
    "| --- | --- |",
    "| `<CR>` | 対象行へジャンプ (パネルは開いたまま) |",
    "| `o` | 対象行を表示するがカーソルはパネルに残す |",
    "| `<Tab>` / `za` | 本文と対象コードを展開 / 折りたたみ |",
    "| `<S-Tab>` | 全部まとめて展開 / 折りたたみ |",
    "| `<C-n>` `<C-p>` / `]]` `[[` | 次 / 前の項目 |",
    "| `r` | スレッドに返信 (即時公開・確認あり) |",
    "| `x` | スレッドを resolved / unresolved |",
    "| `a` | この行にローカルコメントを付ける |",
    "| `e` / `d` | ローカルコメントを編集 / 削除 |",
    "| `y` | 本文を Markdown でヤンク |",
    "| `gx` | GitHub で開く |",
    "| `P` | ローカルコメントを PR にドラフト投稿 |",
    "| `R` | PR スレッドを再取得 |",
    "| `f` | resolved を隠す / 出す |",
    "| `q` | 閉じる |",
  }, "review panel")
end

function M.close()
  if is_open() then
    api.nvim_win_close(state.win, true)
  end
  if state then
    state.win = nil
  end
end

-- ---------------------------------------------------------------------------
-- 開閉
-- ---------------------------------------------------------------------------

local registered = false

local function ensure_buf()
  if state and api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end
  if not registered then
    -- filetype は "review" にして markdown の LSP や spell を巻き込まず、パーサだけ markdown を使う
    pcall(vim.treesitter.language.register, "markdown", "review")
    registered = true
  end
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_name(buf, "review://panel")
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "review"
  pcall(vim.treesitter.start, buf, "markdown")

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, desc = "Review panel: " .. desc })
  end
  map("<CR>", M.jump, "ジャンプ")
  map("o", M.peek, "表示 (カーソルは残す)")
  map("<Tab>", M.toggle_expand, "展開/折りたたみ")
  map("za", M.toggle_expand, "展開/折りたたみ")
  map("<S-Tab>", M.toggle_expand_all, "全部展開/折りたたみ")
  map("<C-n>", function()
    M.move(1)
  end, "次の項目")
  map("<C-p>", function()
    M.move(-1)
  end, "前の項目")
  map("]]", function()
    M.move(1)
  end, "次の項目")
  map("[[", function()
    M.move(-1)
  end, "前の項目")
  map("r", M.reply, "返信")
  map("x", M.resolve, "resolve/unresolve")
  map("a", M.add, "ローカルコメントを付ける")
  map("e", M.edit, "編集")
  map("d", M.delete, "削除")
  map("y", M.yank, "ヤンク")
  map("gx", M.open_in_browser, "GitHub で開く")
  map("P", M.publish, "PR に投稿")
  map("R", M.refetch, "再取得")
  map("f", M.toggle_resolved_filter, "resolved を隠す/出す")
  map("?", M.help, "キー一覧")
  map("q", M.close, "閉じる")
  return buf
end

---@param opts? { root?: string }
function M.open(opts)
  opts = opts or {}
  local main_win = api.nvim_get_current_win()
  local root = opts.root or A().root_of(api.nvim_get_current_buf())
  if not A().threads(root) then
    -- PR が無い / gh が無い場合は通知だけ出て false になるので、ローカルコメントだけで続ける
    review().fetch_threads({ root = root })
  end

  local buf = ensure_buf()
  if is_open() then
    api.nvim_set_current_win(state.win)
  else
    vim.cmd(string.format("botright vertical %dsplit", review().config.panel.width))
    local win = api.nvim_get_current_win()
    api.nvim_win_set_buf(win, buf)
    for k, v in pairs({
      number = false,
      relativenumber = false,
      signcolumn = "no",
      foldcolumn = "0",
      wrap = true,
      linebreak = true,
      breakindent = true,
      cursorline = true,
      winfixwidth = true,
      spell = false,
      list = false,
      conceallevel = 2,
      concealcursor = "nc",
    }) do
      vim.wo[win][k] = v
    end
    state = {
      root = root,
      buf = buf,
      win = win,
      main_win = main_win,
      expanded = state and state.root == root and state.expanded or {},
      hide_resolved = state and state.hide_resolved or false,
      rows = {},
      heads = {},
      item_row = {},
    }
  end
  state.root = root
  state.main_win = main_win ~= state.win and main_win or state.main_win
  render()
  if state.heads[1] then
    api.nvim_win_set_cursor(state.win, { state.heads[1], 0 })
  end
end

---開いていなければ開く。開いていてフォーカスが別なら移動、フォーカス中なら閉じる
function M.toggle()
  if is_open() then
    if api.nvim_get_current_win() == state.win then
      M.close()
    else
      api.nvim_set_current_win(state.win)
    end
    return
  end
  M.open()
end

---review.setup から呼ばれる。保存・再取得の通知を受けて描き直す
function M.setup()
  local listeners = review()._listeners
  listeners[#listeners + 1] = function(root)
    if is_open() and state.root == root then
      vim.schedule(render)
    end
  end
  api.nvim_clear_autocmds({ group = augroup })
  -- 最後に残るのがパネルだけなら一緒に閉じる
  api.nvim_create_autocmd("QuitPre", {
    group = augroup,
    callback = function()
      if not is_open() or api.nvim_get_current_win() == state.win then
        return
      end
      local others = 0
      for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
        if w ~= state.win and api.nvim_win_get_config(w).relative == "" then
          others = others + 1
        end
      end
      if others <= 1 then
        M.close()
      end
    end,
  })
end

---テスト・デバッグ用
function M._state()
  return state
end

return M

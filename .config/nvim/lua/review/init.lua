-- コードレビュー用のコメントを、ソースには書き込まずに外付けで残す自前モジュール。
-- 行(範囲)を選んでコメントを付けると、git root 直下の .review/ に
--   comments.json  … データ本体 (ファイルパス・行番号・本文)
--   REVIEW.md      … 貼り付け用 Markdown (保存のたびに再生成)
-- が書かれ、エディタ上にはサイン + 範囲末尾の下の仮想行として表示される。
-- (.review/ を commit したくなければ .gitignore に追加する)
--
--   <leader>aa  カーソル行 / 選択範囲(v)にコメントを付ける
--   <leader>ae  カーソル位置のコメントを編集
--   <leader>ad  カーソル位置のコメントを削除
--   <leader>al  コメント一覧 (Telescope / 無ければ quickfix)
--   <leader>ay  全コメントを Markdown でヤンク (+ レジスタ)
--   <leader>aY  現在ファイルのコメントだけヤンク
--   <leader>ao  .review/REVIEW.md を開く
--   <leader>at  表示のトグル
--   <leader>ax  全コメントを削除 (確認あり)
--   ]a / [a     次 / 前のコメントへ
--   :Review {add|edit|delete|list|yank|yankfile|open|toggle|clear}
--
-- 入力フロートでは ノーマルの <CR> / <C-s> / :w で確定、q でキャンセル。
-- インサートの <CR> は普通の改行なので複数行のコメントが書ける。

local M = {}

M.config = {
  dir = ".review", -- git root からの相対ディレクトリ
  json_name = "comments.json",
  md_name = "REVIEW.md",
  sign = "▎",
  prefix = "┃ ", -- 仮想行の各行頭
  editor = { width = 80, height = 10 },
}

local api = vim.api
local ns = api.nvim_create_namespace("review_comments")
local augroup = api.nvim_create_augroup("review_comments", { clear = true })

---@class ReviewComment
---@field id integer
---@field file string git root からの相対パス
---@field line_start integer 1-origin
---@field line_end integer 1-origin
---@field text string
---@field created_at string

---@class ReviewStore
---@field comments ReviewComment[]
---@field next_id integer

local stores = {} ---@type table<string, ReviewStore>  root -> store
local marks = {} ---@type table<integer, table<integer, {first: integer, last: integer}>> bufnr -> id -> extmark
local enabled = true

-- ---------------------------------------------------------------------------
-- パス
-- ---------------------------------------------------------------------------

---バッファが属するプロジェクトの root (git root、無ければ cwd)
---@param bufnr? integer
---@return string
local function root_of(bufnr)
  bufnr = bufnr or 0
  local name = api.nvim_buf_get_name(bufnr)
  local root
  if name ~= "" and not name:match("^%w+://") then
    root = vim.fs.root(name, ".git")
  end
  return root or vim.uv.cwd()
end

---絶対パスを root からの相対パスに。root の外なら nil
---@param root string
---@param abs string
---@return string|nil
local function relpath(root, abs)
  if abs == "" or abs:match("^%w+://") then
    return nil
  end
  abs = vim.fn.fnamemodify(abs, ":p")
  local prefix = root:gsub("/$", "") .. "/"
  if abs:sub(1, #prefix) == prefix then
    return abs:sub(#prefix + 1)
  end
  return nil
end

---@param root string
---@return string dir, string json, string md
local function paths(root)
  local dir = root .. "/" .. M.config.dir
  return dir, dir .. "/" .. M.config.json_name, dir .. "/" .. M.config.md_name
end

---表示用の "path:L10-L15"
---@param c ReviewComment
---@return string
local function location(c)
  if c.line_start == c.line_end then
    return string.format("%s:L%d", c.file, c.line_start)
  end
  return string.format("%s:L%d-L%d", c.file, c.line_start, c.line_end)
end

local function first_line(text)
  return (vim.split(text, "\n", { plain = true })[1] or "")
end

-- ---------------------------------------------------------------------------
-- 永続化
-- ---------------------------------------------------------------------------

---@param comments ReviewComment[]
local function sort_comments(comments)
  table.sort(comments, function(a, b)
    if a.file ~= b.file then
      return a.file < b.file
    end
    if a.line_start ~= b.line_start then
      return a.line_start < b.line_start
    end
    return a.id < b.id
  end)
end

---root のストアを (必要なら読み込んで) 返す
---@param root string
---@return ReviewStore
local function store(root)
  if stores[root] then
    return stores[root]
  end
  local _, json = paths(root)
  local s = { comments = {}, next_id = 1 }
  local f = io.open(json, "r")
  if f then
    local ok, parsed = pcall(vim.json.decode, f:read("*a"))
    f:close()
    if ok and type(parsed) == "table" and type(parsed.comments) == "table" then
      s.comments = parsed.comments
      local max_id = 0
      for _, c in ipairs(s.comments) do
        max_id = math.max(max_id, tonumber(c.id) or 0)
      end
      s.next_id = math.max(tonumber(parsed.next_id) or 0, max_id + 1)
    end
  end
  stores[root] = s
  return s
end

---対象範囲のコードを返す。開いているバッファがあればそちら、無ければディスクから
---@param root string
---@param c ReviewComment
---@return string[]|nil
local function read_code(root, c)
  local abs = root .. "/" .. c.file
  local lines
  local bufnr = vim.fn.bufnr(abs)
  if bufnr > 0 and api.nvim_buf_is_loaded(bufnr) then
    lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  elseif vim.fn.filereadable(abs) == 1 then
    lines = vim.fn.readfile(abs)
  else
    return nil
  end
  local s = math.max(1, c.line_start)
  local e = math.min(#lines, c.line_end)
  if s > e then
    return nil
  end
  return vim.list_slice(lines, s, e)
end

---コメント群を貼り付け用 Markdown にする
---@param comments ReviewComment[]
---@param root string
---@param with_header? boolean 先頭に "# Review comments" を付ける
---@return string
function M.render_markdown(comments, root, with_header)
  local sorted = vim.list_extend({}, comments)
  sort_comments(sorted)
  local blocks = {}
  for _, c in ipairs(sorted) do
    local lines = { "### " .. location(c), "" }
    local code = read_code(root, c)
    if code then
      -- コード側に ``` が含まれていたらフェンスを長くして壊れないようにする
      local fence = "```"
      for _, l in ipairs(code) do
        local ticks = l:match("^%s*(````*)")
        if ticks and #ticks >= #fence then
          fence = string.rep("`", #ticks + 1)
        end
      end
      local lang = vim.filetype.match({ filename = c.file }) or ""
      lines[#lines + 1] = fence .. lang
      vim.list_extend(lines, code)
      lines[#lines + 1] = fence
      lines[#lines + 1] = ""
    end
    lines[#lines + 1] = c.text
    blocks[#blocks + 1] = table.concat(lines, "\n")
  end
  local out = table.concat(blocks, "\n\n")
  if with_header then
    out = "# Review comments\n\n" .. out
  end
  return out .. "\n"
end

---ストアを comments.json と REVIEW.md に書き出す。0 件なら両方消す
---@param root string
local function save(root)
  local s = store(root)
  local dir, json, md = paths(root)
  if #s.comments == 0 then
    os.remove(json)
    os.remove(md)
    vim.fn.delete(dir, "d") -- 空のときだけ消える
    return
  end
  sort_comments(s.comments)
  vim.fn.mkdir(dir, "p")
  -- 1 コメント 1 行の JSON にして diff で読めるようにする
  local lines = { "{", '  "version": 1,', string.format('  "next_id": %d,', s.next_id), '  "comments": [' }
  for i, c in ipairs(s.comments) do
    lines[#lines + 1] = "    " .. vim.json.encode(c) .. (i < #s.comments and "," or "")
  end
  lines[#lines + 1] = "  ]"
  lines[#lines + 1] = "}"
  vim.fn.writefile(lines, json)
  vim.fn.writefile(vim.split(M.render_markdown(s.comments, root, true), "\n", { plain = true }), md)
end

-- ---------------------------------------------------------------------------
-- 表示 (extmark)
-- ---------------------------------------------------------------------------

local function set_highlights()
  api.nvim_set_hl(0, "ReviewCommentSign", { link = "DiagnosticInfo", default = true })
  api.nvim_set_hl(0, "ReviewCommentBorder", { link = "Comment", default = true })
  local info = api.nvim_get_hl(0, { name = "DiagnosticInfo", link = false })
  api.nvim_set_hl(0, "ReviewCommentText", { fg = info.fg, italic = true, default = true })
end

---@param bufnr integer
local function clear_buf(bufnr)
  if api.nvim_buf_is_valid(bufnr) then
    api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end
  marks[bufnr] = nil
end

---1 件分の extmark を置く
---@param bufnr integer
---@param c ReviewComment
local function place(bufnr, c)
  local last_line = api.nvim_buf_line_count(bufnr)
  local s = math.max(1, math.min(c.line_start, last_line))
  local e = math.max(s, math.min(c.line_end, last_line))
  local first_id
  for l = s, e do
    local id = api.nvim_buf_set_extmark(bufnr, ns, l - 1, 0, {
      sign_text = M.config.sign,
      sign_hl_group = "ReviewCommentSign",
      priority = 20,
    })
    first_id = first_id or id
  end
  local virt = {}
  for _, t in ipairs(vim.split(c.text, "\n", { plain = true })) do
    virt[#virt + 1] = { { "  " .. M.config.prefix, "ReviewCommentBorder" }, { t, "ReviewCommentText" } }
  end
  local last_id = api.nvim_buf_set_extmark(bufnr, ns, e - 1, 0, { virt_lines = virt })
  marks[bufnr] = marks[bufnr] or {}
  marks[bufnr][c.id] = { first = first_id, last = last_id }
end

---バッファのコメントを描き直す
---@param bufnr? integer
function M.render(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and api.nvim_get_current_buf() or bufnr
  if not api.nvim_buf_is_valid(bufnr) or not api.nvim_buf_is_loaded(bufnr) then
    return
  end
  clear_buf(bufnr)
  if not enabled then
    return
  end
  local root = root_of(bufnr)
  local rel = relpath(root, api.nvim_buf_get_name(bufnr))
  if not rel then
    return
  end
  marks[bufnr] = {}
  for _, c in ipairs(store(root).comments) do
    if c.file == rel then
      place(bufnr, c)
    end
  end
end

---開いている全バッファを描き直す
function M.render_all()
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_get_name(bufnr) ~= "" then
      M.render(bufnr)
    end
  end
end

---extmark の今の位置からコメントの行範囲を返す (描画前ならデータの値)
---@param bufnr integer
---@param c ReviewComment
---@return integer, integer
local function current_range(bufnr, c)
  local m = marks[bufnr] and marks[bufnr][c.id]
  if m then
    local first = api.nvim_buf_get_extmark_by_id(bufnr, ns, m.first, {})
    local last = api.nvim_buf_get_extmark_by_id(bufnr, ns, m.last, {})
    if first[1] and last[1] then
      local s = first[1] + 1
      return s, math.max(s, last[1] + 1)
    end
  end
  return c.line_start, c.line_end
end

---編集で動いた行番号をデータに反映して保存する (BufWritePost)
---@param bufnr integer
local function sync(bufnr)
  local bm = marks[bufnr]
  if not bm or vim.tbl_isempty(bm) then
    return
  end
  local root = root_of(bufnr)
  local moved = false
  for _, c in ipairs(store(root).comments) do
    if bm[c.id] then
      local s, e = current_range(bufnr, c)
      if s ~= c.line_start or e ~= c.line_end then
        c.line_start, c.line_end = s, e
        moved = true
      end
    end
  end
  -- 行が動いていなくてもコード断片が変わっているかもしれないので REVIEW.md は作り直す
  save(root)
  if moved then
    M.render(bufnr)
  end
end

---バッファ内のコメントを現在位置順に返す
---@param bufnr integer
---@return { c: ReviewComment, s: integer, e: integer }[]
local function buf_comments(bufnr)
  local root = root_of(bufnr)
  local rel = relpath(root, api.nvim_buf_get_name(bufnr))
  local out = {}
  if not rel then
    return out
  end
  for _, c in ipairs(store(root).comments) do
    if c.file == rel then
      local s, e = current_range(bufnr, c)
      out[#out + 1] = { c = c, s = s, e = e }
    end
  end
  table.sort(out, function(a, b)
    if a.s ~= b.s then
      return a.s < b.s
    end
    return a.c.id < b.c.id
  end)
  return out
end

---カーソル行を含むコメント
---@param bufnr integer
---@return ReviewComment[]
local function comments_at_cursor(bufnr)
  local line = api.nvim_win_get_cursor(0)[1]
  local out = {}
  for _, item in ipairs(buf_comments(bufnr)) do
    if item.s <= line and line <= item.e then
      out[#out + 1] = item.c
    end
  end
  return out
end

---複数ヒットしたら選ばせる
---@param cands ReviewComment[]
---@param prompt string
---@param cb fun(c: ReviewComment)
local function pick(cands, prompt, cb)
  if #cands == 0 then
    vim.notify("Review: カーソル位置にコメントはありません", vim.log.levels.WARN)
    return
  end
  if #cands == 1 then
    cb(cands[1])
    return
  end
  vim.ui.select(cands, {
    prompt = prompt,
    format_item = function(c)
      return location(c) .. "  " .. first_line(c.text)
    end,
  }, function(c)
    if c then
      cb(c)
    end
  end)
end

-- ---------------------------------------------------------------------------
-- 入力フロート
-- ---------------------------------------------------------------------------

---@param opts { title: string, text: string, on_submit: fun(text: string) }
local function open_editor(opts)
  local buf = api.nvim_create_buf(false, false)
  api.nvim_buf_set_name(buf, "review://comment/" .. buf)
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(opts.text or "", "\n", { plain = true }))
  vim.bo[buf].modified = false

  local width = math.max(40, math.min(M.config.editor.width, math.floor(vim.o.columns * 0.7)))
  local height = M.config.editor.height
  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. opts.title .. " ",
    title_pos = "left",
    footer = " <CR> / <C-s> / :w 確定   q キャンセル ",
    footer_pos = "right",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  local done = false
  local function close()
    if api.nvim_win_is_valid(win) then
      api.nvim_win_close(win, true)
    end
  end
  local function submit()
    if done then
      return
    end
    done = true
    local text = vim.trim(table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
    vim.bo[buf].modified = false
    close()
    if text == "" then
      vim.notify("Review: 本文が空なのでキャンセルしました", vim.log.levels.WARN)
      return
    end
    opts.on_submit(text)
  end
  local function cancel()
    if done then
      return
    end
    done = true
    vim.bo[buf].modified = false
    close()
    vim.notify("Review: キャンセルしました")
  end

  local kopts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", submit, kopts)
  vim.keymap.set({ "n", "i" }, "<C-s>", submit, kopts)
  vim.keymap.set("n", "q", cancel, kopts)

  api.nvim_create_autocmd("BufWriteCmd", { buffer = buf, callback = submit })
  -- :q でも閉じられるように modified フラグは立てっぱなしにしない
  api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = function()
      vim.bo[buf].modified = false
    end,
  })
  api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      if not done then
        cancel()
      end
    end,
  })

  if (opts.text or "") == "" then
    vim.cmd("startinsert")
  end
end

-- ---------------------------------------------------------------------------
-- 公開 API
-- ---------------------------------------------------------------------------

---コメントを追加する。visual mode なら選択範囲、range 指定があればその範囲、無ければカーソル行
---@param range? { [1]: integer, [2]: integer }
function M.add(range)
  local bufnr = api.nvim_get_current_buf()
  local root = root_of(bufnr)
  local rel = relpath(root, api.nvim_buf_get_name(bufnr))
  if not rel then
    vim.notify("Review: プロジェクト内のファイルを開いた状態で実行してください", vim.log.levels.WARN)
    return
  end

  local s, e
  if range then
    s, e = range[1], range[2]
  elseif vim.fn.mode():match("^[vV\22]") then
    -- '< '> は visual mode を抜けた時点で確定するので、先に <Esc> を送る
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    s, e = vim.fn.line("'<"), vim.fn.line("'>")
  else
    s = api.nvim_win_get_cursor(0)[1]
    e = s
  end
  if s > e then
    s, e = e, s
  end

  local draft = { id = 0, file = rel, line_start = s, line_end = e, text = "", created_at = "" }
  open_editor({
    title = "review: " .. location(draft),
    text = "",
    on_submit = function(text)
      local st = store(root)
      draft.id = st.next_id
      draft.text = text
      draft.created_at = os.date("%Y-%m-%dT%H:%M:%S")
      st.next_id = st.next_id + 1
      table.insert(st.comments, draft)
      save(root)
      M.render(bufnr)
      vim.notify("Review: コメントを追加しました " .. location(draft))
    end,
  })
end

---カーソル位置のコメントを編集する
function M.edit()
  local bufnr = api.nvim_get_current_buf()
  local root = root_of(bufnr)
  pick(comments_at_cursor(bufnr), "編集するコメント", function(c)
    open_editor({
      title = "review: " .. location(c),
      text = c.text,
      on_submit = function(text)
        c.text = text
        save(root)
        M.render(bufnr)
        vim.notify("Review: コメントを更新しました " .. location(c))
      end,
    })
  end)
end

---カーソル位置のコメントを削除する
function M.delete()
  local bufnr = api.nvim_get_current_buf()
  local root = root_of(bufnr)
  pick(comments_at_cursor(bufnr), "削除するコメント", function(c)
    local st = store(root)
    for i, x in ipairs(st.comments) do
      if x.id == c.id then
        table.remove(st.comments, i)
        break
      end
    end
    save(root)
    M.render(bufnr)
    vim.notify("Review: コメントを削除しました " .. location(c))
  end)
end

---コメントを Markdown にしてレジスタに入れる
---@param scope? "all"|"file"
function M.yank(scope)
  local bufnr = api.nvim_get_current_buf()
  local root = root_of(bufnr)
  local comments = store(root).comments
  if scope == "file" then
    local rel = relpath(root, api.nvim_buf_get_name(bufnr))
    comments = vim.tbl_filter(function(c)
      return c.file == rel
    end, comments)
  end
  if #comments == 0 then
    vim.notify("Review: ヤンクするコメントがありません", vim.log.levels.WARN)
    return
  end
  local md = M.render_markdown(comments, root, false)
  vim.fn.setreg("+", md)
  vim.fn.setreg('"', md)
  vim.notify(string.format("Review: %d 件のコメントを Markdown でヤンクしました", #comments))
end

---プロジェクトのコメントを全部消す (確認あり)
function M.clear()
  local root = root_of(api.nvim_get_current_buf())
  local st = store(root)
  if #st.comments == 0 then
    vim.notify("Review: コメントはありません")
    return
  end
  local answer = vim.fn.confirm(
    string.format("Review: %d 件のコメントを全て削除しますか？\n(%s)", #st.comments, root),
    "&Yes\n&No",
    2
  )
  if answer ~= 1 then
    return
  end
  st.comments = {}
  st.next_id = 1
  save(root)
  M.render_all()
  vim.notify("Review: 全てのコメントを削除しました")
end

---表示の ON/OFF
function M.toggle()
  enabled = not enabled
  M.render_all()
  vim.notify("Review: 表示を " .. (enabled and "ON" or "OFF") .. " にしました")
end

---REVIEW.md を開く
function M.open_output()
  local root = root_of(api.nvim_get_current_buf())
  local _, _, md = paths(root)
  if vim.fn.filereadable(md) == 0 then
    vim.notify("Review: まだ REVIEW.md がありません (コメントを追加すると作られます)", vim.log.levels.WARN)
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(md))
end

---@param dir 1|-1
local function jump(dir)
  local bufnr = api.nvim_get_current_buf()
  local items = buf_comments(bufnr)
  if #items == 0 then
    vim.notify("Review: このファイルにコメントはありません", vim.log.levels.WARN)
    return
  end
  local line = api.nvim_win_get_cursor(0)[1]
  local target
  if dir > 0 then
    for _, it in ipairs(items) do
      if it.s > line then
        target = it
        break
      end
    end
    target = target or items[1]
  else
    for i = #items, 1, -1 do
      if items[i].s < line then
        target = items[i]
        break
      end
    end
    target = target or items[#items]
  end
  api.nvim_win_set_cursor(0, { target.s, 0 })
end

function M.next()
  jump(1)
end

function M.prev()
  jump(-1)
end

---一覧 (Telescope、無ければ quickfix)
function M.list()
  local root = root_of(api.nvim_get_current_buf())
  local st = store(root)
  if #st.comments == 0 then
    vim.notify("Review: コメントはありません")
    return
  end
  sort_comments(st.comments)

  local function jump_to(c)
    vim.cmd.edit(vim.fn.fnameescape(root .. "/" .. c.file))
    local bufnr = api.nvim_get_current_buf()
    local s = current_range(bufnr, c)
    api.nvim_win_set_cursor(0, { math.min(s, api.nvim_buf_line_count(bufnr)), 0 })
  end

  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.fn.setqflist({}, " ", {
      title = "Review comments",
      items = vim.tbl_map(function(c)
        return { filename = root .. "/" .. c.file, lnum = c.line_start, text = first_line(c.text) }
      end, st.comments),
    })
    vim.cmd("copen")
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  local loc_width = 0
  for _, c in ipairs(st.comments) do
    loc_width = math.max(loc_width, vim.fn.strdisplaywidth(location(c)))
  end
  local displayer = entry_display.create({
    separator = "  ",
    items = { { width = math.min(loc_width, 50) }, { remaining = true } },
  })

  pickers
    .new({}, {
      prompt_title = "Review comments",
      finder = finders.new_table({
        results = st.comments,
        entry_maker = function(c)
          return {
            value = c,
            ordinal = location(c) .. " " .. c.text,
            display = function(entry)
              return displayer({
                { location(entry.value), "TelescopeResultsIdentifier" },
                first_line(entry.value.text),
              })
            end,
            filename = root .. "/" .. c.file,
            lnum = c.line_start,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.grep_previewer({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry then
            jump_to(entry.value)
          end
        end)
        for _, mode in ipairs({ "i", "n" }) do
          map(mode, "<C-d>", function()
            local entry = action_state.get_selected_entry()
            if not entry then
              return
            end
            actions.close(prompt_bufnr)
            for i, x in ipairs(st.comments) do
              if x.id == entry.value.id then
                table.remove(st.comments, i)
                break
              end
            end
            save(root)
            M.render_all()
            vim.notify("Review: コメントを削除しました " .. location(entry.value))
          end)
        end
        return true
      end,
    })
    :find()
end

-- ---------------------------------------------------------------------------
-- setup
-- ---------------------------------------------------------------------------

local subcommands = {
  add = function(cmd)
    M.add(cmd.range > 0 and { cmd.line1, cmd.line2 } or nil)
  end,
  edit = M.edit,
  delete = M.delete,
  list = M.list,
  yank = function()
    M.yank("all")
  end,
  yankfile = function()
    M.yank("file")
  end,
  open = M.open_output,
  toggle = M.toggle,
  clear = M.clear,
}

---@param opts? { dir?: string, sign?: string, prefix?: string, editor?: { width?: integer, height?: integer } }
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  set_highlights()

  api.nvim_clear_autocmds({ group = augroup })
  api.nvim_create_autocmd("ColorScheme", { group = augroup, callback = set_highlights })
  api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    callback = function(ev)
      M.render(ev.buf)
    end,
  })
  api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function(ev)
      -- 描画済みのバッファは extmark が追従しているので触らない
      if not marks[ev.buf] and api.nvim_buf_get_name(ev.buf) ~= "" then
        M.render(ev.buf)
      end
    end,
  })
  api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    callback = function(ev)
      sync(ev.buf)
    end,
  })
  api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
    group = augroup,
    callback = function(ev)
      marks[ev.buf] = nil
    end,
  })

  api.nvim_create_user_command("Review", function(cmd)
    local sub = cmd.fargs[1] or "add"
    local fn = subcommands[sub]
    if not fn then
      vim.notify("Review: 不明なサブコマンド: " .. sub, vim.log.levels.ERROR)
      return
    end
    fn(cmd)
  end, {
    nargs = "?",
    range = true,
    desc = "Review comments",
    complete = function(arg)
      return vim.tbl_filter(function(k)
        return k:find(arg, 1, true) == 1
      end, vim.tbl_keys(subcommands))
    end,
  })

  local map = vim.keymap.set
  map({ "n", "v" }, "<leader>aa", function()
    M.add()
  end, { desc = "Review: コメントを付ける" })
  map("n", "<leader>ae", M.edit, { desc = "Review: コメントを編集" })
  map("n", "<leader>ad", M.delete, { desc = "Review: コメントを削除" })
  map("n", "<leader>al", M.list, { desc = "Review: 一覧" })
  map("n", "<leader>ay", function()
    M.yank("all")
  end, { desc = "Review: 全コメントを Markdown でヤンク" })
  map("n", "<leader>aY", function()
    M.yank("file")
  end, { desc = "Review: このファイルのコメントをヤンク" })
  map("n", "<leader>ao", M.open_output, { desc = "Review: REVIEW.md を開く" })
  map("n", "<leader>at", M.toggle, { desc = "Review: 表示トグル" })
  map("n", "<leader>ax", M.clear, { desc = "Review: 全コメントを削除" })
  map("n", "]a", M.next, { desc = "Review: 次のコメント" })
  map("n", "[a", M.prev, { desc = "Review: 前のコメント" })

  -- setup より前に開き終わっているバッファにも描く
  M.render_all()
end

return M

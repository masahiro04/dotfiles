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
--   <leader>ap  未投稿のコメントを gh で PR のドラフト (Pending) レビューとして投稿
--   <leader>aP  ドラフトにせず、その場でレビューコメントとして投稿 (確認あり)
--   <leader>af  PR のレビュースレッド (相手の返信など) を取得して表示
--   <leader>aL  スレッド一覧 (Telescope)
--   <leader>av  カーソル行のスレッド全文をフロートで読む
--   <leader>ar  カーソル行のスレッドに返信 (即時公開・確認あり)
--   <leader>aR  カーソル行のスレッドを resolved / unresolved に切り替え
--   <leader>at  表示のトグル
--   <leader>ax  全コメントを削除 (確認あり)
--   ]a / [a     次 / 前のコメントへ
--   :Review {add|edit|delete|list|yank|yankfile|open|publish|toggle|clear}
--   :Review {fetch|threads|view|reply|resolve}
--   :Review submit  即時投稿 / :Review publish --dry-run  送る内容だけ確認 / :Review! publish  投稿済みも含めて再投稿
--
-- diffview (:G diff / :G diffmain / :G diffparent) の右ペインでも使える。
-- 右側は作業ツリーか HEAD なので実ファイルに読み替えて保存・表示する。
-- 左側 (base / index) は行番号が合わないので付けられない。
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
  thread_sign = "◆", -- PR スレッドのサイン
  thread_max_lines = 4, -- 仮想行に出すスレッド本文の行数上限 (全文は <leader>av)
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
---@field posted? { pr: integer, review_id: integer, url: string, at: string } GitHub に投稿済みなら入る

---@class ReviewStore
---@field comments ReviewComment[]
---@field next_id integer

local stores = {} ---@type table<string, ReviewStore>  root -> store
local marks = {} ---@type table<integer, table<integer, {first: integer, last: integer}>> bufnr -> id -> extmark
local enabled = true

-- PR のレビュースレッド (GitHub 側のデータ)
---@class ReviewThreadComment
---@field id integer REST の comment id
---@field author string
---@field body string
---@field created_at string
---@field url string

---@class ReviewThread
---@field id string GraphQL node id (resolve 用)
---@field path string
---@field line integer|nil 変更後ファイルでの現在の行 (outdated なら nil)
---@field start_line integer|nil
---@field original_line integer|nil
---@field side string "RIGHT" | "LEFT"
---@field resolved boolean
---@field outdated boolean
---@field comments ReviewThreadComment[]

local tns = api.nvim_create_namespace("review_threads")
local threads = {} ---@type table<string, { pr: integer, url: string, fetched_at: string, items: ReviewThread[] }> root -> data
local tmarks = {} ---@type table<integer, table<string, integer>> bufnr -> thread id -> extmark
local render_threads -- 後で定義 (M.render から呼ぶ)

-- ---------------------------------------------------------------------------
-- パス
-- ---------------------------------------------------------------------------

---@class ReviewDiffviewFile
---@field root string リポジトリの toplevel
---@field rel string 相対パス
---@field kind "local"|"head"|"other" local = 作業ツリー、head = HEAD コミット、other = base や index 側

local dv_cache = {} ---@type table<integer, ReviewDiffviewFile|false>

---diffview の仮想バッファなら、対応するファイルと「右側かどうか」を返す
---@param bufnr integer
---@return ReviewDiffviewFile|nil
local function diffview_file(bufnr)
  local name = api.nvim_buf_get_name(bufnr)
  if not name:match("^diffview://") then
    return nil
  end
  local cached = dv_cache[bufnr]
  if cached ~= nil then
    return cached or nil
  end
  local ok, lib = pcall(require, "diffview.lib")
  local ok2, revmod = pcall(require, "diffview.vcs.rev")
  if not ok or not ok2 then
    return nil
  end
  local found
  for _, view in ipairs(lib.views or {}) do
    local entry = view.cur_entry
    if entry and entry.layout then
      for _, file in ipairs(entry.layout:files()) do
        if file.bufnr == bufnr and file.adapter and file.adapter.ctx and file.rev then
          local kind = "other"
          if file.rev.type == revmod.RevType.LOCAL then
            kind = "local"
          elseif file.rev.is_head and file.rev:is_head(file.adapter) then
            kind = "head"
          end
          found = { root = file.adapter.ctx.toplevel, rel = file.path, kind = kind }
          break
        end
      end
    end
    if found then
      break
    end
  end
  -- バッファがまだ view に登録されていない場合もあるので、見つからなかったときはキャッシュしない
  if found then
    dv_cache[bufnr] = found
  end
  return found
end

---バッファが属するプロジェクトの root (git root、無ければ cwd)
---@param bufnr? integer
---@return string
local function root_of(bufnr)
  bufnr = bufnr or 0
  local dv = diffview_file(bufnr)
  if dv then
    return dv.root
  end
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

---コマンドを root で同期実行する。失敗したら nil と stderr
---@param cmd string[]
---@param root string
---@param stdin? string
---@return string|nil out, string|nil err
local function run(cmd, root, stdin)
  if vim.fn.executable(cmd[1]) == 0 then
    return nil, cmd[1] .. " コマンドが見つかりません"
  end
  local res = vim.system(cmd, { cwd = root, text = true, stdin = stdin }):wait()
  if res.code ~= 0 then
    return nil, vim.trim((res.stderr or "") .. (res.stdout or ""))
  end
  return res.stdout or "", nil
end

---バッファをコメント対象の (root, 相対パス) に解決する。diffview の右ペインは実ファイルに読み替える
---@param bufnr integer
---@return string|nil root, string|nil rel, string|nil err
local function buf_target(bufnr)
  local dv = diffview_file(bufnr)
  if dv then
    if dv.kind == "other" then
      return nil, nil, "diffview の左側 (base / index) にはコメントできません。右側のペインで付けてください"
    end
    return dv.root, dv.rel
  end
  local root = root_of(bufnr)
  local rel = relpath(root, api.nvim_buf_get_name(bufnr))
  if not rel then
    return nil, nil, "プロジェクト内のファイルを開いた状態で実行してください"
  end
  return root, rel
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
  -- GitHub に投稿済みのものは薄く
  api.nvim_set_hl(0, "ReviewCommentPostedSign", { link = "Comment", default = true })
  api.nvim_set_hl(0, "ReviewCommentPosted", { link = "Comment", default = true })
  -- PR 側のスレッドはローカルのコメントと色を変える
  local hint = api.nvim_get_hl(0, { name = "DiagnosticHint", link = false })
  api.nvim_set_hl(0, "ReviewThreadSign", { link = "DiagnosticHint", default = true })
  api.nvim_set_hl(0, "ReviewThreadText", { fg = hint.fg, default = true })
  api.nvim_set_hl(0, "ReviewThreadAuthor", { fg = hint.fg, bold = true, default = true })
  api.nvim_set_hl(0, "ReviewThreadResolved", { link = "Comment", default = true })
end

---@param bufnr integer
local function clear_buf(bufnr)
  if api.nvim_buf_is_valid(bufnr) then
    api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    api.nvim_buf_clear_namespace(bufnr, tns, 0, -1)
  end
  marks[bufnr] = nil
  tmarks[bufnr] = nil
end

---1 件分の extmark を置く
---@param bufnr integer
---@param c ReviewComment
local function place(bufnr, c)
  local last_line = api.nvim_buf_line_count(bufnr)
  local s = math.max(1, math.min(c.line_start, last_line))
  local e = math.max(s, math.min(c.line_end, last_line))
  local sign_hl = c.posted and "ReviewCommentPostedSign" or "ReviewCommentSign"
  local text_hl = c.posted and "ReviewCommentPosted" or "ReviewCommentText"
  local first_id
  for l = s, e do
    local id = api.nvim_buf_set_extmark(bufnr, ns, l - 1, 0, {
      sign_text = M.config.sign,
      sign_hl_group = sign_hl,
      priority = 20,
    })
    first_id = first_id or id
  end
  local text_lines = vim.split(c.text, "\n", { plain = true })
  if c.posted then
    text_lines[1] = string.format("[PR #%d 投稿済み] ", c.posted.pr) .. text_lines[1]
  end
  local virt = {}
  for _, t in ipairs(text_lines) do
    virt[#virt + 1] = { { "  " .. M.config.prefix, "ReviewCommentBorder" }, { t, text_hl } }
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
  local root, rel = buf_target(bufnr)
  if not rel then
    return
  end
  marks[bufnr] = {}
  for _, c in ipairs(store(root).comments) do
    if c.file == rel then
      place(bufnr, c)
    end
  end
  render_threads(bufnr, root, rel)
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
  local root, rel = buf_target(bufnr)
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
  local root, rel, err = buf_target(bufnr)
  if not rel then
    vim.notify("Review: " .. err, vim.log.levels.WARN)
    return
  end
  -- diffview で HEAD を見ているとき、そのファイルに未コミットの変更があると行番号が作業ツリーとずれる
  local dv = diffview_file(bufnr)
  if dv and dv.kind == "head" then
    local dirty = run({ "git", "status", "--porcelain", "--", rel }, root)
    if dirty and vim.trim(dirty) ~= "" then
      local answer = vim.fn.confirm(
        "Review: " .. rel .. " に未コミットの変更があります。diffview (HEAD) の行番号は作業ツリーとずれる可能性がありますが続けますか？",
        "&Yes\n&No",
        2
      )
      if answer ~= 1 then
        return
      end
    end
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
      M.render_all()
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
        M.render_all()
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
    M.render_all()
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
    local _, rel = buf_target(bufnr)
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
      prompt_title = "Review comments (i で絞り込み)",
      initial_mode = "normal",
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

-- ---------------------------------------------------------------------------
-- GitHub PR へ投稿 (gh)
-- ---------------------------------------------------------------------------

---unified diff から、ファイルごとに「変更後 (RIGHT) 側でコメントを付けられる行」の集合を作る。
---GitHub の review comment は diff のハンク内 (追加行かコンテキスト行) にしか付けられない。
---@param diff string
---@return table<string, table<integer, boolean>>  path -> { [line] = true }
function M._parse_diff(diff)
  local files = {}
  local current, new_line
  for line in (diff .. "\n"):gmatch("(.-)\r?\n") do
    local path = line:match("^%+%+%+ b/(.+)$")
    if path then
      current = {}
      files[path] = current
      new_line = nil
    elseif line:match("^%+%+%+ /dev/null") then
      current = nil
      new_line = nil
    else
      local start = line:match("^@@ %-%d+,?%d* %+(%d+),?%d* @@")
      if start then
        new_line = current and tonumber(start) or nil
      elseif new_line then
        local head = line:sub(1, 1)
        if head == "+" or head == " " or head == "" then
          current[new_line] = true
          new_line = new_line + 1
        elseif head == "-" or head == "\\" then
          -- 削除行 / "\ No newline at end of file" は右側の行番号を進めない
        else
          new_line = nil -- ハンクの外 (次の diff --git など)
        end
      end
    end
  end
  return files
end

---投稿内容を確認用のスクラッチバッファに出す
---@param payload table
local function show_payload(payload)
  vim.cmd("botright new")
  local buf = api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "lua"
  api.nvim_buf_set_name(buf, "review://publish-dry-run")
  api.nvim_buf_set_lines(buf, 0, -1, false, vim.split("-- :Review publish --dry-run\n" .. vim.inspect(payload), "\n"))
  vim.bo[buf].modifiable = false
end

---未投稿のコメントを、現在ブランチの PR にドラフト (Pending) レビューとしてまとめて投稿する。
---投稿後は GitHub 上で見直してから自分で Submit する。
---@param opts? { dry_run?: boolean, include_posted?: boolean, event?: "COMMENT" }  event を付けると Pending にせず即時投稿
function M.publish(opts)
  opts = opts or {}
  local root = root_of(api.nvim_get_current_buf())
  local st = store(root)
  local targets = vim.tbl_filter(function(c)
    return opts.include_posted or not c.posted
  end, st.comments)
  if #targets == 0 then
    vim.notify("Review: 投稿するコメントがありません (投稿済みも含めるなら :Review! publish)", vim.log.levels.WARN)
    return
  end

  vim.notify("Review: PR の情報を取得しています…")
  vim.cmd.redraw()
  local out, err = run({ "gh", "pr", "view", "--json", "number,url,headRefOid,headRefName" }, root)
  if not out then
    vim.notify("Review: 現在ブランチの PR が見つかりません\n" .. (err or ""), vim.log.levels.ERROR)
    return
  end
  local pr = vim.json.decode(out)

  -- 行番号は手元のファイルのものなので、PR の head と手元がずれていると位置が合わない
  local warns = {}
  local head = run({ "git", "rev-parse", "HEAD" }, root)
  head = head and vim.trim(head) or ""
  if head ~= pr.headRefOid then
    warns[#warns + 1] = string.format("ローカル HEAD (%s) と PR の head (%s) が違います (push 忘れ?)", head:sub(1, 7), pr.headRefOid:sub(1, 7))
  end
  local files = {}
  for _, c in ipairs(targets) do
    if not vim.tbl_contains(files, c.file) then
      files[#files + 1] = c.file
    end
  end
  local dirty = run(vim.list_extend({ "git", "status", "--porcelain", "--" }, files), root)
  if dirty and vim.trim(dirty) ~= "" then
    warns[#warns + 1] = "未コミットの変更があります:\n" .. vim.trim(dirty)
  end
  if #warns > 0 and not opts.dry_run then
    local answer = vim.fn.confirm(
      "Review: 行番号がずれる可能性があります。\n\n" .. table.concat(warns, "\n") .. "\n\n続けますか？",
      "&Yes\n&No",
      2
    )
    if answer ~= 1 then
      return
    end
  end

  -- diff の外にある行は GitHub 側で 422 になるので先に除外する
  local diff, derr = run({ "gh", "pr", "diff", tostring(pr.number) }, root)
  if not diff then
    vim.notify("Review: PR の diff を取得できませんでした\n" .. (derr or ""), vim.log.levels.ERROR)
    return
  end
  local hunks = M._parse_diff(diff)
  local comments, posted, skipped = {}, {}, {}
  for _, c in ipairs(targets) do
    local lines = hunks[c.file]
    if lines and lines[c.line_start] and lines[c.line_end] then
      local entry = { path = c.file, line = c.line_end, side = "RIGHT", body = c.text }
      if c.line_start ~= c.line_end then
        entry.start_line = c.line_start
        entry.start_side = "RIGHT"
      end
      comments[#comments + 1] = entry
      posted[#posted + 1] = c
    else
      skipped[#skipped + 1] = c
    end
  end
  local skipped_msg = ""
  if #skipped > 0 then
    skipped_msg = "\ndiff に含まれない行のためスキップ:\n  " .. table.concat(vim.tbl_map(location, skipped), "\n  ")
  end
  if #comments == 0 then
    vim.notify("Review: PR の diff に含まれる行のコメントがありません" .. skipped_msg, vim.log.levels.WARN)
    return
  end

  -- event を付けないと PENDING (ドラフト) になる。COMMENT ならその場で公開される
  local payload = { commit_id = pr.headRefOid, comments = comments, event = opts.event }
  if opts.dry_run then
    show_payload({ pr = pr.number, url = pr.url, payload = payload, skipped = vim.tbl_map(location, skipped), warnings = warns })
    return
  end
  if opts.event then
    local answer = vim.fn.confirm(
      string.format("Review: %d 件のコメントを PR #%d にその場で投稿します (ドラフトにはなりません)。送信しますか？%s", #comments, pr.number, skipped_msg),
      "&Yes\n&No",
      2
    )
    if answer ~= 1 then
      return
    end
  end

  -- 未送信のレビューは 1 つしか持てないので先に確認
  local reviews_json = run({ "gh", "api", string.format("repos/{owner}/{repo}/pulls/%d/reviews", pr.number) }, root)
  if reviews_json then
    local ok, reviews = pcall(vim.json.decode, reviews_json)
    if ok and type(reviews) == "table" then
      for _, r in ipairs(reviews) do
        if r.state == "PENDING" then
          vim.notify(
            "Review: この PR には既に未送信のレビューがあります。GitHub で送信か破棄をしてから再実行してください\n" .. (r.html_url or pr.url),
            vim.log.levels.ERROR
          )
          return
        end
      end
    end
  end

  vim.notify(string.format("Review: PR #%d に %d 件を投稿しています…", pr.number, #comments))
  vim.cmd.redraw()
  local res, perr = run({
    "gh",
    "api",
    "-X",
    "POST",
    string.format("repos/{owner}/{repo}/pulls/%d/reviews", pr.number),
    "--input",
    "-",
  }, root, vim.json.encode(payload))
  if not res then
    vim.notify("Review: 投稿に失敗しました\n" .. (perr or ""), vim.log.levels.ERROR)
    return
  end
  local review = vim.json.decode(res)
  local now = os.date("%Y-%m-%dT%H:%M:%S")
  for _, c in ipairs(posted) do
    c.posted = { pr = pr.number, review_id = review.id, url = review.html_url or pr.url, at = now }
  end
  -- 投稿された個々の comment id を控えておくと、あとでスレッド一覧で「自分の指摘」が分かる
  local rc = run({ "gh", "api", string.format("repos/{owner}/{repo}/pulls/%d/reviews/%d/comments", pr.number, review.id) }, root)
  if rc then
    local ok, list = pcall(vim.json.decode, rc, { luanil = { object = true, array = true } })
    if ok and type(list) == "table" then
      for _, remote in ipairs(list) do
        for _, c in ipairs(posted) do
          if c.file == remote.path and c.line_end == remote.line and c.text == (remote.body or ""):gsub("\r\n", "\n") then
            c.posted.comment_id = remote.id
          end
        end
      end
    end
  end
  save(root)
  M.render_all()
  local url = review.html_url or pr.url
  vim.fn.setreg("+", url)
  local msg
  if opts.event then
    msg = string.format("Review: %d 件を PR #%d にレビューコメントとして投稿しました (URL をコピー済み)\n%s%s", #posted, pr.number, url, skipped_msg)
  else
    msg = string.format(
      "Review: %d 件を PR #%d のドラフトレビューに追加しました。GitHub で確認して Submit してください (URL をコピー済み)\n%s%s",
      #posted,
      pr.number,
      url,
      skipped_msg
    )
  end
  vim.notify(msg, #skipped > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
end

-- ---------------------------------------------------------------------------
-- PR のレビュースレッド (相手の返信など) を表示・返信・解決する
-- ---------------------------------------------------------------------------

local repo_cache = {} ---@type table<string, { owner: string, name: string }>

---owner / repo 名
---@param root string
---@return { owner: string, name: string }|nil, string|nil
local function repo_info(root)
  if repo_cache[root] then
    return repo_cache[root]
  end
  local out, err = run({ "gh", "repo", "view", "--json", "nameWithOwner" }, root)
  if not out then
    return nil, err
  end
  local ok, data = pcall(vim.json.decode, out)
  local owner, name
  if ok and type(data) == "table" and type(data.nameWithOwner) == "string" then
    -- `a and s:match()` と書くと match の 2 つ目の戻り値 (name) が捨てられるので分けて書く
    owner, name = data.nameWithOwner:match("^([^/]+)/(.+)$")
  end
  if not owner or not name then
    return nil, "リポジトリ名を取得できませんでした"
  end
  repo_cache[root] = { owner = owner, name = name }
  return repo_cache[root]
end

local THREADS_QUERY = [[
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id isResolved isOutdated path line startLine originalLine diffSide
          comments(first: 100) {
            nodes { databaseId author { login } body createdAt url }
          }
        }
      }
    }
  }
}
]]

---GraphQL の応答 (decode 済み) をスレッド配列にする
---@param data table
---@return ReviewThread[]
function M._threads_from_graphql(data)
  local pr = data and data.data and data.data.repository and data.data.repository.pullRequest
  local nodes = pr and pr.reviewThreads and pr.reviewThreads.nodes or {}
  local items = {}
  for _, n in ipairs(nodes) do
    local comments = {}
    for _, c in ipairs(n.comments and n.comments.nodes or {}) do
      comments[#comments + 1] = {
        id = c.databaseId,
        author = c.author and c.author.login or "ghost",
        body = (c.body or ""):gsub("\r\n", "\n"), -- GitHub の本文は CRLF で返る
        created_at = c.createdAt or "",
        url = c.url or "",
      }
    end
    if #comments > 0 then
      items[#items + 1] = {
        id = n.id,
        path = n.path,
        line = n.line,
        start_line = n.startLine,
        original_line = n.originalLine,
        side = n.diffSide or "RIGHT",
        resolved = n.isResolved == true,
        outdated = n.isOutdated == true,
        comments = comments,
      }
    end
  end
  return items
end

---ローカルファイル上でスレッドを置く行。LEFT 側 (削除行) は置けないので nil
---@param t ReviewThread
---@return integer|nil
local function thread_anchor(t)
  if t.side == "LEFT" then
    return nil
  end
  return t.line or t.original_line
end

---@param t ReviewThread
---@return string
local function thread_location(t)
  local anchor = thread_anchor(t) or t.original_line
  if not anchor then
    return t.path
  end
  if t.start_line and t.line and t.start_line ~= t.line then
    return string.format("%s:L%d-L%d", t.path, t.start_line, t.line)
  end
  return string.format("%s:L%d", t.path, anchor)
end

---テスト・内部用: 取得結果を差し替えて描画し直す
---@param root string
---@param data { pr: integer, url: string, items: ReviewThread[] }
function M._set_threads(root, data)
  data.fetched_at = data.fetched_at or os.date("%Y-%m-%dT%H:%M:%S")
  threads[root] = data
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_get_name(bufnr) ~= "" and root_of(bufnr) == root then
      M.render(bufnr)
    end
  end
end

---スレッド 1 件分の仮想行
---@param t ReviewThread
---@return table
local function thread_virt_lines(t)
  local text_hl = t.resolved and "ReviewThreadResolved" or "ReviewThreadText"
  local author_hl = t.resolved and "ReviewThreadResolved" or "ReviewThreadAuthor"
  local virt = {}
  local function add(text, hl)
    virt[#virt + 1] = { { "  " .. M.config.prefix, "ReviewCommentBorder" }, { text, hl } }
  end
  for i, c in ipairs(t.comments) do
    local flags = ""
    if i == 1 then
      flags = (t.resolved and " [resolved]" or "") .. (t.outdated and " [outdated]" or "")
    end
    add(string.format("%s@%s · %s%s", i == 1 and "💬 " or "↳ ", c.author, c.created_at:sub(1, 10), flags), author_hl)
    local body = vim.split(c.body, "\n", { plain = true })
    for j = 1, math.min(#body, M.config.thread_max_lines) do
      add("   " .. body[j], text_hl)
    end
    if #body > M.config.thread_max_lines then
      add("   … (<leader>av で全文)", "ReviewThreadResolved")
    end
  end
  return virt
end

---バッファに PR スレッドを描く (M.render から呼ばれる。namespace は clear_buf で消えている前提)
---@param bufnr integer
---@param root string
---@param rel string
render_threads = function(bufnr, root, rel)
  local data = threads[root]
  if not data then
    return
  end
  tmarks[bufnr] = {}
  local last_line = api.nvim_buf_line_count(bufnr)
  for _, t in ipairs(data.items) do
    if t.path == rel then
      local anchor = thread_anchor(t)
      if anchor then
        anchor = math.max(1, math.min(anchor, last_line))
        local id = api.nvim_buf_set_extmark(bufnr, tns, anchor - 1, 0, {
          sign_text = M.config.thread_sign,
          sign_hl_group = t.resolved and "ReviewThreadResolved" or "ReviewThreadSign",
          priority = 19,
          virt_lines = thread_virt_lines(t),
        })
        tmarks[bufnr][t.id] = id
      end
    end
  end
end

---カーソル行を含むスレッド
---@param bufnr integer
---@return ReviewThread[]
local function threads_at_cursor(bufnr)
  local tm = tmarks[bufnr]
  local data = threads[root_of(bufnr)]
  if not tm or not data then
    return {}
  end
  local line = api.nvim_win_get_cursor(0)[1]
  local out = {}
  for _, t in ipairs(data.items) do
    local id = tm[t.id]
    if id then
      local pos = api.nvim_buf_get_extmark_by_id(bufnr, tns, id, {})
      if pos[1] then
        local e = pos[1] + 1
        local s = e - ((t.line and t.start_line) and (t.line - t.start_line) or 0)
        if s <= line and line <= e then
          out[#out + 1] = t
        end
      end
    end
  end
  return out
end

---@param cands ReviewThread[]
---@param prompt string
---@param cb fun(t: ReviewThread)
local function pick_thread(cands, prompt, cb)
  if #cands == 0 then
    vim.notify("Review: カーソル位置に PR スレッドはありません (<leader>af で取得)", vim.log.levels.WARN)
    return
  end
  if #cands == 1 then
    cb(cands[1])
    return
  end
  vim.ui.select(cands, {
    prompt = prompt,
    format_item = function(t)
      return string.format("@%s: %s", t.comments[1].author, first_line(t.comments[1].body))
    end,
  }, function(t)
    if t then
      cb(t)
    end
  end)
end

---現在ブランチの PR のレビュースレッドを取得して表示する
---@param opts? { silent?: boolean }
---@return boolean ok
function M.fetch_threads(opts)
  opts = opts or {}
  local root = root_of(api.nvim_get_current_buf())
  if not opts.silent then
    vim.notify("Review: PR のスレッドを取得しています…")
    vim.cmd.redraw()
  end
  local out, err = run({ "gh", "pr", "view", "--json", "number,url" }, root)
  if not out then
    vim.notify("Review: 現在ブランチの PR が見つかりません\n" .. (err or ""), vim.log.levels.ERROR)
    return false
  end
  local pr = vim.json.decode(out)
  local repo, rerr = repo_info(root)
  if not repo then
    vim.notify("Review: " .. rerr, vim.log.levels.ERROR)
    return false
  end
  local res, gerr = run({
    "gh",
    "api",
    "graphql",
    "-f",
    "query=" .. THREADS_QUERY,
    "-F",
    "owner=" .. repo.owner,
    "-F",
    "repo=" .. repo.name,
    "-F",
    "number=" .. pr.number,
  }, root)
  if not res then
    vim.notify("Review: スレッドを取得できませんでした\n" .. (gerr or ""), vim.log.levels.ERROR)
    return false
  end
  local ok, data = pcall(vim.json.decode, res, { luanil = { object = true, array = true } })
  if not ok then
    vim.notify("Review: GraphQL の応答を読めませんでした", vim.log.levels.ERROR)
    return false
  end
  local items = M._threads_from_graphql(data)
  M._set_threads(root, { pr = pr.number, url = pr.url, items = items })
  if not opts.silent then
    local open = 0
    for _, t in ipairs(items) do
      if not t.resolved then
        open = open + 1
      end
    end
    vim.notify(string.format("Review: PR #%d のスレッド %d 件 (未解決 %d 件) を取得しました", pr.number, #items, open))
  end
  return true
end

---読み取り専用のフロート
---@param lines string[]
---@param title string
local function open_reader(lines, title)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local width = math.max(40, math.min(100, math.floor(vim.o.columns * 0.8)))
  local height = math.max(5, math.min(#lines + 1, math.floor(vim.o.lines * 0.8)))
  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "left",
    footer = " q 閉じる ",
    footer_pos = "right",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.keymap.set("n", "q", function()
    if api.nvim_win_is_valid(win) then
      api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })
end

---スレッドを Markdown 行にする
---@param t ReviewThread
---@return string[]
local function thread_markdown(t)
  local lines = {
    string.format("## %s%s%s", thread_location(t), t.resolved and "  [resolved]" or "", t.outdated and "  [outdated]" or ""),
    "",
  }
  for _, c in ipairs(t.comments) do
    lines[#lines + 1] = string.format("### @%s  %s", c.author, c.created_at:gsub("T", " "):gsub("Z$", ""))
    lines[#lines + 1] = ""
    vim.list_extend(lines, vim.split(c.body, "\n", { plain = true }))
    lines[#lines + 1] = ""
  end
  return lines
end

---カーソル行のスレッド全文をフロートで読む
function M.view_thread()
  local bufnr = api.nvim_get_current_buf()
  pick_thread(threads_at_cursor(bufnr), "表示するスレッド", function(t)
    open_reader(thread_markdown(t), "thread: " .. thread_location(t))
  end)
end

---カーソル行のスレッドに返信する (即時公開)
function M.reply()
  local bufnr = api.nvim_get_current_buf()
  local root = root_of(bufnr)
  local data = threads[root]
  if not data then
    vim.notify("Review: 先に <leader>af で PR のスレッドを取得してください", vim.log.levels.WARN)
    return
  end
  pick_thread(threads_at_cursor(bufnr), "返信するスレッド", function(t)
    local first = t.comments[1]
    open_editor({
      title = string.format("reply: @%s %s", first.author, thread_location(t)),
      text = "",
      on_submit = function(text)
        local answer = vim.fn.confirm(
          string.format("Review: PR #%d のスレッド (@%s) に返信します。すぐに公開されますが送信しますか？", data.pr, first.author),
          "&Yes\n&No",
          2
        )
        if answer ~= 1 then
          return
        end
        local repo, rerr = repo_info(root)
        if not repo then
          vim.notify("Review: " .. rerr, vim.log.levels.ERROR)
          return
        end
        local _, err = run({
          "gh",
          "api",
          "-X",
          "POST",
          string.format("repos/%s/%s/pulls/%d/comments/%d/replies", repo.owner, repo.name, data.pr, first.id),
          "--input",
          "-",
        }, root, vim.json.encode({ body = text }))
        if err then
          vim.notify("Review: 返信に失敗しました\n" .. err, vim.log.levels.ERROR)
          return
        end
        vim.notify("Review: 返信しました " .. thread_location(t))
        M.fetch_threads({ silent = true })
      end,
    })
  end)
end

---カーソル行のスレッドを resolved / unresolved に切り替える
function M.resolve()
  local bufnr = api.nvim_get_current_buf()
  local root = root_of(bufnr)
  pick_thread(threads_at_cursor(bufnr), "切り替えるスレッド", function(t)
    local mutation = t.resolved and "unresolveReviewThread" or "resolveReviewThread"
    local query = string.format("mutation($id: ID!) { %s(input: { threadId: $id }) { thread { isResolved } } }", mutation)
    local _, err = run({ "gh", "api", "graphql", "-f", "query=" .. query, "-F", "id=" .. t.id }, root)
    if err then
      vim.notify("Review: 切り替えに失敗しました\n" .. err, vim.log.levels.ERROR)
      return
    end
    vim.notify(string.format("Review: %s を %s にしました", thread_location(t), t.resolved and "unresolved" or "resolved"))
    M.fetch_threads({ silent = true })
  end)
end

---PR スレッドの一覧 (Telescope、無ければ quickfix)。未取得なら取得してから開く
function M.list_threads()
  local root = root_of(api.nvim_get_current_buf())
  if not threads[root] and not M.fetch_threads() then
    return
  end
  local data = threads[root]
  if #data.items == 0 then
    vim.notify("Review: PR にスレッドはありません")
    return
  end

  -- 自分が publish した指摘から始まるスレッドには印を付ける
  local mine = {}
  for _, c in ipairs(store(root).comments) do
    if c.posted and c.posted.comment_id then
      mine[c.posted.comment_id] = true
    end
  end
  local function status(t)
    local parts = {}
    if mine[t.comments[1].id] then
      parts[#parts + 1] = "★"
    end
    if t.resolved then
      parts[#parts + 1] = "resolved"
    end
    if t.outdated then
      parts[#parts + 1] = "outdated"
    end
    return table.concat(parts, " ")
  end
  local function summary(t)
    local first = t.comments[1]
    local extra = #t.comments > 1 and string.format(" (+%d)", #t.comments - 1) or ""
    return string.format("@%s: %s%s", first.author, first_line(first.body), extra)
  end
  local function jump_to(t)
    vim.cmd.edit(vim.fn.fnameescape(root .. "/" .. t.path))
    local anchor = thread_anchor(t) or t.original_line
    if anchor then
      api.nvim_win_set_cursor(0, { math.min(anchor, api.nvim_buf_line_count(0)), 0 })
    end
  end

  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.fn.setqflist({}, " ", {
      title = string.format("PR #%d threads", data.pr),
      items = vim.tbl_map(function(t)
        return {
          filename = root .. "/" .. t.path,
          lnum = thread_anchor(t) or t.original_line or 1,
          text = (status(t) ~= "" and ("[" .. status(t) .. "] ") or "") .. summary(t),
        }
      end, data.items),
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
  for _, t in ipairs(data.items) do
    loc_width = math.max(loc_width, vim.fn.strdisplaywidth(thread_location(t)))
  end
  local displayer = entry_display.create({
    separator = "  ",
    items = { { width = math.min(loc_width, 45) }, { width = 12 }, { remaining = true } },
  })

  pickers
    .new({}, {
      prompt_title = string.format("PR #%d threads (<C-v> 全文, / で絞り込み)", data.pr),
      -- j/k で選びたいのでノーマルモードで開く。絞り込みたいときは i で入力へ
      initial_mode = "normal",
      finder = finders.new_table({
        results = data.items,
        entry_maker = function(t)
          local bodies = {}
          for _, c in ipairs(t.comments) do
            bodies[#bodies + 1] = c.author .. " " .. c.body
          end
          return {
            value = t,
            ordinal = thread_location(t) .. " " .. status(t) .. " " .. table.concat(bodies, " "),
            display = function(entry)
              local v = entry.value
              return displayer({
                { thread_location(v), v.resolved and "Comment" or "TelescopeResultsIdentifier" },
                { status(v), "TelescopeResultsComment" },
                { summary(v), v.resolved and "Comment" or "" },
              })
            end,
            filename = root .. "/" .. t.path,
            lnum = thread_anchor(t) or t.original_line or 1,
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
          map(mode, "<C-v>", function()
            local entry = action_state.get_selected_entry()
            if not entry then
              return
            end
            actions.close(prompt_bufnr)
            open_reader(thread_markdown(entry.value), "thread: " .. thread_location(entry.value))
          end)
        end
        return true
      end,
    })
    :find()
end

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
  publish = function(cmd)
    M.publish({ dry_run = cmd.fargs[2] == "--dry-run", include_posted = cmd.bang })
  end,
  submit = function(cmd)
    M.publish({ event = "COMMENT", include_posted = cmd.bang })
  end,
  toggle = M.toggle,
  clear = M.clear,
  fetch = function()
    M.fetch_threads()
  end,
  threads = M.list_threads,
  view = M.view_thread,
  reply = M.reply,
  resolve = M.resolve,
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
      tmarks[ev.buf] = nil
      dv_cache[ev.buf] = nil
    end,
  })
  -- diffview の差分バッファは中身が後から入るので、読み込み完了のイベントで描き直す
  api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "DiffviewDiffBufRead",
    callback = function()
      local bufnr = api.nvim_get_current_buf()
      dv_cache[bufnr] = nil
      M.render(bufnr)
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
    nargs = "*",
    range = true,
    bang = true,
    desc = "Review comments",
    complete = function(arg, line)
      if line:match("^%s*%S+!?%s+%S+%s") then
        return { "--dry-run" }
      end
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
  map("n", "<leader>ap", function()
    M.publish()
  end, { desc = "Review: PR にドラフトレビューとして投稿 (gh)" })
  map("n", "<leader>aP", function()
    M.publish({ event = "COMMENT" })
  end, { desc = "Review: PR にその場で投稿 (ドラフトなし)" })
  map("n", "<leader>af", function()
    M.fetch_threads()
  end, { desc = "Review: PR のスレッドを取得して表示" })
  map("n", "<leader>aL", M.list_threads, { desc = "Review: PR スレッド一覧" })
  map("n", "<leader>av", M.view_thread, { desc = "Review: スレッド全文を読む" })
  map("n", "<leader>ar", M.reply, { desc = "Review: スレッドに返信" })
  map("n", "<leader>aR", M.resolve, { desc = "Review: スレッドを resolve/unresolve" })
  map("n", "<leader>at", M.toggle, { desc = "Review: 表示トグル" })
  map("n", "<leader>ax", M.clear, { desc = "Review: 全コメントを削除" })
  map("n", "]a", M.next, { desc = "Review: 次のコメント" })
  map("n", "[a", M.prev, { desc = "Review: 前のコメント" })

  -- setup より前に開き終わっているバッファにも描く
  M.render_all()
end

return M

-- nvim-treesitter (master ブランチ) のクエリ用ディレクティブを Neovim 0.12 向けに直す。
--
-- Neovim 0.11 以降、クエリの match[capture_id] は 1 つの TSNode ではなく TSNode[] (配列) になった。
-- master ブランチの query_predicates.lua はそれを知らずに match[id]:range() などを呼ぶので、
-- 該当ディレクティブを使うインジェクションクエリが走った瞬間にエラーになる。
-- 例: Ruby はヒアドキュメント (<<~SQL など) の言語判定に #downcase! を使うため、
--     ヒアドキュメントが 1 つでもあるファイルでシンタックスハイライトが止まる。
-- ここでは同じ名前・同じ意味のディレクティブを両 API 対応で上書き登録する。
return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function(plugin)
      -- ここまでは LazyVim 本体の init と同じ (rtp と custom query の先行登録)
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")

      local query = vim.treesitter.query

      ---match[id] が TSNode でも TSNode[] でも、代表 (最後) のノードを返す
      ---@return TSNode|nil
      local function node_of(match, id)
        local nodes = match[id]
        if type(nodes) == "table" then
          return nodes[#nodes]
        end
        return nodes
      end

      -- markdown のコードフェンス: ```js などの info string を言語名にする
      query.add_directive("set-lang-from-info-string!", function(match, _, source, pred, metadata)
        local node = node_of(match, pred[2])
        if not node then
          return
        end
        -- js -> javascript のような別名解決は languagetree の resolve_lang() が
        -- filetype 経由でやってくれるので、ここでは info string をそのまま渡す
        metadata["injection.language"] = vim.treesitter.get_node_text(node, source):lower()
      end, { force = true })

      -- html の <script type="..."> から言語を決める
      local script_type_languages = {
        importmap = "json",
        module = "javascript",
        ["application/ecmascript"] = "javascript",
        ["text/ecmascript"] = "javascript",
      }
      query.add_directive("set-lang-from-mimetype!", function(match, _, source, pred, metadata)
        local node = node_of(match, pred[2])
        if not node then
          return
        end
        local value = vim.treesitter.get_node_text(node, source)
        local parts = vim.split(value, "/", {})
        metadata["injection.language"] = script_type_languages[value] or parts[#parts]
      end, { force = true })

      -- キャプチャの文字列を小文字にして言語名として使う (ruby / bash / nix のヒアドキュメントなど)
      query.add_directive("downcase!", function(match, _, source, pred, metadata)
        local id = pred[2]
        local node = node_of(match, id)
        if not node then
          return
        end
        local text = vim.treesitter.get_node_text(node, source, { metadata = metadata[id] }) or ""
        metadata[id] = metadata[id] or {}
        metadata[id].text = text:lower()
      end, { force = true })

      -- インジェクション範囲の末尾の空行を削る
      query.add_directive("trim!", function(match, _, bufnr, pred, metadata)
        for i = 2, #pred do
          local id = pred[i]
          local node = node_of(match, id)
          if node then
            local start_row, start_col, end_row, end_col = node:range()
            if end_col == 0 then
              while end_row > start_row do
                local line = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)[1]
                if line ~= "" then
                  break
                end
                end_row = end_row - 1
              end
              if start_row < end_row or (start_row == end_row and start_col <= end_col) then
                metadata[id] = metadata[id] or {}
                metadata[id].range = { start_row, start_col, end_row, end_col }
              end
            end
          end
        end
      end, { force = true })
    end,
  },
}

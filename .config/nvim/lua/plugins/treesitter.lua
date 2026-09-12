return {
  -- markdown のシンタックスハイライトが効かない問題の修正
  --
  -- lazy-lock で 2024-07 に固定している nvim-treesitter が、
  -- queries/markdown/injections.scm から自前ディレクティブ
  -- `#set-lang-from-info-string!` を呼んでいる。そのハンドラは
  -- `match[capture_id]` が TSNode を返す旧 API 前提で書かれているが、
  -- nvim 0.11+ では TSNode[] (リスト) を返すようになったため
  -- get_node_text() の中で `attempt to call method 'range' (a nil value)`
  -- を投げ、injections.scm 全体の評価が落ちる。
  --
  -- 結果 markdown_inline (太字・斜体・インラインコード・リンク) も
  -- フェンスドコードブロックの言語 inject も一切効かず、見出し以外が
  -- ほぼ無色になる。ここで新 API 対応版を force 上書きする。
  -- nvim-treesitter を新しい版に更新できたら削除可。
  --
  -- 上書きは init で行う必要がある。LazyVim 側の init が起動時点で
  -- query_predicates を require して壊れたハンドラを登録してしまうため、
  -- その init を丸ごと差し替えて (元の処理 + 上書き) を行う。
  {
    "nvim-treesitter/nvim-treesitter",
    init = function(plugin)
      -- ここまでは LazyVim 本体の init と同じ (rtp と custom query の先行登録)
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")

      vim.treesitter.query.add_directive("set-lang-from-info-string!", function(match, _, source, pred, metadata)
        local nodes = match[pred[2]]
        -- 旧 API (TSNode) / 新 API (TSNode[]) の両対応
        local node = type(nodes) == "table" and nodes[#nodes] or nodes
        if not node then
          return
        end
        local alias = vim.treesitter.get_node_text(node, source):lower()
        -- js -> javascript のような別名解決は languagetree の resolve_lang() が
        -- filetype 経由でやってくれるので、ここでは info string をそのまま渡す
        metadata["injection.language"] = alias
      end, { force = true })
    end,
  },
}

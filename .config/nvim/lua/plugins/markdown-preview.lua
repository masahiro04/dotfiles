return {
  -- LazyVim extras (lang.markdown) の build 上書き
  --
  -- extras 側は build に mkdp#util#install() を指定しているが、これは
  -- 非同期ターミナルで install.sh を走らせる実装のため lazy.nvim の
  -- build コンテキストでは完走せず、しかも失敗が成功扱いになる。
  -- 結果 app/bin (プリビルドバイナリ) も app/node_modules も無い状態になり、
  -- :MarkdownPreview が `Cannot find module 'tslib'` で落ちる。
  {
    "iamcco/markdown-preview.nvim",
    build = function(plugin)
      local app = vim.fn.shellescape(plugin.dir .. "/app")
      -- 1) プリビルドバイナリを取得する（推奨経路）
      local out = vim.fn.system({ "sh", "-c", ("cd %s && ./install.sh"):format(app) })
      if vim.v.shell_error == 0 then
        return
      end
      -- 2) 失敗したら node フォールバック用に依存を入れる
      vim.notify("[markdown-preview] install.sh failed, falling back to yarn:\n" .. out, vim.log.levels.WARN)
      out = vim.fn.system({ "sh", "-c", ("cd %s && npx --yes yarn install"):format(app) })
      if vim.v.shell_error ~= 0 then
        vim.notify("[markdown-preview] yarn install failed:\n" .. out, vim.log.levels.ERROR)
      end
    end,
  },
}

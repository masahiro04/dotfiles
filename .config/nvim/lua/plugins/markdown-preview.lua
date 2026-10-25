return {
  -- LazyVim extras (lang.markdown) の build 上書き
  --
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

return {
  "folke/tokyonight.nvim",
  lazy = true,
  priority = 1000,
  opts = function()
    return {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      -- on_highlights は styles より後に適用されるので、
      -- floats = "transparent" を維持したまま LSP フロートだけ不透明にできる。
      -- 実際にこれらを使うのは lua/plugins/lsp-hover.lua の winhighlight。
      on_highlights = function(hl, c)
        -- 透過エディタの上で「浮いた面」に見える、bg (#1a1b26) より少し明るいトーン
        local float_bg = "#1b1e2e"

        hl.LspFloatNormal = { bg = float_bg, fg = c.fg }
        hl.LspFloatBorder = { bg = float_bg, fg = c.blue }
        hl.LspFloatTitle = { bg = c.blue, fg = c.bg_dark, bold = true }
        hl.LspFloatCursorLine = { bg = c.bg_highlight }

        -- 0.12 は hover 中、元バッファの該当範囲を LspReferenceTarget で
        -- ハイライトする。tokyonight の 2024-07 pin は未定義なので補う。
        hl.LspReferenceTarget = { bg = c.bg_highlight }

        -- render-markdown.nvim
        -- 既定は H1Bg=DiffText / H2Bg=DiffAdd のように diff 色へのリンクなので、
        -- ドキュメント表示だと色が強すぎて浮く。tokyonight のアクセント色を
        -- フロート背景に薄く溶かした帯に差し替える。
        local util = require("tokyonight.util")
        local function band(color)
          return util.blend_bg(color, 0.18, float_bg)
        end
        local code_bg = util.blend_bg(c.bg_highlight, 0.6, float_bg)

        hl.RenderMarkdownH1Bg = { fg = c.blue, bg = band(c.blue), bold = true }
        hl.RenderMarkdownH2Bg = { fg = c.cyan, bg = band(c.cyan), bold = true }
        hl.RenderMarkdownH3Bg = { fg = c.green, bg = band(c.green), bold = true }
        hl.RenderMarkdownH4Bg = { fg = c.yellow, bg = band(c.yellow), bold = true }
        hl.RenderMarkdownH5Bg = { fg = c.magenta, bg = band(c.magenta), bold = true }
        hl.RenderMarkdownH6Bg = { fg = c.purple, bg = band(c.purple), bold = true }

        hl.RenderMarkdownCode = { bg = code_bg }
        hl.RenderMarkdownCodeInfo = { fg = c.comment, bg = code_bg, italic = true }
        hl.RenderMarkdownCodeInline = { fg = c.blue5, bg = code_bg }
        hl.RenderMarkdownBullet = { fg = c.blue }
        hl.RenderMarkdownDash = { fg = c.fg_gutter }
        hl.RenderMarkdownTableHead = { fg = c.blue, bold = true }
        hl.RenderMarkdownTableRow = { fg = c.fg_dark }
        hl.RenderMarkdownQuote = { fg = c.purple }
        hl.RenderMarkdownLink = { fg = c.cyan }
      end,
    }
  end,
}

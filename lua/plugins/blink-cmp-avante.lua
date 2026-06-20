return {
  -- Integrate Avante (Claude) as a blink.cmp source. Copilot is not used,
  -- to keep a single, Claude-first completion experience.
  "saghen/blink.cmp",
  -- Disable Avante completion source inside VSCode/Cursor
  cond = function() return not vim.g.vscode end,
  dependencies = {
    "Kaiser-Yang/blink-cmp-avante",
    -- Snippet engine + community snippets (recommended)
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",
  },
  opts = function(_, opts)
    opts = opts or {}
    opts.sources = opts.sources or {}
    opts.snippets = vim.tbl_deep_extend("force", { preset = "luasnip" }, opts.snippets or {})

    local defs = opts.sources.default or { "lsp", "avante", "path", "snippets", "buffer" }
    defs = vim.deepcopy(defs)
    if vim.g.avante_integration_enabled ~= true then
      defs = vim.tbl_filter(function(s) return s ~= "avante" end, defs)
    end
    opts.sources.default = defs

    opts.sources.providers = vim.tbl_deep_extend("force", {
      avante = {
        module = "blink-cmp-avante",
        name = "Avante",
        opts = {},
      },
    }, opts.sources.providers or {})

    return opts
  end,
}

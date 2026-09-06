return {
  -- Completion: LSP-first with LuaSnip snippets. No AI completion source here;
  -- AI editing lives in ai-codecompanion.lua / ai-claudecode.lua. Copilot is
  -- intentionally not used (Claude-only stack).
  "saghen/blink.cmp",
  cond = function()
    return not vim.g.vscode
  end,
  dependencies = {
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",
  },
  opts = function(_, opts)
    opts = opts or {}
    opts.snippets = vim.tbl_deep_extend("force", { preset = "luasnip" }, opts.snippets or {})
    -- Native cmdline (see plugins/noice.lua). Blink cmdline UI was the only
    -- visible piece when typing ":" and hid the actual command line.
    opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, { enabled = false })
    return opts
  end,
}

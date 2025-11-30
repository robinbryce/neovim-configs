return {
  "zbirenbaum/copilot.lua",
  enabled = false, -- temporarily disabled for troubleshooting startup issues
  opts = function(_, opts)
    -- Merge with defaults, disabling suggestions and panel
    -- Per recomendation from https://github.com/giuxtaposition/blink-cmp-copilot
    opts.suggestion = vim.tbl_deep_extend("force", opts.suggestion or {}, {
      enabled = false,
    })
    opts.panel = vim.tbl_deep_extend("force", opts.panel or {}, {
      enabled = false,
    })
  end,
}

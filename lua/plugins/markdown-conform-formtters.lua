return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    -- Override just the markdown formatter config
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.markdown = {} -- or { "prettier" }

    -- return the modified options
    return opts
  end,
}

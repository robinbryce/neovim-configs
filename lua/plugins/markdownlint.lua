return {
  "nvimtools/none-ls.nvim", -- null-ls (used by LazyVim)
  optional = true,
  opts = function(_, opts)
    local nls = require("null-ls")

    opts.sources = opts.sources or {}
    vim.list_extend(opts.sources, {
      nls.builtins.diagnostics.markdownlint.with({
        -- Optional: force a specific config path
        -- extra_args = { "--config", vim.fn.expand("~/.markdownlint.json") },
        -- Optional: only lint markdown files
        filetypes = { "markdown" },
      }),
    })
  end,
}

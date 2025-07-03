return {
  "jay-babu/mason-nvim-dap.nvim",
  opts = function(_, opts)
    -- Add "python" to the existing list
    table.insert(opts.ensure_installed, "python")
  end,
}

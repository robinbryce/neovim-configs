return {
  "leoluz/nvim-dap-go",
  ft = "go",
  opts = function(_, opts)
    opts.delve = opts.delve or {}
    opts.delve.build_flags = "-tags=unit,integration,e2e,azurite"
  end,
}

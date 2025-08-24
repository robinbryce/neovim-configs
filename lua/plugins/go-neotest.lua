return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/neotest-go",
  },
  opts = function(_, opts)
    opts.adapters = opts.adapters or {}
    opts.adapters["neotest-go"] = {
      go_test_args = { "-v", "-tags=unit,integration,e2e,azurite", "-count=1", "-timeout=60s" },
      dap_enabled = true, -- enable debugging with dap-go
    }
  end,
}

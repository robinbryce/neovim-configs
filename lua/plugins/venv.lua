return {
  "linux-cultist/venv-selector.nvim",
  dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
  opts = {
    -- Default paths where uv stores venvs
    -- Adjust if you use a different layout
    search_venv_managers = true,
    search_workspace = true,
    name = ".venv", -- the default uv venv name
  },
  keys = {
    { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    { "<leader>cV", "<cmd>VenvSelectCached<cr>", desc = "Re-select Last VirtualEnv" },
  },
  event = "VeryLazy",
}

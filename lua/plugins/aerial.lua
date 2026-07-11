return {
  {
    "stevearc/aerial.nvim",
    -- opts will be merged with the parent spec
    -- https://github.com/stevearc/aerial.nvim?tab=readme-ov-file#options
    opts = {
      manage_folds = true,
    },
    -- Aerial on <leader>o (init.lua); free <leader>cs from the LazyVim extra default.
    keys = {
      { "<leader>cs", false },
    },
  },
}

return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.explorer = opts.explorer or {}
    opts.explorer.show_hidden = true
    opts.explorer.respect_gitignore = false
  end,
}

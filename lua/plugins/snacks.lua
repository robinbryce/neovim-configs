return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.explorer = opts.explorer or {}
    opts.explorer.show_hidden = true
    -- Respect .gitignore in large monorepos (e.g. forestrie); still show dotfiles.
    opts.explorer.respect_gitignore = true
  end,
}

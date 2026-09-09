return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    -- `show_hidden` / `respect_gitignore` are not real Snacks options (silent
    -- no-ops), and `opts.explorer` is the wrong namespace anyway: that table
    -- only takes `replace_netrw` / `trash` (see snacks/explorer/init.lua).
    -- The explorer *picker source*'s dotfile/gitignore filters live under
    -- `picker.sources.explorer` (see snacks/picker/config/sources.lua: the
    -- `files` source, whose `Config` the explorer source shares, defines
    -- `hidden` and `ignored`, both boolean, both default false).
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    opts.picker.sources.explorer = opts.picker.sources.explorer or {}
    opts.picker.sources.explorer.hidden = true -- show dotfiles
    -- Keep gitignored entries excluded: this config's cwd is often a
    -- multi-worktree monorepo root with dozens of node_modules trees
    -- underneath (millions of files combined) -- `ignored = true` walks/
    -- renders all of them and pegs the CPU, the same failure mode fixed for
    -- neo-tree in lua/plugins/neo-tree.lua.
    opts.picker.sources.explorer.ignored = false
  end,
}

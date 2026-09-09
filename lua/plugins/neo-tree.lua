return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    -- opts will be merged with the parent spec
    -- https://github.com/stevearc/aerial.nvim?tab=readme-ov-file#options
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          -- Keep gitignored dirs (node_modules etc.) hidden: this config's cwd
          -- is often a multi-worktree monorepo root with dozens of
          -- node_modules trees underneath (millions of files combined).
          -- Setting this to false makes neo-tree walk/render all of them,
          -- which pegs the CPU and bloats memory. Default is `true`.
          hide_gitignored = true,
        },
      },
    },
  },
}

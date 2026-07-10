return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      -- Avoid libuv watchers on huge trees (node_modules, .worktrees, etc.).
      use_libuv_file_watcher = false,
      follow_current_file = { enabled = false },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = true,
        hide_by_name = {},
        never_show = {},
      },
    },
  },
}

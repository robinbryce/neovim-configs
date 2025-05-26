return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- show filtered (hidden) items
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_by_name = {},
        never_show = {},
      },
    },
  },
}

-- LazyVim json extra (lazyvim.json) already enables jsonls + schemastore; options.lua maps
-- .json → jsonc. Ensure the jsonc treesitter parser is installed for comment-aware syntax.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "jsonc" },
    },
  },
}

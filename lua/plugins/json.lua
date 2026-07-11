-- LazyVim json extra (lazyvim.json) already enables jsonls + schemastore; options.lua maps
-- .json → jsonc. On the nvim-treesitter main branch there is no separate "jsonc" parser
-- (Neovim maps the jsonc filetype to the json language), so ensure "json" instead.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "json" },
    },
  },
}

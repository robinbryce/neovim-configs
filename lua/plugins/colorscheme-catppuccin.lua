return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      term_colors = true,
      -- Comments in Catppuccin default to overlay2, a pale grey-blue that is
      -- hard to read. Use the palette green instead: the same shade `String`
      -- gets, i.e. the colour of module paths in import lines (TypeScript,
      -- Go, Solidity, ...). Setting the base `Comment` group is enough for
      -- every language: Tree-sitter `@comment` / `@comment.documentation` and
      -- the LSP semantic `@lsp.type.comment` all link to it. The special
      -- comment kinds (@comment.todo/.note/.warning/.error) keep their own
      -- badge colours.
      custom_highlights = function(colors)
        return {
          Comment = { fg = colors.green, style = { "italic" } },
        }
      end,
      integrations = {
        cmp = true,
        gitsigns = true,
        native_lsp = {
          enabled = true,
        },
        treesitter = true,
        which_key = true,
        telescope = true,
        neotree = true,
        noice = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- Not "catppuccin": Neovim 0.12 bundles its own colors/catppuccin.vim in
      -- $VIMRUNTIME, which shadows the plugin's compiled theme, silently
      -- discarding every option above (custom_highlights, integrations, ...).
      -- The flavour-suffixed name only exists in the plugin.
      colorscheme = "catppuccin-mocha",
    },
  },
}

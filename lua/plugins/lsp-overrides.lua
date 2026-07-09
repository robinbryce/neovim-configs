-- LSP defaults retained after removing the broken lsp-modern-mason override.
return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = {
      enabled = false,
    },
  },
}

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      gopls = {
        settings = {
          gopls = {
            buildFlags = { "-tags=unit,integration,e2e" },
          },
        },
      },
    },
  },
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          mason = true,
          settings = {
            gopls = {
              buildFlags = { "-tags=unit,integration,e2e,azurite" },
            },
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "gopls",
        "goimports",
        "gofumpt",
        "delve",
      },
    },
  },
}

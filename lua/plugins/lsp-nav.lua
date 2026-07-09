-- Peek and browse LSP locations via FzfLua (always show picker + preview).
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ["*"] = {
        keys = {
          {
            "gpd",
            "<cmd>FzfLua lsp_definitions jump1=false ignore_current_line=true<cr>",
            desc = "Peek Definition",
            has = "definition",
          },
          {
            "gpi",
            "<cmd>FzfLua lsp_implementations jump1=false ignore_current_line=true<cr>",
            desc = "Peek Implementation",
            has = "implementation",
          },
          {
            "gpr",
            "<cmd>FzfLua lsp_references jump1=false ignore_current_line=true<cr>",
            desc = "Browse References",
            nowait = true,
          },
        },
      },
    },
  },
}

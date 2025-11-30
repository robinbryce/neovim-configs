return {
  "saghen/blink.cmp",
  dependencies = {
    "Kaiser-Yang/blink-cmp-avante",
    -- Snippet engine + community snippets (recommended)
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",
  },
  opts = {
    -- Tell blink to drive LuaSnip via the new snippets layer
    snippets = { preset = "luasnip" },

    sources = {
      -- Use "snippets" instead of the removed "luasnip" source
      default = { "avante", "lsp", "path", "snippets", "buffer" },

      providers = {
        avante = {
          module = "blink-cmp-avante",
          name = "Avante",
          opts = {
            -- options for blink-cmp-avante
          },
        },
      },
    },
  },
}

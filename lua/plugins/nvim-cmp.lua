-- ~/.config/nvim/lua/plugins/cmp.lua
return {
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    local cmp = require("cmp")

    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      -- Use <Tab> to confirm Copilot suggestions or general completions
      ["<Tab>"] = cmp.mapping.confirm({ select = true }),

      -- Use <CR> to insert newline when no completion is active
      ["<CR>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.abort() -- cancel the completion menu
        end
        fallback() -- fall back to newline
      end, { "i", "s" }),

      -- <Esc> cancels completion as well
      ["<Esc>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.abort()
        else
          fallback()
        end
      end, { "i", "s" }),
    })
  end,
}

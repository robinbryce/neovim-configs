-- ~/.config/nvim/lua/plugins/cmp.lua
return {
  "hrsh7th/nvim-cmp",
  name = "cmp",
  opts = function(_, opts)
    local cmp = require("cmp")

    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      -- Use <Tab> to confirm Copilot suggestions or general completions
      -- ["<Tab>"] = cmp.mapping.confirm({ select = true }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() and cmp.get_selected_entry() then
          cmp.confirm({ select = false }) -- confirm only selected
        else
          fallback() -- normal Tab behavior
        end
      end, { "i", "s" }),

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

    -- Optional: use filetype-specific sources and tweaks
    opts.sources = cmp.config.sources(opts.sources)

    --- -- Add filetype-specific workaround for Solidity (disable auto-commit on punctuation)
    --- vim.api.nvim_create_autocmd("FileType", {
    ---   pattern = "solidity",
    ---   callback = function()
    ---     require("cmp").setup.buffer({
    ---       mapping = {
    ---         ["<CR>"] = cmp.mapping(function(fallback)
    ---           if cmp.visible() and cmp.get_selected_entry() then
    ---             cmp.confirm({ select = false })
    ---           else
    ---             fallback()
    ---           end
    ---         end, { "i", "s" }),
    ---       },
    ---     })
    ---   end,
    --- })
  end,
}

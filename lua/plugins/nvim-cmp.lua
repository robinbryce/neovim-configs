-- ~/.config/nvim/lua/plugins/cmp.lua
return {
  "hrsh7th/nvim-cmp",
  name = "cmp",
  opts = function(_, opts)
    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end

    local cmp = require("cmp")

    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      -- https://www.lazyvim.org/configuration/recipes#supertab
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          -- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
          -- cmp.select_next_item() -- supertab default
          cmp.confirm({ select = true }) -- VS Code behaviour
        elseif vim.snippet.active({ direction = 1 }) then
          vim.schedule(function()
            vim.snippet.jump(1)
          end)
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif vim.snippet.active({ direction = -1 }) then
          vim.schedule(function()
            vim.snippet.jump(-1)
          end)
        else
          fallback()
        end
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

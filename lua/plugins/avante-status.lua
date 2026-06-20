return {
  {
    -- Status helpers and auto-provider chooser for Avante
    "takeshiD/avante-status.nvim",
    lazy = true,
    cond = function()
      return not vim.g.vscode and vim.g.avante_integration_enabled == true
    end,
  },
  {
    -- Show the active Avante provider/model in lualine (if present)
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      if vim.g.avante_integration_enabled ~= true then
        return opts
      end

      local ok, avante_lualine = pcall(require, "avante-status.lualine")
      if not ok then
        return opts
      end

      opts.sections = opts.sections or {}
      opts.sections.lualine_c = opts.sections.lualine_c or {}

      -- Add Avante chat status component to the main statusline center section
      table.insert(opts.sections.lualine_c, avante_lualine.chat_component)

      return opts
    end,
  },
}
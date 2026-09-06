-- Lualine segment showing which AI account / Claude subscription this Neovim
-- session is bound to, from `claude auth status` (see config/account.lua):
--   AI·personal·max   logged in, identity matches           (normal colour)
--   AI·work·…         probe still running
--   AI·work·LOGIN!    not logged in to that config dir      (red)
--   AI·work≠id!       logged-in email is not a work identity (red)
--   AI·personal·apiKey!  CLI would bill an API key           (red)
-- Click it (or :AiAccount) to re-probe. Switch with :AiAccount work|personal.
return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      local function color_for(level)
        local hl = ({ ok = "Special", error = "DiagnosticError", pending = "Comment" })[level] or "Special"
        if package.loaded["snacks"] and Snacks.util and Snacks.util.color then
          return { fg = Snacks.util.color(hl) }
        end
        return hl
      end

      table.insert(opts.sections.lualine_x, 1, {
        function()
          return require("config.account").status_text()
        end,
        color = function()
          return color_for(require("config.account").status_level())
        end,
        on_click = function()
          vim.cmd("AiAccount")
        end,
      })
      return opts
    end,
  },
}

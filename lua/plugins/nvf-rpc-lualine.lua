return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_y = opts.sections.lualine_y or {}

      table.insert(opts.sections.lualine_y, {
        function()
          local st = vim.g.nvf_rpc_state
          local path = vim.g.nvf_rpc_path or ""
          local base = path ~= "" and vim.fn.fnamemodify(path, ":t") or ""
          if #base > 22 then
            base = base:sub(1, 19) .. "…"
          end
          if st == "listening" then
            return base ~= "" and ("RPC·" .. base) or "RPC·listen"
          elseif st == "follower" then
            return "RPC·peer"
          elseif st == "error" then
            return "RPC·!"
          end
          return ""
        end,
        cond = function()
          local st = vim.g.nvf_rpc_state
          return st == "listening" or st == "follower" or st == "error"
        end,
      })

      return opts
    end,
  },
}

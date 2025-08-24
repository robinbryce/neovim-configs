return {
  {
    "nvim-lua/plenary.nvim", -- dummy plugin to hook into LazyVim plugin system
    keys = {
      {
        "<leader>rs", -- r for robin, s for scrolloff
        function()
          if vim.o.scrolloff == 9999 then
            vim.o.scrolloff = 5
            vim.notify("Scrolloff set to 5", vim.log.levels.INFO)
          else
            vim.o.scrolloff = 9999
            vim.notify("Scrolloff set to 9999", vim.log.levels.INFO)
          end
        end,
        desc = "Toggle Scrolloff 9999",
      },
    },
  },
}

return {
  "alexghergh/nvim-tmux-navigation",

  opts = {
      disable_when_zoomed = true -- defaults to false
  },

  keys = {
    { "<C-h>", "<cmd>NvimTmuxNavigateLeft<cr>", desc = "Navigate Left" },
    { "<C-j>", "<cmd>NvimTmuxNavigateDown<cr>", desc = "Navigate Down" },
    { "<C-k>", "<cmd>NvimTmuxNavigateUp<cr>", desc = "Navigate Up" },
    { "<C-l>", "<cmd>NvimTmuxNavigateRight<cr>", desc = "Navigate Right" },
    { "<C-\\>", "<cmd>NvimTmuxNavigateLastActive<cr>", desc = "Navigate LastActive" },
    { "<C-Space>", "<cmd>NvimTmuxNavigateNext<cr>", desc = "Navigate Next" },
  },
  config = true,
}

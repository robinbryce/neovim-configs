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
    -- Terminal mode: escape terminal input first, then navigate.
    -- This lets <C-h/j/k/l> work from inside agent terminals.
    { "<C-h>", "<C-\\><C-n><cmd>NvimTmuxNavigateLeft<cr>", mode = "t", desc = "Navigate Left" },
    { "<C-j>", "<C-\\><C-n><cmd>NvimTmuxNavigateDown<cr>", mode = "t", desc = "Navigate Down" },
    { "<C-k>", "<C-\\><C-n><cmd>NvimTmuxNavigateUp<cr>", mode = "t", desc = "Navigate Up" },
    { "<C-l>", "<C-\\><C-n><cmd>NvimTmuxNavigateRight<cr>", mode = "t", desc = "Navigate Right" },
  },
  config = true,
}

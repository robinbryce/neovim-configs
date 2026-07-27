local directions = {
  h = { wincmd = "h", herdr = "left", tmux_fn = "NvimTmuxNavigateLeft", desc = "Navigate Left" },
  j = { wincmd = "j", herdr = "down", tmux_fn = "NvimTmuxNavigateDown", desc = "Navigate Down" },
  k = { wincmd = "k", herdr = "up", tmux_fn = "NvimTmuxNavigateUp", desc = "Navigate Up" },
  l = { wincmd = "l", herdr = "right", tmux_fn = "NvimTmuxNavigateRight", desc = "Navigate Right" },
}

-- herdr sets $HERDR_PANE_ID ambiently on every pane, the same way tmux sets
-- $TMUX -- but the nvim-tmux-navigation plugin only ever checks $TMUX, so
-- under herdr it silently falls back to vim-only navigation and never crosses
-- out at a split edge. Handle herdr ourselves: move within vim first, and
-- only hand off to `herdr pane focus` if the window didn't change (i.e. we're
-- at the edge). Falls through to the plugin's own tmux handling otherwise, so
-- behaviour under tmux (or plain vim) is unchanged.
local function navigate(d)
  local pane = vim.env.HERDR_PANE_ID
  if not pane then
    require("nvim-tmux-navigation")[d.tmux_fn]()
    return
  end
  local winnr = vim.fn.winnr()
  pcall(vim.cmd, "wincmd " .. d.wincmd)
  if vim.fn.winnr() ~= winnr then
    return
  end
  vim.fn.system({ "herdr", "pane", "focus", "--direction", d.herdr, "--pane", pane })
end

return {
  "alexghergh/nvim-tmux-navigation",

  opts = {
      disable_when_zoomed = true -- defaults to false
  },

  keys = {
    { "<C-h>", function() navigate(directions.h) end, desc = "Navigate Left" },
    { "<C-j>", function() navigate(directions.j) end, desc = "Navigate Down" },
    { "<C-k>", function() navigate(directions.k) end, desc = "Navigate Up" },
    { "<C-l>", function() navigate(directions.l) end, desc = "Navigate Right" },
    { "<C-\\>", "<cmd>NvimTmuxNavigateLastActive<cr>", desc = "Navigate LastActive" },
    { "<C-Space>", "<cmd>NvimTmuxNavigateNext<cr>", desc = "Navigate Next" },
  },
  config = true,
}

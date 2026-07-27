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
  local from = vim.api.nvim_get_current_win()
  pcall(vim.cmd, "wincmd " .. d.wincmd)
  if vim.api.nvim_get_current_win() ~= from then
    return -- moved to another nvim window; nothing to hand over
  end
  -- Fire and forget: herdr moves the focus itself, and blocking on it would
  -- stall the UI at the split edge.
  vim.system({
    vim.env.HERDR_BIN_PATH or "herdr",
    "pane",
    "focus",
    "--direction",
    d.herdr,
    "--pane",
    pane,
  })
end

-- Scheduled so the stopinsert mode change is processed before wincmd runs,
-- same as the old <C-\><C-n> key-sequence prefix did.
local function navigate_from_terminal(d)
  vim.cmd("stopinsert")
  vim.schedule(function()
    navigate(d)
  end)
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
    -- Terminal mode: escape terminal input first, then navigate.
    -- This lets <C-h/j/k/l> work from inside agent terminals.
    { "<C-h>", function() navigate_from_terminal(directions.h) end, mode = "t", desc = "Navigate Left" },
    { "<C-j>", function() navigate_from_terminal(directions.j) end, mode = "t", desc = "Navigate Down" },
    { "<C-k>", function() navigate_from_terminal(directions.k) end, mode = "t", desc = "Navigate Up" },
    { "<C-l>", function() navigate_from_terminal(directions.l) end, mode = "t", desc = "Navigate Right" },
  },
  config = true,
}

-- Seamless <C-h/j/k/l> between nvim splits and the surrounding multiplexer.
--
--   tmux    -- nvim-tmux-navigation, exactly as before.
--   herdr   -- handled below. herdr exports $HERDR_PANE_ID into every pane. The
--              herdr side (dotfiles bin/herdr-nav.sh, bound to bare
--              ctrl+h/j/k/l) forwards the chord into this pane whenever nvim is
--              the foreground process; we move within nvim and, when already at
--              the edge window, call back out with `herdr pane focus`.
--   neither -- plain wincmd, via nvim-tmux-navigation's own fallback.
--
-- The herdr branch is entered only when $HERDR_PANE_ID is set, so the tmux path
-- is unchanged.

local tmux_cmd = { h = "Left", j = "Down", k = "Up", l = "Right" }
local herdr_dir = { h = "left", j = "down", k = "up", l = "right" }

local function navigate(key)
  if not vim.env.HERDR_PANE_ID then
    vim.cmd("NvimTmuxNavigate" .. tmux_cmd[key])
    return
  end

  local from = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(key)
  if vim.api.nvim_get_current_win() ~= from then
    return -- moved to another nvim window; nothing to hand over
  end

  -- Already at the edge: cross into the neighbouring herdr pane. Fire and
  -- forget, herdr moves the focus itself.
  vim.system({
    vim.env.HERDR_BIN_PATH or "herdr",
    "pane",
    "focus",
    "--direction",
    herdr_dir[key],
    "--pane",
    vim.env.HERDR_PANE_ID,
  })
end

-- Terminal mode: leave terminal input before moving, same as the old
-- <C-\><C-n> prefix did. Scheduled so the mode change lands before wincmd.
local function navigate_term(key)
  vim.cmd("stopinsert")
  vim.schedule(function()
    navigate(key)
  end)
end

return {
  "alexghergh/nvim-tmux-navigation",

  opts = {
      disable_when_zoomed = true -- defaults to false
  },

  keys = {
    { "<C-h>", function() navigate("h") end, desc = "Navigate Left" },
    { "<C-j>", function() navigate("j") end, desc = "Navigate Down" },
    { "<C-k>", function() navigate("k") end, desc = "Navigate Up" },
    { "<C-l>", function() navigate("l") end, desc = "Navigate Right" },
    { "<C-\\>", "<cmd>NvimTmuxNavigateLastActive<cr>", desc = "Navigate LastActive" },
    { "<C-Space>", "<cmd>NvimTmuxNavigateNext<cr>", desc = "Navigate Next" },
    -- Terminal mode: escape terminal input first, then navigate.
    -- This lets <C-h/j/k/l> work from inside agent terminals.
    { "<C-h>", function() navigate_term("h") end, mode = "t", desc = "Navigate Left" },
    { "<C-j>", function() navigate_term("j") end, mode = "t", desc = "Navigate Down" },
    { "<C-k>", function() navigate_term("k") end, mode = "t", desc = "Navigate Up" },
    { "<C-l>", function() navigate_term("l") end, mode = "t", desc = "Navigate Right" },
  },
  config = true,
}

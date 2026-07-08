-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Cursor Agent split (and any vertical split): widen/narrow for reading plans. Use from normal mode
-- (in the agent terminal: Ctrl-\\ Ctrl-N first).
vim.keymap.set("n", "<leader>cw", function()
  local w = vim.api.nvim_win_get_width(0)
  -- Snap between 50 and 100 columns; threshold sits between the two targets.
  if w >= 75 then
    vim.cmd("vertical resize 50")
  else
    vim.cmd("vertical resize 100")
  end
end, { desc = "Toggle split width 50/100 cols (e.g. Cursor Agent)" })

-- Use WARN so noice shows these in the split view (INFO goes to mini and can be invisible).
vim.keymap.set("n", "<leader>ic", function()
  local account = vim.g.cursor_account or "?"
  local cursor_on = vim.g.cursor_agent_integration_enabled == true
  local avante_on = vim.g.avante_integration_enabled == true
  local lines = {
    "Account: " .. account,
    "Cursor agent: " .. (cursor_on and "on" or "off"),
    "Avante: " .. (avante_on and "on" or "off"),
  }
  if not cursor_on and vim.g.cursor_agent_integration_reason then
    table.insert(lines, "  (" .. vim.g.cursor_agent_integration_reason .. ")")
  end
  if not avante_on and vim.g.avante_integration_reason then
    table.insert(lines, "  (" .. vim.g.avante_integration_reason .. ")")
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN, { title = "Agent integrations" })
end, { desc = "[I]nfo: agent integrations (account + Avante/Cursor)" })

-- Avante diagnostic: show if Claude API key is set and current provider (for <leader>ae hang debugging).
vim.keymap.set("n", "<leader>ia", function()
  local key = vim.env.ANTHROPIC_API_KEY or vim.env.AVANTE_ANTHROPIC_API_KEY or ""
  local key_ok = key ~= "" and #key > 10
  local provider = "?"
  pcall(function()
    local cfg = require("avante.config")
    provider = cfg.provider or "?"
  end)
  vim.notify(
    string.format("Avante: provider=%s, ANTHROPIC_API_KEY=%s", provider, key_ok and "set" or "NOT SET"),
    vim.log.levels.WARN,
    { title = "Avante" }
  )
end, { desc = "[I]nfo: Avante (API key + provider)" })

vim.keymap.set("n", "<leader>is", function()
  local path = vim.g.nvf_rpc_path or "?"
  local st = vim.g.nvf_rpc_state or "?"
  local owned = vim.g.nvf_rpc_socket
  local lines = {
    "State: " .. st,
    "Canonical path: " .. path,
    "This instance listens: " .. (owned and owned ~= "" and owned or "no (first wins / not bound)"),
    "serverlist(): " .. vim.inspect(vim.fn.serverlist()),
  }
  if st == "follower" then
    table.insert(lines, "Another nvim in this cwd owns the socket; use this path with --server or nvr.")
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN, { title = "nvf-rpc" })
end, { desc = "[I]nfo: project RPC socket (nvf-rpc)" })

-- Avante edit with immediate insert: opens edit UI and focuses input so
-- progress is visible right away (default <leader>ae can feel slow to show).
vim.keymap.set("n", "<leader>aE", function()
  local ok, api = pcall(require, "avante.api")
  if ok and api and api.edit then
    api.edit()
    vim.schedule(function()
      vim.cmd("startinsert")
    end)
  else
    vim.notify("Avante not loaded", vim.log.levels.WARN)
  end
end, { desc = "Avante: edit (focus input)" })

-- Refine visual selection: same edit flow as <leader>ae from normal mode
vim.keymap.set("v", "<leader>ae", function()
  local ok, api = pcall(require, "avante.api")
  if ok and api and api.edit then
    api.edit()
    vim.schedule(function()
      vim.cmd("startinsert")
    end)
  else
    vim.notify("Avante not loaded", vim.log.levels.WARN)
  end
end, { desc = "Avante: edit (visual selection)" })

-- Toggle the gitsigns gutter (signs) on/off. Sits in the <leader>u ("ui")
-- toggle namespace. gitsigns also has toggle_current_line_blame / toggle_deleted
-- / toggle_word_diff if you want to bind those too.
vim.keymap.set("n", "<leader>ug", "<cmd>Gitsigns toggle_signs<cr>", { desc = "Toggle Git Signs" })

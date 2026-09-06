-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- AI keymaps live with their plugin specs: lua/plugins/ai-codecompanion.lua
-- (inline refine, <leader>a*) and lua/plugins/ai-claudecode.lua (Claude Code CLI).

-- Claude Code split (and any vertical split): widen/narrow for reading plans. Use from normal mode
-- (in the agent terminal: Ctrl-\\ Ctrl-N first).
vim.keymap.set("n", "<leader>cw", function()
  local w = vim.api.nvim_win_get_width(0)
  -- Snap between 50 and 100 columns; threshold sits between the two targets.
  if w >= 75 then
    vim.cmd("vertical resize 50")
  else
    vim.cmd("vertical resize 100")
  end
end, { desc = "Toggle split width 50/100 cols (e.g. Claude Code)" })

-- AI integration status: account, Claude login (re-probed), API key source,
-- Claude Code connection. Use WARN so noice shows it in the split view.
vim.keymap.set("n", "<leader>ia", function()
  local account = require("config.account")
  account.reset_key_cache() -- re-probe env/keychain so a newly added key shows up
  account.refresh_auth(function()
    local lines = account.status_lines()

    local ok_cc, claudecode = pcall(require, "claudecode")
    if ok_cc and claudecode.state and claudecode.state.server then
      table.insert(
        lines,
        "Claude Code IDE server: port "
          .. tostring(claudecode.state.port or "?")
          .. ", CLI "
          .. (claudecode.is_claude_connected() and "connected" or "not connected")
      )
    else
      table.insert(lines, "Claude Code IDE server: not started (loads on first <leader>ac)")
    end
    local cc_loaded = package.loaded["codecompanion"] ~= nil
    table.insert(lines, "CodeCompanion: " .. (cc_loaded and "loaded" or "not loaded yet (loads on first <leader>aE)"))

    vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN, { title = "AI integrations" })
  end)
end, { desc = "[I]nfo: AI integrations (account, login, key, Claude Code)" })

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

-- Toggle the gitsigns gutter (signs) on/off. Sits in the <leader>u ("ui")
-- toggle namespace. gitsigns also has toggle_current_line_blame / toggle_deleted
-- / toggle_word_diff if you want to bind those too.
vim.keymap.set("n", "<leader>ug", "<cmd>Gitsigns toggle_signs<cr>", { desc = "Toggle Git Signs" })

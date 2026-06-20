-- Shared launch context: work vs personal by cwd.
-- Used by cursor_account.lua and configure_mcp_location.lua.
-- Evaluated once at require(); restart Neovim to switch.

local M = {}

local cwd = vim.fn.getcwd()
local work_root = vim.fn.expand("~/Dev/justgames")

if cwd:find(work_root, 1, true) == 1 then
  M.account_name = "work"
else
  M.account_name = "personal"
end

M.cwd = cwd
M.work_root = work_root

return M

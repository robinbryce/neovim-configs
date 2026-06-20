-- Select cursor-agent API key based on working directory at startup.
-- Work vs personal is determined by config.cursor_context; restart Neovim to switch.
-- Keychain: cursor-api-key-work / cursor-api-key-personal (generic password service names).

local ctx = require("config.cursor_context")

local service = ctx.account_name == "work" and "cursor-api-key-work" or "cursor-api-key-personal"

local raw = vim.fn.system({ "security", "find-generic-password", "-s", service, "-w" })
local out = type(raw) == "string" and raw:gsub("%s+$", "") or ""

local function looks_like_security_error(s)
  return s:match("^security:") ~= nil or s:lower():match("could not be found") ~= nil
end

vim.g.cursor_account = ctx.account_name
vim.g.cursor_agent_integration_reason = nil

if vim.v.shell_error ~= 0 or out == "" or looks_like_security_error(out) then
  vim.env.CURSOR_API_KEY = nil
  vim.g.cursor_agent_integration_enabled = false
  vim.g.cursor_agent_integration_reason = "missing_cursor_keychain"
else
  vim.env.CURSOR_API_KEY = out
  vim.g.cursor_agent_integration_enabled = true
end

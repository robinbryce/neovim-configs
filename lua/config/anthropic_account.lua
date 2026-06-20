-- Set ANTHROPIC_API_KEY from macOS keychain by work/personal cwd (config.cursor_context).
-- Services mirror cursor-api-key-{work|personal}: anthropic-api-key-work, anthropic-api-key-personal.
-- Restart Neovim after cwd/account change. When no key is found, Avante is not loaded (see plugins).

local ctx = require("config.cursor_context")

local service = ctx.account_name == "work" and "anthropic-api-key-work" or "anthropic-api-key-personal"

local raw = vim.fn.system({ "security", "find-generic-password", "-s", service, "-w" })
local out = type(raw) == "string" and raw:gsub("%s+$", "") or ""

local function looks_like_security_error(s)
  return s:match("^security:") ~= nil or s:lower():match("could not be found") ~= nil
end

vim.g.avante_integration_reason = nil

if vim.v.shell_error ~= 0 or out == "" or looks_like_security_error(out) then
  vim.env.ANTHROPIC_API_KEY = nil
  vim.g.avante_integration_enabled = false
  vim.g.avante_integration_reason = "missing_anthropic_keychain"
else
  vim.env.ANTHROPIC_API_KEY = out
  vim.g.avante_integration_enabled = true
end

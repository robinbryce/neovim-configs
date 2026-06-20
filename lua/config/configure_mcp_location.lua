-- Select MCP config path based on working directory at startup.
-- Uses the same work/personal logic as config.cursor_account (via config.cursor_context).
-- Restart Neovim to switch.
--
-- Sets:
--   vim.g.mcp_config_path   – Cursor-style mcp.json path (~/.cursor/mcp-{work|personal}.json)
--   vim.g.mcphub_config_path – mcphub servers.json path (~/.config/mcphub/servers-{work|personal}.json)

local ctx = require("config.cursor_context")

local cursor_dir = vim.fn.expand("~/.cursor")
local mcphub_dir = vim.fn.expand("~/.config/mcphub")
local account = ctx.account_name

vim.g.mcp_config_path = cursor_dir .. "/mcp-" .. account .. ".json"
vim.g.mcphub_config_path = mcphub_dir .. "/servers-" .. account .. ".json"

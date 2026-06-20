return {
  -- MCP server hub: manages MCP servers for Avante and other AI plugins.
  -- Config path: vim.g.mcphub_config_path (set by config.configure_mcp_location from cwd) or ~/.config/mcphub/servers.json
  "ravitemer/mcphub.nvim",
  cond = function()
    return not vim.g.vscode
  end,
  dependencies = { "nvim-lua/plenary.nvim" },
  build = "npm install -g mcp-hub@latest",
  config = function()
    local config_path = vim.g.mcphub_config_path or vim.fn.expand("~/.config/mcphub/servers.json")
    require("mcphub").setup({
      config = config_path,
    })
  end,
}

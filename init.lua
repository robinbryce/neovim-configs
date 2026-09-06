-- bootstrap lazy.nvim, LazyVim and your plugins

-- global config
vim.opt.autowrite = true -- write file whenever you get taken elsewhere
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

require("config.project_listen") -- deterministic RPC socket; before plugins
require("config.account") -- work/personal AI account: CLAUDE_CONFIG_DIR + lazy API key
require("config.lazy")
require("config.suppress_warnings")
-- global keymap
vim.keymap.set("n", "<leader>o", "<cmd>AerialToggle!<CR>", { desc = "[O]utline (Aerial)" })

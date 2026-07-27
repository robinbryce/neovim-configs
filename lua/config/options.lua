-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- vim.o.mouse = "a"

-- Many project JSON files include comments (tsconfig, wrangler, etc.). Treat .json as
-- jsonc so jsonls validation and treesitter allow comments instead of reporting errors.
vim.filetype.add({
  extension = {
    json = "jsonc",
  },
})
vim.g.enable_notify_logging = false -- set to true temporarily if you need notify.log for diagnostics

-- Native ex/cmdline row must be visible (noice cmdline UI is off; see plugins/noice.lua).
vim.o.cmdheight = 1
vim.o.showcmd = true

-- gopls launches `go` as a subprocess but does not honor GOTOOLCHAIN from the
-- go env config file, so on a machine whose base toolchain is older than a
-- module/go.work `go` directive (e.g. base go1.23.4 vs a go.work requiring
-- 1.24.4) its `go list` fails with "requires go >= X (running go Y)" and gopls
-- reports "no package metadata" — breaking gd, references, and Trouble LSP.
-- Exporting GOTOOLCHAIN=auto as a real env var makes gopls's go auto-switch to
-- the required (cached/downloaded) toolchain. Harmless when the base go is new
-- enough. Respect an explicit override if one is already set.
if not vim.env.GOTOOLCHAIN then
  vim.env.GOTOOLCHAIN = "auto"
end

-- Python provider (pyenv-compatible)
vim.g.python3_host_prog = vim.fn.expand("$HOME/wb/.pyenv/versions/3.11.5/bin/python")

-- set textwidth to 80 columns for `gq`, `gw`, etc.
vim.opt.textwidth = 79
vim.opt.colorcolumn = "80,100"

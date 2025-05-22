-- bootstrap lazy.nvim, LazyVim and your plugins

-- global config
vim.opt.autowrite = true -- write file whenever you get taken elsewhere
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

require("config.lazy")

--- hacks & workarounds

--- known issue with the neotest plugin and how it invokes nvim_create_autocmd
--- suppress all errors like - E5560: nvim_create_autocmd must not be called in a fast event context
--- in the case of neotest, they are completley benign and safely ignored
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  if msg:match("nvim_create_autocmd must not be called in a fast event context") then
    return
  end
  orig_notify(msg, level, opts)
end

-- global keymap
vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>")

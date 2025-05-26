-- Suppress specific benign neotest/nio errors

--- suppress all errors like - E5560: nvim_create_autocmd must not be called in a fast event context
--- in the case of neotest, they are completley benign and safely ignored
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  if msg:match("nvim_create_autocmd must not be called in a fast event context") then
    return
  end
  orig_notify(msg, level, opts)
end

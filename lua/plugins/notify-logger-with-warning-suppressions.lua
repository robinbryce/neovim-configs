return {
  "nvim-lua/plenary.nvim", -- safe dummy dependency
  lazy = false,
  priority = 1000,
  config = function()
    local notify = vim.notify
    local logfile = vim.fn.stdpath("data") .. "/notify.log"
    local f = io.open(logfile, "a")
    if vim.g.enable_notify_logging then
      if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] "), "---- new session ----", "\n")
        f:close()
      end
    end

    vim.notify = function(msg, level, opts)
      if msg:match("nvim_create_autocmd must not be called in a fast event context") then
        return
      end

      if vim.g.enable_notify_logging then
        local f = io.open(logfile, "a")
        if f then
          f:write(os.date("[%Y-%m-%d %H:%M:%S] "), msg, "\n")
          f:close()
        end
      end
      notify(msg, level, opts)
    end
  end,
}

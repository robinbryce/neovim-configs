-- Override noice (from LazyVim) so error/warning notifications stay visible.
-- Without this, <leader>ae (Avante edit) and other vim.notify(..., ERROR) messages
-- disappear too quickly in the mini view.
return {
  "folke/noice.nvim",
  opts = function(_, opts)
    -- Render the command line at the classic bottom position instead of the
    -- floating cmdline_popup, which was not showing the text as you type.
    -- This keeps every other noice feature (messages, LSP docs, notifications).
    opts.cmdline = opts.cmdline or {}
    opts.cmdline.view = "cmdline"

    opts.routes = opts.routes or {}
    -- Route ERROR and WARN notifications to split view so they stay until dismissed.
    table.insert(opts.routes, {
      filter = {
        event = "notify",
        cond = function(message)
          local level = message.level or (message.opts and message.opts.level)
          -- vim.log.levels: ERROR=4, WARN=3, INFO=2, DEBUG=1
          return level and (level >= vim.log.levels.WARN)
        end,
      },
      view = "split",
    })
    return opts
  end,
}

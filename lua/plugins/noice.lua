-- Override noice (from LazyVim): bottom cmdline + persistent WARN/ERROR notifications.
return {
  "folke/noice.nvim",
  opts = function(_, opts)
    -- Floating cmdline_popup was not rendering typed text; use classic bottom line.
    opts.cmdline = opts.cmdline or {}
    opts.cmdline.view = "cmdline"

    opts.routes = opts.routes or {}
    table.insert(opts.routes, {
      filter = {
        event = "notify",
        cond = function(message)
          local level = message.level or (message.opts and message.opts.level)
          return level and (level >= vim.log.levels.WARN)
        end,
      },
      view = "split",
    })
    return opts
  end,
}

-- noice.nvim: keep LSP + vim.notify routing; use native cmdline/messages.
--
-- The cmdline_popup stack (noice + blink cmdline) was not rendering a visible
-- input box here — only blink's completion menu appeared. Native cmdline +
-- messages are reliable; see options.lua (cmdheight) and blink-cmp override.
return {
  "folke/noice.nvim",
  opts = function(_, opts)
    opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, {
      enabled = false,
    })
    opts.messages = vim.tbl_deep_extend("force", opts.messages or {}, {
      enabled = false,
    })
    opts.popupmenu = vim.tbl_deep_extend("force", opts.popupmenu or {}, {
      enabled = false,
    })

    opts.presets = opts.presets or {}
    opts.presets.command_palette = false
    opts.presets.cmdline_output_to_split = false

    opts.routes = opts.routes or {}
    table.insert(opts.routes, {
      filter = {
        event = "notify",
        cond = function(message)
          local level = message.level or (message.opts and message.opts.level)
          return level and level >= vim.log.levels.WARN
        end,
      },
      view = "split",
    })

    return opts
  end,
}

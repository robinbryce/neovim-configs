-- Route markdown-preview.nvim's browser launch (<leader>cp, from LazyVim's
-- lang.markdown extra) through `cmux browser open-split` when Neovim is
-- running inside herdr-in-cmux, so the preview lands in a cmux pane to the
-- right instead of popping a native browser window over everything.
-- <leader>uP toggles back to the OS-default browser (e.g. for a URL you
-- want to keep open outside the cmux workspace).

local function in_cmux_herdr()
  return vim.env.HERDR_ENV == "1" and vim.env.CMUX_WORKSPACE_ID ~= nil and vim.env.CMUX_WORKSPACE_ID ~= ""
end

local function open_system_browser(url)
  vim.system({ "open", url })
end

_G.MkdpOpenBrowserImpl = function(url)
  if vim.g.mkdp_prefer_system_browser or not in_cmux_herdr() then
    open_system_browser(url)
    return
  end
  vim.system(
    { "cmux", "browser", "open-split", url, "--workspace", vim.env.CMUX_WORKSPACE_ID },
    {},
    function(res)
      if res.code ~= 0 then
        vim.schedule(function()
          vim.notify(
            "cmux browser open-split failed, falling back to system browser: " .. vim.trim(res.stderr or ""),
            vim.log.levels.WARN
          )
        end)
        open_system_browser(url)
      end
    end
  )
end

return {
  {
    "iamcco/markdown-preview.nvim",
    init = function()
      -- server.js calls this by name over RPC; it can't resolve `v:lua.*`
      -- funcrefs directly, so wrap the Lua impl in a tiny VimL shim.
      vim.cmd([[
        function! MkdpOpenBrowser(url) abort
          call v:lua.MkdpOpenBrowserImpl(a:url)
        endfunction
      ]])
      vim.g.mkdp_browserfunc = "MkdpOpenBrowser"
    end,
    keys = {
      {
        "<leader>uP",
        function()
          vim.g.mkdp_prefer_system_browser = not vim.g.mkdp_prefer_system_browser
          vim.notify(
            "Markdown preview browser: "
              .. (vim.g.mkdp_prefer_system_browser and "system default" or "cmux split (when in herdr/cmux)"),
            vim.log.levels.INFO
          )
        end,
        desc = "Toggle Markdown Preview Browser (system/cmux)",
      },
    },
  },
}

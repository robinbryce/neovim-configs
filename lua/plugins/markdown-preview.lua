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

-- markdown-preview.nvim renders inside `#page-ctn { max-width: 900px }` (from
-- its page.css) and forces every table to `display:block; width:100%`, so wide
-- tables get squashed and truncated. We can't append CSS to the plugin -- the
-- `g:mkdp_markdown_css` var *replaces* /_static/markdown.css wholesale -- but
-- that swapped file is loaded *after* page.css, so overriding `#page-ctn` here
-- wins on cascade order. We regenerate the served file from the plugin's own
-- current markdown.css on each launch (so it tracks upstream updates) and append
-- our width overrides. Set g:mkdp_page_max_width to a CSS length (e.g. "1400px")
-- to cap the page; default "none" uses the full browser window.
local function mkdp_plugin_dir()
  local ok, cfg = pcall(require, "lazy.core.config")
  if ok and cfg.plugins["markdown-preview.nvim"] then
    return cfg.plugins["markdown-preview.nvim"].dir
  end
  local found = vim.api.nvim_get_runtime_file("app/_static/markdown.css", false)[1]
  return found and vim.fn.fnamemodify(found, ":h:h:h") or nil
end

local function setup_wide_markdown_css()
  local dir = mkdp_plugin_dir()
  if not dir then
    return
  end
  local src = dir .. "/app/_static/markdown.css"
  if vim.fn.filereadable(src) == 0 then
    return
  end
  local lines = vim.fn.readfile(src)
  if vim.tbl_isempty(lines) then
    return
  end

  local max_width = vim.g.mkdp_page_max_width or "none"
  vim.list_extend(lines, {
    "",
    "/* ---- injected by markdown-preview.lua: full-width page + wide tables ---- */",
    "#page-ctn {",
    "  max-width: " .. max_width .. ";", -- was 900px in page.css; this file loads later, so wins
    "  padding: 0 24px;",
    "}",
    ".markdown-body table {",
    "  display: block;",
    "  width: max-content;", -- natural width from content instead of forced 100%
    "  max-width: 100%;", -- clamp to the page; overflow-x scrolls when wider
    "  overflow-x: auto;",
    "}",
  })

  local out = vim.fn.stdpath("cache") .. "/mkdp-wide.css"
  vim.fn.writefile(lines, out)
  vim.g.mkdp_markdown_css = out
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
      setup_wide_markdown_css()
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

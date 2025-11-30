return {
  {
    "neovim/nvim-lspconfig",
    -- We only override the config function; opts still come from LazyVim and local plugins.
    config = function(_, opts)
      local LazyVim = require("lazyvim.util")
      local Snacks = require("snacks")

      -- setup autoformat
      LazyVim.format.register(LazyVim.lsp.formatter())

      -- setup keymaps (preserves LazyVim + your per-server keymaps)
      for server, server_opts in pairs(opts.servers) do
        if type(server_opts) == "table" and server_opts.keys then
          require("lazyvim.plugins.lsp.keymaps").set({ name = server ~= "*" and server or nil }, server_opts.keys)
        end
      end

      -- inlay hints
      -- We disable automatic enabling and rely on the standard LazyVim keybinding
      -- `<leader>uh` (Snacks.toggle.inlay_hints) to toggle them explicitly.
      opts.inlay_hints = opts.inlay_hints or {}
      opts.inlay_hints.enabled = false

      -- folds
      if opts.folds.enabled then
        Snacks.util.lsp.on({ method = "textDocument/foldingRange" }, function()
          if LazyVim.set_default("foldmethod", "expr") then
            LazyVim.set_default("foldexpr", "v:lua.vim.lsp.foldexpr()")
          end
        end)
      end

      -- code lens
      if opts.codelens.enabled and vim.lsp.codelens then
        Snacks.util.lsp.on({ method = "textDocument/codeLens" }, function(buffer)
          vim.lsp.codelens.refresh()
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer = buffer,
            callback = vim.lsp.codelens.refresh,
          })
        end)
      end

      -- diagnostics
      if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
        opts.diagnostics.virtual_text.prefix = function(diagnostic)
          local icons = LazyVim.config.icons.diagnostics
          for d, icon in pairs(icons) do
            if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
              return icon
            end
          end
          return "●"
        end
      end
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      if opts.capabilities then
        LazyVim.deprecate("lsp-config.opts.capabilities", "Use lsp-config.opts.servers['*'].capabilities instead")
        opts.servers["*"] = vim.tbl_deep_extend("force", opts.servers["*"] or {}, {
          capabilities = opts.capabilities,
        })
      end

      if opts.servers["*"] then
        vim.lsp.config("*", opts.servers["*"])
      end

      -- Modern mason-lspconfig integration using get_mappings()
      local have_mason = LazyVim.has("mason-lspconfig.nvim")
      local mason_all = {} ---@type string[]
      if have_mason then
        local ok, mlsp = pcall(require, "mason-lspconfig")
        if ok and type(mlsp.get_mappings) == "function" then
          local map = mlsp.get_mappings()
          if map and map.lspconfig_to_mason then
            mason_all = vim.tbl_keys(map.lspconfig_to_mason)
          end
        end
      end

      local mason_exclude = {} ---@type string[]

      ---@return boolean? exclude automatic setup
      local function configure(server)
        if server == "*" then
          return false
        end
        local sopts = opts.servers[server]
        sopts = sopts == true and {} or (not sopts) and { enabled = false } or sopts --[[@as lazyvim.lsp.Config]]

        if sopts.enabled == false then
          mason_exclude[#mason_exclude + 1] = server
          return
        end

        local use_mason = sopts.mason ~= false and vim.tbl_contains(mason_all, server)
        local setup = opts.setup[server] or opts.setup["*"]
        if setup and setup(server, sopts) then
          mason_exclude[#mason_exclude + 1] = server
        else
          vim.lsp.config(server, sopts) -- configure the server
          if not use_mason then
            vim.lsp.enable(server)
          end
        end
        return use_mason
      end

      local install = vim.tbl_filter(configure, vim.tbl_keys(opts.servers))
      if have_mason then
        require("mason-lspconfig").setup({
          ensure_installed = vim.list_extend(install, LazyVim.opts("mason-lspconfig.nvim").ensure_installed or {}),
          automatic_enable = { exclude = mason_exclude },
        })
      end
    end,
  },
}

-- Secondary AI path (pay-per-token): Claude over the Anthropic API via
-- codecompanion.nvim, for the cases the subscription CLI is a poor fit: a
-- one-shot inline edit with an in-place per-hunk diff, the prompt library, or
-- a chat scratchpad. Billing is against the account's API key, resolved lazily
-- by config/account.lua (project direnv ANTHROPIC_API_KEY, else macOS keychain
-- anthropic-api-key-{work|personal}). Everything else, including the primary
-- <leader>ae refine, goes through ai-claudecode.lua on the subscription.
--
-- Keys (all under <leader>a, "+ai"; visual-mode variants act on the selection):
--   <leader>aE  inline (API): refine selection / buffer, diff applied in place
--   <leader>aa  action palette (prompt library, chat, editor context)
--   <leader>ai  toggle chat sidebar
--   <leader>ad  (v) add selection to the chat buffer
--   <leader>ax  (v) explain selection      <leader>af  (v) fix selection
--   <leader>at  (v) generate unit tests    <leader>al  explain LSP diagnostics
--
-- Inside an inline diff: gv view diff, g1 accept all, g2 accept hunk, g3 reject
-- hunk, g4 cancel, } / { next / previous hunk, q stop the request.
-- Inside the chat buffer: <CR>/<C-s> send, ga change adapter, gm change model,
-- gx clear, gy yank code, gd debug, ? show all keymaps.

local function read_global_instructions()
  local path = vim.fn.stdpath("config") .. "/global-ai-instructions.md"
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local lines = vim.fn.readfile(path)
  if not lines or #lines == 0 then
    return nil
  end
  return table.concat(lines, "\n")
end

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
    cond = function()
      return not vim.g.vscode
    end,
    opts = function()
      local account = require("config.account")

      -- Resolved on first request, not at startup: no keychain prompt or
      -- `security` shell-out until Claude is actually used.
      local function api_key()
        local key, why = account.anthropic_api_key()
        if not key then
          vim.notify(
            "No Anthropic API key for account '"
              .. account.name
              .. "': "
              .. why
              .. '\nAdd it with: security add-generic-password -a "$USER" -s anthropic-api-key-'
              .. account.name
              .. " -w '<key>'  (then <leader>ia to re-check)",
            vim.log.levels.ERROR,
            { title = "CodeCompanion" }
          )
        end
        return key
      end

      return {
        adapters = {
          http = {
            anthropic = function()
              return require("codecompanion.adapters").extend("anthropic", {
                env = { api_key = api_key },
                schema = {
                  -- Current-generation ids; model capabilities (adaptive
                  -- thinking, context management) are read from the Models API.
                  model = { default = "claude-opus-5" },
                },
              })
            end,
          },
          opts = {
            show_presets = false, -- Claude-only stack: hide the other built-in adapters
          },
        },
        interactions = {
          chat = {
            adapter = "anthropic",
            opts = {
              -- Keep CodeCompanion's default prompt and append the cross-repo
              -- engineering defaults previously fed to Avante.
              system_prompt = function(ctx)
                local extra = read_global_instructions()
                if not extra then
                  return ctx.default_system_prompt
                end
                return ctx.default_system_prompt .. "\n\n# Engineering defaults\n\n" .. extra
              end,
            },
          },
          inline = { adapter = "anthropic" },
          cmd = { adapter = "anthropic" },
        },
        display = {
          action_palette = { provider = "snacks" },
          chat = {
            window = { layout = "vertical", width = 0.4 },
            show_settings = false,
          },
          diff = { enabled = true },
        },
        opts = {
          log_level = "ERROR",
        },
      }
    end,
    -- stylua: ignore
    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      { "<leader>aE", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "AI: inline refine via API (pay-per-token)" },
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI: actions palette" },
      { "<leader>ai", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "AI: toggle chat" },
      { "<leader>ad", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "AI: add selection to chat" },
      { "<leader>ax", "<cmd>CodeCompanion /explain<cr>", mode = "v", desc = "AI: explain selection" },
      { "<leader>af", "<cmd>CodeCompanion /fix<cr>", mode = "v", desc = "AI: fix selection" },
      { "<leader>at", "<cmd>CodeCompanion /tests<cr>", mode = "v", desc = "AI: unit tests for selection" },
      { "<leader>al", "<cmd>CodeCompanion /lsp<cr>", mode = { "n", "v" }, desc = "AI: explain LSP diagnostics" },
    },
  },
  {
    -- Render the chat buffer as markdown (LazyVim's markdown extra provides the plugin).
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,
    opts = function(_, opts)
      opts.file_types = opts.file_types or { "markdown" }
      if not vim.tbl_contains(opts.file_types, "codecompanion") then
        table.insert(opts.file_types, "codecompanion")
      end
    end,
    ft = { "markdown", "codecompanion" },
  },
}

return {
  -- Claude-first AI agent for Neovim. Copilot is intentionally not used
  -- in this config; Avante + Claude is the primary AI experience here.
  "yetone/avante.nvim",
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- ⚠️ must add this setting! ! !
  build = "make",
  -- Load on VimEnter so <leader>ae (edit) shows UI immediately instead of
  -- waiting for first use (VeryLazy delays until first keymap/command).
  event = "VimEnter",
  -- Skip when no Anthropic key (config/anthropic_account.lua); skip in VSCode/Cursor.
  cond = function()
    return not vim.g.vscode and vim.g.avante_integration_enabled == true
  end,
  version = false, -- Never set this value to "*"! Never!
  ---@module 'avante'
  ---@type avante.Config
  opts = {
    input = { provider = "dressing" },
    -- Per-project instructions (relative to project root)
    instructions_file = "avante.md",
    -- Cross-repo defaults: stdpath("config")/global-ai-instructions.md (this repo root when config is symlinked here)
    system_prompt = function()
      local path = vim.fn.stdpath("config") .. "/global-ai-instructions.md"
      if vim.fn.filereadable(path) ~= 1 then
        return nil
      end
      local lines = vim.fn.readfile(path)
      if not lines or #lines == 0 then
        return nil
      end
      return table.concat(lines, "\n")
    end,
    -- Agentic mode enables tool-use: the LLM can call functions to
    -- gather context, edit files, and run commands iteratively.
    -- If <leader>ae + Ctrl-S spins forever: 1) :messages for API errors,
    -- 2) <leader>ia to confirm ANTHROPIC_API_KEY is set in the env that started Neovim,
    -- 3) try mode = "chat" temporarily to see if agentic/MCP is blocking.
    mode = "agentic",
    -- Claude for edit so <leader>ae shows results; Cursor ACP edit often deletes
    -- selection and never returns. Use the provider picker in Avante UI to use Cursor for chat.
    provider = "claude",
    auto_suggestions_provider = "claude",
    providers = {
      claude = {
        auth_type = "api",
        endpoint = "https://api.anthropic.com",
        model = "claude-sonnet-4-20250514",
        api_key_name = "ANTHROPIC_API_KEY", -- Set by config/anthropic_account.lua when integration is enabled.
        timeout = 60000, -- ms (plugin may not pass this to HTTP yet; if edit hangs, see below).
        extra_request_body = {
          temperature = 0.75,
          max_tokens = 20480,
        },
      },
      -- You can add more providers here in the future (openai, openrouter, etc.)
    },
    -- Cursor Agent inline via ACP: use in Avante chat/edit by setting
    -- provider = "cursor" (or switch in UI). Requires `agent` (Cursor CLI) on PATH.
    -- Authentication: CURSOR_API_KEY is set by config/cursor_account.lua at
    -- startup (keychain by cwd: work vs personal). Passing --api-key when set
    -- pre-authenticates the agent so it does not prompt for interactive login.
    acp_providers = {
      cursor = {
        command = "agent",
        args = (function()
          local key = vim.env.CURSOR_API_KEY or ""
          if key ~= "" then
            return { "--api-key", key, "acp" }
          end
          return { "acp" }
        end)(),
        auth_method = "cursor_login",
        env = {
          HOME = os.getenv("HOME"),
          PATH = os.getenv("PATH"),
          CURSOR_API_KEY = vim.env.CURSOR_API_KEY or "",
        },
      },
    },
    -- So edit results are applied in-place and you're taken to the result.
    -- If with Cursor provider you still get deleted selection and no result,
    -- ACP edit can be unreliable; switch to Claude in the UI or set provider = "claude".
    behaviour = {
      auto_apply_diff_after_generation = true,
      jump_result_buffer_on_finish = true,
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "nvim-mini/mini.pick", -- for file_selector provider mini.pick
    "ibhagwan/fzf-lua", -- for file_selector provider fzf
    "stevearc/dressing.nvim", -- for input provider dressing
    "folke/snacks.nvim", -- for input provider snacks
    "nvim-tree/nvim-web-devicons", -- or nvim-mini/mini.icons
    "ravitemer/mcphub.nvim", -- MCP server hub for Avante
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}

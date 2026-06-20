return {
  -- cursor-agent CLI integration: terminal, MCP bridge, diff view,
  -- selection tracking, and agent/ask/plan/resume modes.
  -- Ported from claude-code.nvim for Cursor Agent compatibility.
  "aug6th/cursoragent.nvim",
  -- Without cmd=, this plugin only loads on keys; :PlanNew / doc-workflow calling
  -- :CursorAgentPlan would hit a missing command. Stub commands load the plugin first.
  cmd = {
    "CursorAgent",
    "CursorAgentAsk",
    "CursorAgentPlan",
    "CursorAgentResume",
    "CursorAgentPrompt",
    "CursorAgentSelection",
    "CursorAgentBuffer",
  },
  cond = function()
    return not vim.g.vscode and vim.g.cursor_agent_integration_enabled == true
  end,
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("cursoragent").setup({
      -- Match `cursor-agent --help` on PATH (often the `agent` binary; see docs/cursor-agent-capabilities.md)
      terminal_cmd = "agent",
      terminal = {
        split_side = "right",
        split_width_percentage = 0.5,
        provider = "native",
        auto_close = false, -- keep terminal alive to resume
        git_repo_cwd = true,
      },
      auto_start = false,
      track_selection = true, -- send visual selections as context
      -- command_variants create CursorAgent<Name> commands that
      -- pass the given args to cursor-agent CLI
      command_variants = {
        ask = "--mode ask",
        plan = "--mode plan",
        resume = "--continue",
      },
    })
  end,
  keys = {
    -- <leader>C = Cursor Agent group (uppercase to avoid <leader>c LSP clash)
    {
      "<leader>CC",
      function()
        require("cursoragent").toggle()
      end,
      desc = "Cursor Agent: toggle",
    },
    { "<leader>Ca", "<cmd>CursorAgentAsk<CR>", desc = "Cursor Agent: ask" },
    { "<leader>Cp", "<cmd>CursorAgentPlan<CR>", desc = "Cursor Agent: plan" },
    { "<leader>Cr", "<cmd>CursorAgentResume<CR>", desc = "Cursor Agent: resume" },
    -- Capture selection in a callback while still in visual mode; <cmd> would exit visual
    -- before the command runs and context.get_visual_selection() can see no selection.
    {
      "<leader>Cs",
      function()
        local context = require("cursoragent.context")
        local util = require("cursoragent.util")
        local ca = require("cursoragent")
        local sel = context.get_visual_selection()
        if not sel or sel == "" then
          util.notify("No visual selection", vim.log.levels.WARN)
          return
        end
        local tmp = util.write_tempfile(sel, ".txt")
        ca.ask({ file = tmp, title = "Selection → Cursor Agent" })
      end,
      mode = "v", -- visual (char); "V" is invalid in keymap.set, linewise/block still work via same binding in practice
      desc = "Cursor Agent: send selection",
    },
  },
}

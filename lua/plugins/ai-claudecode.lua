-- Primary AI path (subscription): the Claude Code CLI via coder/claudecode.nvim.
--
-- claudecode.nvim hosts the same WebSocket IDE protocol the official VS Code /
-- JetBrains extensions use: Neovim writes a lock file under
-- $CLAUDE_CONFIG_DIR/ide, the `claude` CLI running in the split connects back,
-- selections/buffers are shared as @-mentions, and every edit Claude proposes
-- opens as a native Neovim diff you accept or reject. The CLI owns the agent
-- loop, permissions, and auth (subscription login in ~/.claude-{personal,
-- justgames}, chosen by config/account.lua; `:AiAccount` switches).
--
-- Keys (under <leader>a, "+ai"):
--   <leader>ae  (v) refine selection: sends it as context, asks for an
--               instruction, submits; edits come back as diffs
--   <leader>ae  (n) same for the whole current file
--   <leader>ac  toggle Claude Code          <leader>ao  focus Claude Code
--   <leader>aC  continue last session       <leader>ar  resume (pick session)
--   <leader>ap  new session in plan mode (--permission-mode plan)
--   <leader>as  (v) send selection only; in neo-tree/oil: add file
--   <leader>ab  add current buffer
--   <leader>ay  accept diff                 <leader>an  deny diff
--   <leader>am  select model
--
-- In a diff window :w also accepts and :q rejects. <C-h/j/k/l> leave the
-- terminal (tmux-navigator maps them in terminal mode).
--
-- Launch keys first run config.account.check_login(), which refuses with a
-- clear message when the config dir has no login or the wrong identity.
--
-- API-key billing inside the CLI is opt-in: set vim.g.claudecode_use_api_key
-- = true before the plugin loads to stop scripts/claude-nvim.sh stripping
-- ANTHROPIC_API_KEY from the CLI's environment.

local function guarded(cmd)
  return function()
    if require("config.account").check_login() then
      vim.cmd(cmd)
    end
  end
end

---Make sure a CLI is running and has completed the IDE handshake, launching
---it if needed. Polls every 250ms for up to `max_ms` (cold start plus any
---first-run prompts such as folder trust, which need the terminal focused).
---@param cb fun(ok: boolean)
local function ensure_connected(cb)
  local cc = require("claudecode")
  if cc.is_claude_connected() then
    return cb(true)
  end
  local terminal = require("claudecode.terminal")
  terminal.open() -- launches (or shows) the CLI and focuses it so prompts can be answered
  vim.notify("Starting Claude Code…", vim.log.levels.INFO, { title = "AI" })
  local max_ms = 45000
  local waited = 0
  local timer = vim.uv.new_timer()
  timer:start(250, 250, function()
    waited = waited + 250
    if cc.is_claude_connected() then
      timer:stop()
      timer:close()
      vim.schedule(function()
        cb(true)
      end)
    elseif waited >= max_ms then
      timer:stop()
      timer:close()
      vim.schedule(function()
        cb(false)
      end)
    end
  end)
end

---Subscription-primary "highlight and refine": share the selection (visual) or
---the whole file (normal) as an @-mention, then ask for the instruction.
---
---Order matters: the range is captured and visual mode exited *before* the
---input prompt (the plugin's own :ClaudeCodeSend feeds a pending <Esc> that
---would otherwise land in the prompt), and the mention is only sent once the
---CLI has connected (the plugin drops queued mentions older than
---queue_timeout, which a cold start easily exceeds).
local function refine()
  local account = require("config.account")
  if not account.check_login() then
    return
  end
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then
    vim.notify("Refine needs a file buffer", vim.log.levels.WARN, { title = "AI" })
    return
  end
  local mode = vim.api.nvim_get_mode().mode
  local visual = mode:match("^[vV\22]") ~= nil
  local line1, line2
  if visual then
    line1, line2 = vim.fn.line("v"), vim.fn.line(".")
    if line1 > line2 then
      line1, line2 = line2, line1
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  end
  if vim.bo.modified then
    vim.cmd("silent! write")
  end

  local what = visual and string.format("selection L%d-%d", line1, line2) or "file"
  vim.ui.input({ prompt = "Refine " .. what .. ": " }, function(instruction)
    instruction = instruction and vim.trim(instruction) or ""
    if instruction == "" then
      return
    end
    ensure_connected(function(ok)
      if not ok then
        vim.fn.setreg("+", instruction)
        vim.notify(
          "Claude Code did not connect (answer any prompt in its terminal, then retry); instruction copied to + register",
          vim.log.levels.WARN,
          { title = "AI" }
        )
        return
      end
      local cc = require("claudecode")
      local terminal = require("claudecode.terminal")
      -- Use the path and range captured above: the terminal may hold focus now,
      -- so anything reading "the current buffer" would pick the wrong one.
      local sent
      if visual then
        sent = cc.send_at_mention(file, line1 - 1, line2 - 1, "refine") -- 0-indexed lines
      else
        sent = cc.send_at_mention(file, nil, nil, "refine")
      end
      if not sent then
        vim.fn.setreg("+", instruction)
        vim.notify(
          "Could not send context to Claude Code; instruction copied to + register",
          vim.log.levels.WARN,
          { title = "AI" }
        )
        return
      end
      -- The mention is broadcast on a ~50ms debounce and the CLI inserts it into
      -- its prompt on receipt; give that a moment, then append the instruction.
      -- Enter goes as a *separate* write a beat later: the CLI treats one fast
      -- chunk as a paste and drops a CR that arrives inside it.
      vim.defer_fn(function()
        if not terminal.send_to_terminal(instruction, { submit = false, focus = true }) then
          vim.fn.setreg("+", instruction)
          return
        end
        vim.defer_fn(function()
          local bufnr = terminal.get_active_terminal_bufnr()
          local chan = bufnr and (vim.b[bufnr].terminal_job_id or vim.bo[bufnr].channel)
          if chan and chan ~= 0 then
            vim.fn.chansend(chan, "\r")
          end
        end, 250)
      end, 800)
    end)
  end)
end

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  cond = function()
    return not vim.g.vscode
  end,
  cmd = {
    "ClaudeCode",
    "ClaudeCodeFocus",
    "ClaudeCodeOpen",
    "ClaudeCodeClose",
    "ClaudeCodeSend",
    "ClaudeCodeSendText",
    "ClaudeCodeAdd",
    "ClaudeCodeTreeAdd",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
    "ClaudeCodeCloseAllDiffs",
    "ClaudeCodeSelectModel",
    "ClaudeCodeStatus",
    "ClaudeCodeStart",
    "ClaudeCodeStop",
  },
  opts = {
    terminal_cmd = vim.fn.stdpath("config") .. "/scripts/claude-nvim.sh",
    env = { CLAUDECODE_NVIM_USE_API_KEY = vim.g.claudecode_use_api_key and "1" or "0" },
    log_level = "warn",
    track_selection = true,
    focus_after_send = false,
    -- A cold CLI start (plus any first-run prompt) takes longer than the 10s /
    -- 5s defaults, after which the plugin silently drops queued @-mentions.
    connection_timeout = 45000,
    queue_timeout = 45000,
    terminal = {
      provider = "snacks",
      split_side = "right",
      split_width_percentage = 0.45, -- <leader>cw snaps any vsplit between 50/100 cols
      diff_split_width_percentage = 0.3, -- give diffs more room while one is open
      auto_close = false, -- keep the CLI alive to --continue
      show_native_term_exit_tip = false,
      git_repo_cwd = true,
    },
    diff_opts = {
      layout = "vertical",
      open_in_new_tab = false,
      keep_terminal_focus = false,
    },
  },
  -- stylua: ignore
  keys = {
    { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
    { "<leader>ae", refine, mode = { "n", "v" }, desc = "AI: refine selection/file with Claude Code" },
    { "<leader>ac", guarded("ClaudeCode"), desc = "Claude Code: toggle" },
    { "<leader>ao", guarded("ClaudeCodeFocus"), desc = "Claude Code: focus" },
    { "<leader>aC", guarded("ClaudeCode --continue"), desc = "Claude Code: continue last session" },
    { "<leader>ar", guarded("ClaudeCode --resume"), desc = "Claude Code: resume (pick session)" },
    { "<leader>ap", guarded("ClaudeCode --permission-mode plan"), desc = "Claude Code: new session in plan mode" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude Code: add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude Code: send selection" },
    { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", desc = "Claude Code: add file", ft = { "NvimTree", "neo-tree", "oil" } },
    { "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude Code: accept diff" },
    { "<leader>an", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude Code: deny diff" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Claude Code: select model" },
  },
}

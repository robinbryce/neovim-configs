-- Work vs personal account context for AI tooling.
--
-- Selection order (first match wins):
--   1. NVF_AI_ACCOUNT=work|personal in the environment (explicit launch override)
--   2. Neovim *startup* cwd under ~/Dev/justgames  => work
--   3. DOTFILES_ROLE=work-dev (from ~/.config/dotfiles/local.sh) => work
--   4. personal
-- Rule 2 is the nvf convention from ~/dotfiles/README.md; rule 3 makes the same
-- config default to work on a work laptop. `:AiAccount work|personal` switches
-- at runtime; `<leader>ia` shows what is active and who is logged in.
--
-- Two credential paths, deliberately kept separate:
--
--   * Claude Code CLI (subscription, the primary path) -> `CLAUDE_CONFIG_DIR`
--     exported for this Neovim session to ~/.claude-{justgames|personal},
--     mirroring the claude()/claude-personal/claude-justgames shell wrappers in
--     ~/dotfiles/profiles/common/agents.sh. `claude auth status --json` run
--     against that dir is the source of truth for who is logged in; it is
--     probed asynchronously at startup and after every switch, cached in
--     `M.auth`, shown in lualine and by <leader>ia, and checked before Claude
--     is launched.
--
--   * Anthropic API key (pay-per-token, secondary) -> `M.anthropic_api_key()`;
--     used only by codecompanion's HTTP adapter. Resolved lazily on first use,
--     cached, and NEVER exported into vim.env, so child processes (notably the
--     `claude` CLI) do not silently switch from subscription to API billing.
--     Sources: ANTHROPIC_API_KEY already in the environment (project direnv
--     .env.secret), then the macOS keychain generic password
--     `anthropic-api-key-{work|personal}` (mirrors the old cursor-api-key-* scheme).

local M = {}

M.cwd = vim.fn.getcwd()
M.work_root = vim.fn.expand("~/Dev/justgames")

-- Claude Code config dirs: same mapping as ~/dotfiles/profiles/common/agents.sh.
M.dirs = {
  work = vim.fn.expand("~/.claude-justgames"),
  personal = vim.fn.expand("~/.claude-personal"),
}

-- Which login identity each account is expected to carry. Matched (Lua
-- patterns) against the email reported by `claude auth status`; a mismatch
-- turns the statusline segment red. Override with vim.g.ai_account_email_patterns.
M.email_patterns = vim.g.ai_account_email_patterns
  or {
    personal = { "gmail%.com$" },
    work = { "justgames", "sentientdogs" },
  }

local key_cache = {}

---@return "work"|"personal"
local function detect()
  local override = vim.env.NVF_AI_ACCOUNT
  if override == "work" or override == "personal" then
    return override
  end
  if M.cwd:find(M.work_root, 1, true) == 1 then
    return "work"
  end
  if vim.env.DOTFILES_ROLE == "work-dev" then
    return "work"
  end
  return "personal"
end

--- Auth status as reported by the CLI for the active config dir.
---@class AiAuthStatus
---@field checked boolean      a probe has completed
---@field loggedIn boolean|nil
---@field authMethod string|nil  "claude.ai" | "apiKey" | ...
---@field email string|nil
---@field orgName string|nil
---@field subscriptionType string|nil  "max" | "pro" | ...
---@field error string|nil
M.auth = { checked = false }

---Apply an account: export CLAUDE_CONFIG_DIR, reset caches. Does not restart
---anything; see M.switch for the runtime path.
---@param name "work"|"personal"
local function apply(name)
  M.name = name
  M.claude_config_dir = M.dirs[name]
  vim.env.CLAUDE_CONFIG_DIR = M.claude_config_dir
  vim.g.ai_account = name
  key_cache = { resolved = false }
  M.auth = { checked = false }
end

-- Honour a dir pinned by the launching shell (e.g. started under the
-- claude-justgames wrapper env) only when it maps to a known account.
local function account_for_dir(dir)
  for name, d in pairs(M.dirs) do
    if dir == d then
      return name
    end
  end
  return nil
end

apply(account_for_dir(vim.env.CLAUDE_CONFIG_DIR or "") or detect())

-- ---------------------------------------------------------------------------
-- Claude CLI login status
-- ---------------------------------------------------------------------------

---Path of the launcher that strips ANTHROPIC_API_KEY (same one claudecode.nvim runs).
---@return string
function M.claude_launcher()
  return vim.fn.stdpath("config") .. "/scripts/claude-nvim.sh"
end

---Does the reported email fit the active account?
---@param email string|nil
---@return boolean|nil  nil when there is nothing to compare
function M.identity_matches(email)
  if not email or email == "" then
    return nil
  end
  local pats = M.email_patterns[M.name] or {}
  if #pats == 0 then
    return nil
  end
  for _, p in ipairs(pats) do
    if email:lower():find(p) then
      return true
    end
  end
  return false
end

---Re-probe `claude auth status --json` for the active config dir (async).
---@param cb? fun(auth: AiAuthStatus)
function M.refresh_auth(cb)
  local launcher = M.claude_launcher()
  if vim.fn.executable(launcher) ~= 1 or vim.fn.executable("claude") ~= 1 then
    M.auth = { checked = true, loggedIn = false, error = "claude CLI not on PATH" }
    if cb then
      cb(M.auth)
    end
    return
  end
  local dir = M.claude_config_dir
  vim.system({ launcher, "auth", "status", "--json" }, {
    text = true,
    timeout = 8000,
    env = {
      CLAUDE_CONFIG_DIR = dir,
      CLAUDECODE_NVIM_USE_API_KEY = vim.g.claudecode_use_api_key and "1" or "0",
    },
  }, function(res)
    vim.schedule(function()
      if dir ~= M.claude_config_dir then
        return -- account switched while probing; a fresh probe is on its way
      end
      local auth = { checked = true }
      local ok, data = pcall(vim.json.decode, res.stdout or "")
      if ok and type(data) == "table" then
        auth.loggedIn = data.loggedIn == true
        auth.authMethod = data.authMethod
        auth.email = data.email
        auth.orgName = data.orgName
        auth.subscriptionType = data.subscriptionType
      else
        auth.loggedIn = false
        auth.error = vim.trim((res.stderr ~= "" and res.stderr) or res.stdout or "auth status gave no JSON")
      end
      M.auth = auth
      vim.api.nvim_exec_autocmds("User", { pattern = "AiAuthRefreshed", modeline = false })
      pcall(vim.cmd.redrawstatus)
      if cb then
        cb(auth)
      end
    end)
  end)
end

---One-line problem description, or nil when everything checks out.
---@return string|nil
function M.auth_problem()
  local a = M.auth
  if not a.checked then
    return nil
  end
  if a.error then
    return a.error
  end
  if not a.loggedIn then
    return "not logged in to " .. M.claude_config_dir
  end
  if a.authMethod and a.authMethod ~= "claude.ai" then
    return "authMethod is '" .. a.authMethod .. "' (not the subscription login)"
  end
  if M.identity_matches(a.email) == false then
    return "logged-in identity " .. a.email .. " does not look like the " .. M.name .. " account"
  end
  return nil
end

---Guard used before launching Claude Code: notify and return false on a known problem.
---@return boolean
function M.check_login()
  local problem = M.auth_problem()
  if not problem then
    return true
  end
  local fix = M.auth.loggedIn == false
      and ("Log in with: CLAUDE_CONFIG_DIR=" .. M.claude_config_dir .. " claude auth login   (or the claude-" .. (M.name == "work" and "justgames" or "personal") .. " shell wrapper, then /login)")
    or "Switch with :AiAccount work|personal, or :AiAccount to re-check."
  vim.notify(
    "Claude Code (" .. M.name .. "): " .. problem .. "\n" .. fix,
    vim.log.levels.ERROR,
    { title = "AI account" }
  )
  return false
end

---Short statusline text, e.g. "AI·personal·max", "AI·work·LOGIN!", "AI·work≠id!".
---@return string
function M.status_text()
  local a = M.auth
  if not a.checked then
    return "AI·" .. M.name .. "·…"
  end
  if a.error or not a.loggedIn then
    return "AI·" .. M.name .. "·LOGIN!"
  end
  if a.authMethod and a.authMethod ~= "claude.ai" then
    return "AI·" .. M.name .. "·" .. a.authMethod .. "!"
  end
  if M.identity_matches(a.email) == false then
    return "AI·" .. M.name .. "≠id!"
  end
  return "AI·" .. M.name .. "·" .. (a.subscriptionType or "?")
end

---@return "ok"|"warn"|"error"|"pending"
function M.status_level()
  if not M.auth.checked then
    return "pending"
  end
  return M.auth_problem() and "error" or "ok"
end

---Switch account at runtime: re-export CLAUDE_CONFIG_DIR, restart the Claude
---Code IDE server against the new lock dir, re-probe login.
---@param name "work"|"personal"
function M.switch(name)
  if not M.dirs[name] then
    vim.notify(
      "Unknown account '" .. tostring(name) .. "' (work|personal)",
      vim.log.levels.ERROR,
      { title = "AI account" }
    )
    return
  end
  local changed = name ~= M.name
  apply(name)

  if changed and package.loaded["claudecode"] then
    local cc = require("claudecode")
    pcall(function()
      require("claudecode.terminal").close()
    end)
    if cc.state and cc.state.server then
      pcall(cc.stop)
    end
    -- lockfile.lua computes its dir once at require time from CLAUDE_CONFIG_DIR.
    pcall(function()
      require("claudecode.lockfile").lock_dir = vim.fn.expand(M.claude_config_dir .. "/ide")
    end)
    if cc.state and cc.state.config and cc.state.config.auto_start then
      pcall(cc.start, false)
    end
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "AiAccountChanged", modeline = false })
  M.refresh_auth(function(auth)
    local msg = "AI account: " .. M.name .. "  (" .. M.claude_config_dir .. ")"
    local problem = M.auth_problem()
    if problem then
      vim.notify(msg .. "\n" .. problem, vim.log.levels.WARN, { title = "AI account" })
    else
      vim.notify(
        msg .. "\nlogged in as " .. tostring(auth.email) .. " (" .. tostring(auth.subscriptionType) .. ")",
        vim.log.levels.INFO,
        { title = "AI account" }
      )
    end
  end)
end

-- ---------------------------------------------------------------------------
-- Anthropic API key (codecompanion only)
-- ---------------------------------------------------------------------------

local function looks_like_security_error(s)
  return s:match("^security:") ~= nil or s:lower():match("could not be found") ~= nil
end

local function from_keychain(service)
  local raw = vim.fn.system({ "security", "find-generic-password", "-s", service, "-w" })
  local out = type(raw) == "string" and raw:gsub("%s+$", "") or ""
  if vim.v.shell_error ~= 0 or out == "" or looks_like_security_error(out) then
    return nil, "keychain item '" .. service .. "' not found"
  end
  return out, "keychain:" .. service
end

--- Resolve the Anthropic API key for the active account. Cached after first call.
---@return string|nil key
---@return string source_or_reason  where it came from, or why it is missing
function M.anthropic_api_key()
  if key_cache.resolved then
    return key_cache.key, key_cache.key and key_cache.source or key_cache.reason
  end
  key_cache.resolved = true
  local env = vim.env.ANTHROPIC_API_KEY
  if env and env ~= "" then
    key_cache.key, key_cache.source = env, "env:ANTHROPIC_API_KEY"
  else
    local key, info = from_keychain("anthropic-api-key-" .. M.name)
    if key then
      key_cache.key, key_cache.source = key, info
    else
      key_cache.reason = info
    end
  end
  return key_cache.key, key_cache.key and key_cache.source or key_cache.reason
end

--- Forget the cached key so the next call re-resolves (after adding a keychain item).
function M.reset_key_cache()
  key_cache = { resolved = false }
end

-- ---------------------------------------------------------------------------
-- Reporting
-- ---------------------------------------------------------------------------

--- Human-readable status lines for the <leader>ia info popup.
---@return string[]
function M.status_lines()
  local a = M.auth
  local lines = {
    "Account: "
      .. M.name
      .. "  (startup cwd "
      .. M.cwd
      .. (vim.env.NVF_AI_ACCOUNT and ", NVF_AI_ACCOUNT override" or "")
      .. ")",
    "CLAUDE_CONFIG_DIR: " .. (vim.env.CLAUDE_CONFIG_DIR or "?"),
  }
  if not a.checked then
    table.insert(lines, "Claude login: probing…")
  elseif a.error then
    table.insert(lines, "Claude login: ERROR " .. a.error)
  elseif not a.loggedIn then
    table.insert(lines, "Claude login: NOT LOGGED IN")
  else
    table.insert(
      lines,
      string.format(
        "Claude login: %s via %s, plan %s, org %s",
        tostring(a.email),
        tostring(a.authMethod),
        tostring(a.subscriptionType),
        tostring(a.orgName)
      )
    )
  end
  local problem = M.auth_problem()
  if problem then
    table.insert(lines, "  !! " .. problem)
  end
  local claude = vim.fn.exepath("claude")
  table.insert(lines, "claude CLI: " .. (claude ~= "" and claude or "NOT ON PATH"))
  local key, info = M.anthropic_api_key()
  table.insert(
    lines,
    "Anthropic API key (codecompanion only): " .. (key and ("set, " .. info) or ("NOT SET, " .. info))
  )
  table.insert(
    lines,
    "ANTHROPIC_API_KEY in env: "
      .. (
        (vim.env.ANTHROPIC_API_KEY and vim.env.ANTHROPIC_API_KEY ~= "")
          and "yes (stripped for the CLI by scripts/claude-nvim.sh)"
        or "no"
      )
  )
  return lines
end

vim.api.nvim_create_user_command("AiAccount", function(opts)
  local arg = vim.trim(opts.args or "")
  if arg == "" then
    M.refresh_auth(function()
      vim.notify(table.concat(M.status_lines(), "\n"), vim.log.levels.WARN, { title = "AI account" })
    end)
    return
  end
  M.switch(arg)
end, {
  nargs = "?",
  complete = function()
    return { "work", "personal" }
  end,
  desc = "Show or switch the AI account (work|personal): CLAUDE_CONFIG_DIR, Claude login, API key",
})

-- Probe the login once the UI is up so the statusline has an answer quickly.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      M.refresh_auth()
    end, 200)
  end,
})

return M

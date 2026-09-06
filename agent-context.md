# Agent context: lazy-fullstack

**Purpose:** Single, agent-friendly context document for this repo. Use this for fast onboarding (Warp, Cursor, Claude, or in-editor agents like CodeCompanion/Claude Code).

---

## 1. Repo in one sentence

Neovim config built on **LazyVim** (lazy.nvim): upstream LazyVim plugins plus project-specific Lua under `lua/config`, `lua/plugins`, `lua/util`, and `ftplugin/` — no app build/test here; this is editor configuration only.

---

## 2. Entry and layout

| Path | Role |
|------|------|
| `init.lua` | Entry: globals (autowrite, tab 2), then `config.project_listen`, `config.account`, `config.lazy`, `config.suppress_warnings`; `<leader>o` = Aerial outline |
| `lua/config/lazy.lua` | Bootstraps lazy.nvim, imports LazyVim + `lua/plugins`; no hand-edit of `lazy-lock.json` |
| `lua/config/options.lua` | Options overlay (textwidth 79, colorcolumn, notify logging flag, Python host prog) |
| `lua/config/keymaps.lua` | Extra keymaps (`<leader>cw` split width, `<leader>ia` AI status, `<leader>is` RPC socket, `<leader>ug`) |
| `lua/config/autocmds.lua` | Extra autocmds |
| `lua/config/suppress_warnings.lua` | Suppress benign runtime warnings; required from init |
| `lua/config/account.lua` | Work/personal: `NVF_AI_ACCOUNT` env, else **startup** cwd under `~/Dev/justgames`, else `DOTFILES_ROLE=work-dev`, else personal. Exports `CLAUDE_CONFIG_DIR` (~/.claude-{justgames,personal}), probes `claude auth status --json` (login, plan, identity) for the statusline and the launch guard, `:AiAccount [work\|personal]` shows/switches at runtime; lazily resolves the Anthropic API key (env `ANTHROPIC_API_KEY` from direnv, else keychain `anthropic-api-key-{work,personal}`) without exporting it |
| `global-ai-instructions.md` | Cross-repo engineering defaults appended to the CodeCompanion chat system prompt (via `stdpath("config")`) |

---

## 3. Plugins (`lua/plugins/`)

Each file returns one or more lazy.nvim specs. Add/change behavior here; don’t edit upstream LazyVim.

- **AI (Claude-only, subscription-primary):** `ai-claudecode.lua` — Claude Code CLI in a split with native diff review; `<leader>ae` refines the selection/file (sends context, asks for an instruction), `<leader>ac/ao/aC/ar/ap/as/ab/ay/an/am` for toggle/focus/continue/resume/plan/send/add/accept/deny/model; launch keys are guarded by `config.account.check_login()`. `ai-codecompanion.lua` — secondary, pay-per-token API path: `<leader>aE` inline diff, `<leader>aa/ai/ad/ax/af/at/al` palette/chat/prompts. `ai-statusline.lua` — lualine `AI·<account>·<plan>` segment (red on no login / wrong identity / API-key auth). `:PlanNew` opens Claude Code in plan mode. `blink-cmp.lua` is LSP + LuaSnip only. No Copilot, no Avante, no Cursor agent.
- **LSP / format / lint:** `lsp-overrides.lua`, `lsp-nav.lua` (`gpd`/`gpi`/`gpr` peek+browse), `go-gopls-lsp.lua`, `python-lsp.lua`, `python-format.lua`, `python-lint.lua`, `solidity.lua`, `toml.lua`, `markdown-conform-formtters.lua`, `markdownlint.lua`.
- **Test / debug:** `test.lua` (neotest), `go-neotest.lua`, `go-nvim-dap.lua`, `dap.adapters.lua`, `mason-nvim-dap.lua`; shared DAP helpers in `lua/util/dap.lua`.
- **UX / nav:** `aerial.lua`, `neo-tree.lua`, `tmux-navigator.lua`, `snacks.lua`, `keymap-leader-scrolloff.lua`, `colorscheme-catppuccin.lua`.
- **Docs / rail 2:** `doc-workflow.lua` — `:ArcNew`, `:AdrNew`, `:PlanNew`, `:DocList` (files under **buffer git root** `docs/`); `:DocNew` deprecated.
- **Other:** `example.lua` / `test.lua` (specs).

`ftplugin/markdown.lua` and `ftplugin/solidity.lua`: filetype-specific options.

---

## 4. Conventions for agents

- **No top-level build/test.** This is a config repo; run tests in the project you open with this Neovim.
- **`docs/` in lazy-fullstack:** Only **tooling** the config integrates with (e.g. upgrade logs). **Do not** add application docs here; those belong in work repos.
- **`:ArcNew` / `:AdrNew`:** Create `docs/arc/` and `docs/adr/` in the **current buffer’s git root**, not necessarily lazy-fullstack.
- **One plugin spec per file** under `lua/plugins/`; follow existing naming.
- **Keep `init.lua` minimal;** put logic in `lua/config/`, `lua/plugins/`, `lua/util/`.
- **Don’t hand-edit `lazy-lock.json`;** lazy.nvim manages it.

### AI account (startup cwd)

`config.account` picks work vs personal at startup (`NVF_AI_ACCOUNT`, startup cwd, `DOTFILES_ROLE`), setting `CLAUDE_CONFIG_DIR` for the Claude Code CLI and the keychain item for the API key. Buffer paths do not re-evaluate account; `:AiAccount work|personal` switches at runtime (restarts the IDE server against the other lock dir). The lualine `AI·…` segment and `<leader>ia` show the identity `claude auth status` reports for that dir. On a machine where a dir has no login, `<leader>ac` refuses and prints the login command.

---

## 5. Key references

- **Full workflows:** [WARP.md](WARP.md).
- **AI system prompt defaults:** [global-ai-instructions.md](global-ai-instructions.md).

---

## 6. Quick file index

```
init.lua
global-ai-instructions.md
lua/config/account.lua
lua/config/configure_mcp_location.lua
lua/config/lazy.lua
lua/config/options.lua
lua/config/keymaps.lua
lua/config/autocmds.lua
lua/config/suppress_warnings.lua
lua/plugins/ai-claudecode.lua
lua/plugins/ai-codecompanion.lua
lua/plugins/ai-statusline.lua
lua/plugins/blink-cmp.lua
lua/plugins/doc-workflow.lua
lua/plugins/lsp-overrides.lua
lua/plugins/lsp-nav.lua
lua/plugins/go-gopls-lsp.lua
lua/plugins/go-neotest.lua
lua/plugins/go-nvim-dap.lua
lua/plugins/python-lsp.lua
lua/plugins/python-format.lua
lua/plugins/python-lint.lua
lua/plugins/solidity.lua
lua/plugins/test.lua
lua/util/dap.lua
ftplugin/markdown.lua
ftplugin/solidity.lua
WARP.md
```

---

*Use this doc for fast context; for detailed workflows, see WARP.md.*

# Agent context: lazy-fullstack

**Purpose:** Single, agent-friendly context document for this repo. Use this for fast onboarding (Warp, Cursor, Claude, or in-editor agents like Avante/cursoragent).

---

## 1. Repo in one sentence

Neovim config built on **LazyVim** (lazy.nvim): upstream LazyVim plugins plus project-specific Lua under `lua/config`, `lua/plugins`, `lua/util`, and `ftplugin/` — no app build/test here; this is editor configuration only.

---

## 2. Entry and layout

| Path | Role |
|------|------|
| `init.lua` | Entry: globals (autowrite, tab 2), then `config.cursor_account`, `config.configure_mcp_location`, `config.lazy`, `config.suppress_warnings`; `<leader>o` = Aerial outline |
| `lua/config/lazy.lua` | Bootstraps lazy.nvim, imports LazyVim + `lua/plugins`; no hand-edit of `lazy-lock.json` |
| `lua/config/options.lua` | Options overlay (textwidth 79, colorcolumn, notify logging flag, Python host prog) |
| `lua/config/keymaps.lua` | Extra keymaps (cursor account, Avante diagnostics, `<leader>aE`, visual `<leader>ae`) |
| `lua/config/autocmds.lua` | Extra autocmds |
| `lua/config/suppress_warnings.lua` | Suppress benign runtime warnings; required from init |
| `lua/config/cursor_context.lua` | Shared: work_root (`~/Dev/justgames`), **startup** cwd, account_name (work/personal); used by cursor_account and configure_mcp_location |
| `lua/config/cursor_account.lua` | Sets `vim.g.cursor_account` and `CURSOR_API_KEY` from macOS keychain using `config.cursor_context` |
| `lua/config/configure_mcp_location.lua` | Sets `vim.g.mcp_config_path` and `vim.g.mcphub_config_path` by account (work/personal) from `config.cursor_context` |
| `global-ai-instructions.md` | Cross-repo Avante `system_prompt` (via `stdpath("config")`); symlink/copy beside `init.lua` when this repo is the config |
| `docs/cursor-agent-capabilities.md` | **Tooling-only:** CLI inventory for `agent` / Neovim integration (update when CLI upgrades) |

---

## 3. Plugins (`lua/plugins/`)

Each file returns one or more lazy.nvim specs. Add/change behavior here; don’t edit upstream LazyVim.

- **AI:** `avante.lua` (Claude, agentic, `avante.md` + `global-ai-instructions.md`), `cursoragent.nvim` (`terminal_cmd = agent`, `<leader>CC/Ca/Cp/Cr/Cs`, `:PlanNew`), `blink-cmp-avante.lua` (LSP before Avante in sources). Copilot disabled elsewhere; Avante + Claude primary.
- **LSP / format / lint:** `lsp-overrides.lua`, `lsp-nav.lua` (`gpd`/`gpi`/`gpr` peek+browse), `go-gopls-lsp.lua`, `python-lsp.lua`, `python-format.lua`, `python-lint.lua`, `solidity.lua`, `toml.lua`, `markdown-conform-formtters.lua`, `markdownlint.lua`.
- **Test / debug:** `test.lua` (neotest), `go-neotest.lua`, `go-nvim-dap.lua`, `dap.adapters.lua`, `mason-nvim-dap.lua`; shared DAP helpers in `lua/util/dap.lua`.
- **UX / nav:** `aerial.lua`, `neo-tree.lua`, `tmux-navigator.lua`, `snacks.lua`, `keymap-leader-scrolloff.lua`, `colorscheme-catppuccin.lua`.
- **Docs / rail 2:** `doc-workflow.lua` — `:ArcNew`, `:AdrNew`, `:PlanNew`, `:DocList` (files under **buffer git root** `docs/`); `:DocNew` deprecated.
- **Other:** `mcphub.lua`, `avante-status.lua`, `example.lua` / `test.lua` (specs).

`ftplugin/markdown.lua` and `ftplugin/solidity.lua`: filetype-specific options.

---

## 4. Conventions for agents

- **No top-level build/test.** This is a config repo; run tests in the project you open with this Neovim.
- **`docs/` in lazy-fullstack:** Only **tooling** the config integrates with (e.g. cursor-agent ledger). **Do not** add application docs here; those belong in work repos.
- **`:ArcNew` / `:AdrNew`:** Create `docs/arc/` and `docs/adr/` in the **current buffer’s git root**, not necessarily lazy-fullstack.
- **One plugin spec per file** under `lua/plugins/`; follow existing naming.
- **Keep `init.lua` minimal;** put logic in `lua/config/`, `lua/plugins/`, `lua/util/`.
- **Don’t hand-edit `lazy-lock.json`;** lazy.nvim manages it.

### Cursor account (startup cwd)

`cursor_context` is evaluated at startup: **initial Neovim cwd** picks work vs personal for keys/MCP for the **whole session**. Restart to switch accounts; buffer paths do not re-evaluate account.

---

## 5. Key references

- **Full workflows:** [WARP.md](WARP.md).
- **Avante / project instructions:** [avante.md](avante.md); global stack defaults: [global-ai-instructions.md](global-ai-instructions.md).
- **Cursor CLI ↔ Neovim:** [docs/cursor-agent-capabilities.md](docs/cursor-agent-capabilities.md).

---

## 6. Quick file index

```
init.lua
global-ai-instructions.md
docs/cursor-agent-capabilities.md
lua/config/cursor_context.lua
lua/config/cursor_account.lua
lua/config/configure_mcp_location.lua
lua/config/lazy.lua
lua/config/options.lua
lua/config/keymaps.lua
lua/config/autocmds.lua
lua/config/suppress_warnings.lua
lua/plugins/avante.lua
lua/plugins/cursoragent.lua
lua/plugins/blink-cmp-avante.lua
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
avante.md
WARP.md
```

---

*Use this doc for fast context; for detailed workflows, see WARP.md and avante.md.*

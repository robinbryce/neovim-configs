# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

**For a concise, agent-friendly context summary:** see [agent-context.md](agent-context.md).

## Repository overview

This repo is a Neovim configuration based on the LazyVim starter template. It bootstraps
`lazy.nvim`, pulls in the upstream `LazyVim/LazyVim` plugin collection, and layers
project‑specific configuration and plugins on top.

There are no project‑local build, lint, or test scripts in this repository. It is a
pure editor configuration; testing and building happen in the language projects you
open with this Neovim config.

## Common workflows and commands

Because this is a Neovim config, most work happens inside Neovim rather than via
shell scripts.

### Launching Neovim with this config

This directory is structured as a full Neovim config rooted at `init.lua`. How it is
connected to your Neovim installation (symlink, Nix profile, etc.) is outside the
scope of this repo. Do not assume a particular launch command; instead, edit the
files here and rely on the user’s Neovim setup to load them.

### Inside Neovim: plugin management (LazyVim / lazy.nvim)

The plugin manager is configured in `lua/config/lazy.lua`. It:
- Bootstraps `lazy.nvim` under Neovim’s data directory if not present.
- Registers the upstream `LazyVim/LazyVim` spec via `import = "lazyvim.plugins"`.
- Imports all local plugin specs from the `lua/plugins` directory.

Use upstream LazyVim / lazy.nvim documentation for commands such as viewing and
updating plugins; those commands are not redefined in this repo.

### Inside Neovim: testing shortcuts (neotest)

The `lua/plugins/test.lua` module configures `nvim-neotest/neotest` with Jest and
Vitest adapters and defines keymaps:
- `<leader>tl` – run the last test.
- `<leader>tL` – debug the last test via DAP.
- `<leader>tw` – run Jest in `--watch` mode in the current project.

These keymaps act on the *current working directory’s* project tests (Jest / Vitest),
not on this config repo itself.

### Inside Neovim: debugging (DAP)

Debugging helpers live in `lua/util/dap.lua`:
- `require("util.dap").setup()` installs temporary DAP keymaps when a debug session
  starts and restores any existing mappings when it ends.
- Function keys are used for DAP control when active:
  - `<F5>` – continue.
  - `<F10>` – step over.
  - `<F11>` – step into.
  - `<F12>` – step out.
  - `<F9>` – toggle breakpoint.

Go‑specific DAP configuration is in `lua/plugins/go-nvim-dap.lua`, which adjusts
`nvim-dap-go` delve build flags to include test tags.

### Inside Neovim: logs and notifications

`lua/plugins/notify-logger-with-warning-suppressions.lua` wraps `vim.notify` to:
- Optionally log notifications to `stdpath("data") .. "/notify.log"` when
  `vim.g.enable_notify_logging` is true.
- Suppress a specific noisy autocmd warning.

Toggling `vim.g.enable_notify_logging` (set in `lua/config/options.lua`) controls
whether a new session header and subsequent notifications are appended to that log.

### Cursor account / MCP (startup cwd)

`lua/config/cursor_context.lua` runs once at startup: **Neovim’s initial working
directory** determines work vs personal (`~/Dev/justgames` prefix) for
`CURSOR_API_KEY` / MCP paths for the **entire session**. Editing buffers in other
repos does not switch accounts; restart Neovim from a different cwd if you need
the other account.

### ARC/ADR and lazy-fullstack `docs/`

- **`:ArcNew`** / **`:AdrNew`** (from `doc-workflow.lua`) create numbered files under
  `docs/arc/` and `docs/adr/` in the **git root of the current buffer** (the project
  you are working in), not in the Neovim config repo by default.
- Under **lazy-fullstack** itself, `docs/` is reserved for **integration tooling**
  the config depends on (e.g. [docs/cursor-agent-capabilities.md](docs/cursor-agent-capabilities.md)),
  not application documentation.
- **`:PlanNew`** / **`<leader>Cp`** start Cursor Agent **plan** mode (rail 2);
  interactive plans stay in agent storage, not in numbered `docs/plan*` files.

## Code structure and architecture

### Entry point and global configuration

- `init.lua` is the main entry point. It:
  - Sets some global options (e.g., tab width, `autowrite`).
  - Requires `config.project_listen`, `config.account`, `config.lazy`, and `config.suppress_warnings`.
  - Adds a global mapping `<leader>o` to toggle the Aerial outline (AI uses the `<leader>a` prefix; see `lua/plugins/ai-codecompanion.lua` and `lua/plugins/ai-claudecode.lua`).

- `lua/config/` contains core editor configuration:
  - `lazy.lua` – lazy.nvim and LazyVim setup (plugin specs, performance tweaks,
    disabled runtime plugins, plugin update checker).
  - `options.lua` – global options layered on top of LazyVim defaults (notably
    textwidth and colorcolumn setup and a flag controlling notify logging).
  - `keymaps.lua` – extension point for additional global keymaps.
  - `autocmds.lua` – extension point for additional autocmds; comments show how to
    add or remove LazyVim defaults.
  - `suppress_warnings.lua` – additional logic to quiet specific runtime warnings
    (required from `init.lua`).

### Filetype‑specific behavior

- `ftplugin/markdown.lua` configures Markdown buffers for 79‑column textwidth and
  specific format options.
- `ftplugin/solidity.lua` enforces 4‑space indentation and registers the `sol` file
  extension as `solidity`.

These files are the right place to put per‑filetype options that should *not* apply
globally.

### Plugin specification layout (`lua/plugins/`)

Each file in `lua/plugins/` returns one or more lazy.nvim plugin specs. Common
patterns:
- Language tooling specs:
  - `lsp-overrides.lua` – LSP defaults (inlay hints off; upstream Mason integration).
  - `lsp-nav.lua` – `gpd`/`gpi`/`gpr` peek and browse via FzfLua.
  - `go-gopls-lsp.lua` – `gopls` build tags + Mason ensure_installed for Go tools.
  - `go-neotest.lua` – extends `neotest` with Go support and shared test tags.
  - `go-nvim-dap.lua` – configures delve flags for Go DAP sessions.
  - `python-format.lua` – configures `conform.nvim` to format Python with `black`
    and `isort`.
  - `python-lint.lua` – configures `nvim-lint` to use `ruff` for Python.
  - `python-lsp.lua` – configures `pyright` with specific analysis settings.
  - `solidity.lua` – sets up a Solidity LSP server that reads remappings from
    `remappings.txt` or `foundry.toml` in each project and disables autoformat for
    Solidity buffers.

- Editor UX and navigation:
  - `aerial.lua` – configures `stevearc/aerial.nvim`, toggled with `<leader>o` in `init.lua`.
  - `snacks.lua` – tweaks the Snacks explorer to show hidden files and ignore
    `.gitignore` by default.
  - Additional plugin specs (e.g., `neo-tree`, `tmux-navigator`, etc.) may adjust
    navigation and UI; follow the same pattern when adding new plugins.

- Testing and debugging:
  - `test.lua` – neotest configuration and keymaps (see above).
  - DAP helpers live in `lua/util/dap.lua` rather than in a plugin spec to allow
    reuse from multiple plugins.

- AI and assistant integrations (Claude-only; all keys under `<leader>a`):
  - `ai-claudecode.lua` (primary, subscription) – `coder/claudecode.nvim`: the Claude Code
    CLI in a right split (`<leader>ac`), launched via `scripts/claude-nvim.sh` with
    `CLAUDE_CONFIG_DIR` set to `~/.claude-{personal,justgames}`. `<leader>ae` on a selection
    (or file in normal mode) sends it as context, asks for an instruction and submits;
    Claude's edits open as native diffs (`<leader>ay` accept, `<leader>an` deny). Launch keys
    refuse when `config.account` finds no login / the wrong identity. `:PlanNew` opens a
    session in plan mode.
  - `ai-codecompanion.lua` (secondary, pay-per-token) – `olimorris/codecompanion.nvim` over
    the Anthropic API: `<leader>aE` inline refine with in-place per-hunk diff, actions
    palette and chat. The API key is resolved lazily by `lua/config/account.lua` (direnv
    `ANTHROPIC_API_KEY`, else keychain `anthropic-api-key-{work,personal}`);
    `global-ai-instructions.md` is appended to the chat system prompt.
  - `ai-statusline.lua` – lualine `AI·<account>·<plan>` segment from `claude auth status`;
    red when not logged in, wrong identity, or API-key auth. `:AiAccount work|personal`
    switches at runtime; bare `:AiAccount` re-probes.
  - `blink-cmp.lua` – LSP + LuaSnip completion only; no AI completion source, no Copilot.
  - `doc-workflow.lua` – `:ArcNew`, `:AdrNew`, `:PlanNew`, `:DocList`; deprecated `:DocNew`.
  - `<leader>ia` reports the resolved account, key source, and Claude Code connection.

When adding or modifying plugins, follow the existing pattern: create a new Lua
module under `lua/plugins/` that returns one or more plugin spec tables, rather
than editing upstream LazyVim plugin definitions directly.

### Utilities

- `lua/util/dap.lua` provides reusable helpers for DAP keymaps and configuration,
  including:
  - `setup()` – installs and restores DAP keymaps around sessions.
  - `clone_and_extend(base, overrides)` – shallow‑clone and extend a table.
  - `config_index(configs, name)` – find a named DAP configuration in a list.
  - `get_vite_node_path()` – discovers a `vite-node` binary via `pnpm bin` and
    reports an error via `vim.notify` if not found.
  - `cli_env_debug_file(program_path)` – derive a `.env` file name for debugging
    Node CLI programs.

This module is the preferred place to add shared debugging‑related helpers.

### Plugin locking

- `lazy-lock.json` is the lazy.nvim lockfile pinning plugin versions. It is
  generated and updated by lazy.nvim / LazyVim; agents should not hand‑edit it.

## Guidance for future agents

- **Context doc:** Prefer [agent-context.md](agent-context.md) for a quick index and conventions; use this file (WARP.md) for detailed workflows and structure.
- Treat this repo as Neovim configuration, not an application: there is no
  top‑level build or test entrypoint.
- When editing behavior for a specific language, prefer adding or updating a
  dedicated plugin spec in `lua/plugins/` or a filetype plugin in `ftplugin/`.
- Keep `init.lua` minimal, delegating behavior to modules under `lua/config/`,
  `lua/plugins/`, and `lua/util/` following the existing patterns.
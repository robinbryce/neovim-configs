# Cursor Agent CLI — capabilities ledger (Neovim integration)

This file documents the **Cursor Agent** / **`agent`** CLI as wired into this Neovim config.  
**Scope:** tooling the config depends on (`cursoragent.nvim`, Avante ACP). It is **not** application documentation.

Update this doc whenever you upgrade the CLI: re-capture **Version** and **Help** below, then adjust [lua/plugins/cursoragent.lua](../lua/plugins/cursoragent.lua) and [lua/plugins/avante.lua](../lua/plugins/avante.lua) if flags changed.

---

## Captured from this machine

**Date recorded:** 2026-04-09  
**Binary:** `cursor-agent` and `agent` both resolve; `cursor-agent --help` matches `agent --help`.

**Version (`cursor-agent --version` / `agent --version`):**

```
2026.04.08-a41fba1
```

**Help (`cursor-agent --help`):** (excerpt — full output in shell history)

- **Modes:** `--mode <mode>` with choices `plan` (read-only planning) and `ask` (Q&A read-only). Shorthand: `--plan` for plan mode.
- **Resume / continue:** `--resume [chatId]`, `--continue` (continue previous session).
- **Auth:** `--api-key`, env `CURSOR_API_KEY`.
- **Workspace:** `--workspace <path>` (defaults to cwd).
- **Other:** `--print`, `--model`, `mcp`, `ls`, `resume`, etc.

---

## Interpretation for Neovim

| Need | CLI surface | Config |
|------|-------------|--------|
| Ask mode | `--mode ask` | `command_variants.ask` → `"--mode ask"` |
| Plan mode | `--mode plan` or `--plan` | `command_variants.plan` → `"--mode plan"` |
| Resume last | `--continue` | `command_variants.resume` → `"--continue"` |
| Default binary | `agent` on PATH (help text: `Usage: agent`) | `terminal_cmd = "agent"` in [cursoragent.lua](../lua/plugins/cursoragent.lua) |
| ACP (Avante) | `agent --api-key … acp` (subcommand not in top-level help list; verify with `agent acp --help` if ACP breaks) | [avante.lua](../lua/plugins/avante.lua) `acp_providers.cursor` |

---

## Config linkage

- **Terminal + MCP:** [lua/plugins/cursoragent.lua](../lua/plugins/cursoragent.lua) — `terminal_cmd`, `command_variants`, MCP `auto_start`.
- **Inline ACP:** [lua/plugins/avante.lua](../lua/plugins/avante.lua) — `acp_providers.cursor.command` / `args` (must stay consistent with `terminal_cmd` and PATH).

---

## Session storage (rail 2)

Agent chat/session persistence is **tool-native** (Cursor / `~/.cursor` and related state). Exact paths can vary by OS and CLI version. After upgrades, run **`agent about`**, **`agent ls`** (list sessions to resume), and inspect **`~/.cursor`** to refresh paths here.

**Concurrency (operators):** Use **separate terminals** (e.g. tmux windows) per planning thread with `auto_close = false` on the Cursor agent split, or resume via **`agent ls`** / **`--resume [chatId]`** / **`--continue`** per current `--help`. Record behaviour changes in this file when the CLI changes.

---

## Upgrade ritual

1. Install/update CLI (`agent update` or installer).
2. Run `cursor-agent --version` and `cursor-agent --help` (and `agent acp --help` if you use ACP).
3. Paste outputs into **Captured from this machine** (replace dated sections).
4. Diff this file and adjust `command_variants` / `terminal_cmd` / ACP `args` if needed.
5. Smoke test: `:CursorAgentAsk`, `:CursorAgentPlan`, `:CursorAgentResume`, `:PlanNew` (if defined), Avante with Cursor ACP (optional).

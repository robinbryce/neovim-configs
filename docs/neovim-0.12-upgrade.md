# Neovim 0.12 upgrade plan (nvf)

Upgrade path from **Neovim 0.11.5** → **0.12.4** for the `nvf` config (`~/.config/nvf`, symlinked from `~/Dev/tooling/neovim/lazy-fullstack`).

**Recommendation:** proceed. Your plugin lockfile already ships **aerial.nvim 4.0.0+**, which refuses to initialize on Neovim &lt; 0.12.

---

## Why upgrade

| Driver | Detail |
|--------|--------|
| **Aerial** | `aerial.nvim` 4.0.0+ calls `setup()` only on Neovim ≥ 0.12. On 0.11 you get an error notify and outline (`<leader>o`) does not work properly. |
| **Treesitter** | LazyVim pins an old `nvim-treesitter` commit on 0.11; on 0.12 it uses **main** with updated APIs Aerial expects. |
| **Ecosystem** | LazyVim 16, blink.cmp, and other plugins are moving to 0.12-first fixes. |

---

## Pre-flight checklist

- [ ] No urgent deadline — allow 30–60 minutes for upgrade + smoke tests.
- [ ] Commit or stash any uncommitted changes in `lazy-fullstack` / dotfiles.
- [ ] Note current version: `nvim --version` (expect `v0.11.5`).
- [ ] Optional rollback: `brew install neovim@0.11` is not a standard tap; rollback is `brew reinstall neovim` only if Homebrew still has the old bottle cached, or install from prior brew bundle. Simpler safety net: finish plugin updates only after Neovim upgrade succeeds.

---

## Phase 1 — Config changes (before or with upgrade)

Do these in the `nvf` repo first so the first 0.12 session is clean.

### 1.1 DAP sign setup (`lua/plugins/dap.adapters.lua`)

**Context:** Lines 26–35 duplicate LazyVim’s `dap.core` sign loop and call `vim.fn.sign_define()` for each `LazyVim.config.icons.dap` entry.

**Neovim 0.12 nuance:** `sign_define()` is removed only for **diagnostic** signs (`:help news-0.12`). **nvim-dap** still uses `sign_define` for breakpoint/stopped signs ([nvim-dap#1292](https://github.com/mfussenegger/nvim-dap/issues/1292)). Your DAP customization should keep working, but you should de-duplicate and verify.

**Change to apply:**

Replace the inline sign loop with a small helper that:

1. Defines signs only if not already defined (matches nvim-dap’s own `sign_try_define` pattern).
2. Uses `vim.fn.sign_define` on 0.11 and 0.12 (still valid for non-diagnostic plugin signs).
3. Avoids double-definition when LazyVim `dap.core` also runs.

```lua
-- In dap.adapters.lua config, replace lines 26-35 with:

local function define_dap_signs()
  local icons = require("lazyvim.config").icons.dap
  for name, sign in pairs(icons) do
    sign = type(sign) == "table" and sign or { sign }
    local sign_name = "Dap" .. name
    if vim.tbl_isempty(vim.fn.sign_getdefined(sign_name)) then
      vim.fn.sign_define(sign_name, {
        text = sign[1],
        texthl = sign[2] or "DiagnosticInfo",
        linehl = sign[3],
        numhl = sign[3],
      })
    end
  end
end
define_dap_signs()
```

**After upgrade verification:**

- [ ] `:lua vim.fn.sign_getdefined('DapBreakpoint')` returns your icon config.
- [ ] `<leader>db` places a visible breakpoint sign in a test buffer.
- [ ] `<leader>dc` shows `DapStopped` (→) on the stopped line when debugging.

**If signs break after `:Lazy update`:** check upstream LazyVim `dap/core.lua` and nvim-dap release notes; align with whatever they ship for 0.12.

### 1.2 Optional cleanup (not blocking)

| File | Note |
|------|------|
| `lua/plugins/doc-workflow.lua` | Uses `vim.loop` → prefer `vim.uv` when touching that file. |
| `lua/plugins/solidity.lua` | Already has `vim.uv or vim.loop` fallback. |

No other nvf files use removed 0.12 APIs (`vim.diagnostic.disable`, legacy `vim.diagnostic.enable`, etc.).

### 1.3 Cmdline / noice (no action required)

Current setup intentionally uses **native cmdline** (`noice` cmdline/messages disabled, `cmdheight = 1`). This sidesteps the noice popup issues on 0.11 and remains valid on 0.12.

---

## Phase 2 — Upgrade Neovim

```bash
brew upgrade neovim
nvim --version   # target: NVIM v0.12.4
```

Confirm `nvf` still resolves:

```bash
type nvf   # alias NVIM_APPNAME=nvf nvim
```

---

## Phase 3 — First nvf session on 0.12

```vim
nvf
:Lazy update
:TSUpdate
:MasonUpdate
:checkhealth
```

**Expected LazyVim behavior:**

- `nvim-treesitter` unpins the 0.11-specific commit and tracks **main**.
- `TSUpdate` may take several minutes (Go, TS, Python, Solidity, etc. from your extras).

**Watch `:checkhealth` for:**

- `nvim-treesitter` — parsers installed
- `noice` — OK (cmdline disabled is fine)
- `dap` / `mason` — adapters present
- LSP servers you use (gopls, pyright, rust-analyzer, etc.)

---

## Phase 4 — Smoke tests

Run in a real project (e.g. `forestrie` or `justgames`).

### Editor / navigation

| Test | Keys / command | Pass? |
|------|----------------|-------|
| Aerial outline | `<leader>o` | Opens symbol tree, no error notify |
| Native ex cmd | `:!pwd` | Output + Press ENTER |
| Shell scratch | `<leader>cy` | Prompt → bottom scratch with output |
| Terminal | `Ctrl+/` | Snacks terminal toggles |

### LSP / diagnostics

| Test | Pass? |
|------|-------|
| Open `.go` / `.ts` / `.py` file — diagnostics appear | |
| `<leader>cd` line diagnostic float | |
| `<leader>ca` code action | |

### DAP (after sign fix)

| Test | Pass? |
|------|-------|
| Toggle breakpoint `<leader>db` — sign visible | |
| Continue `<leader>dc` on a configured launch (Node or Go) | |
| DAP UI `<leader>du` opens | |

### AI integrations (if enabled in cwd)

| Test | Pass? |
|------|-------|
| Avante `<leader>ae` | |
| Cursor agent split (`cursoragent` keymaps) | |

### Neotest (if used in repo)

```vim
:Neotest summary
```

---

## Phase 5 — Rollback (if needed)

If blocking issues appear:

1. Note the failure (`:messages`, `:checkhealth`, log path from `scripts/nvim-diag.sh`).
2. Downgrade Neovim: check `brew info neovim` / brew history; worst case reinstall 0.11 from source or pin an older brew bottle if available.
3. Do **not** downgrade aerial — it requires 0.12. Instead pin aerial to pre-4.0 on 0.11 only if you must stay on 0.11 (not recommended).

---

## 0.12 behavior changes (awareness)

| Change | Impact on nvf |
|--------|----------------|
| `msg_show.return_prompt` removed from `ui-messages` | Neutral — native `:!` already works; noice messages off |
| `'shelltemp'` defaults to `false` | Low — watch exotic `:!` pipelines |
| Insert `Ctrl-R` inserts literally | Low unless you used register eval in insert mode |
| `vim.treesitter.get_parser()` returns `nil` instead of error | Plugins handle it; run `:TSUpdate` |
| Diagnostic signs via `sign_define` removed | **Not** your DAP signs — only `vim.diagnostic.config({ signs = ... })` for LSP diagnostics |

---

## Post-upgrade improvements (optional, later)

- [ ] Revisit noice `cmdline_popup` on 0.12 if you want floating `:` again (0.12 improves `vim.ui_attach`; your prior setup failed on 0.11).
- [ ] Review whether `nvim-treesitter` extras can shrink now that built-in treesitter improved.
- [ ] Update `lazy-lock.json` commit in git after a stable week on 0.12.

---

## Task summary

| # | Task | Owner | Done |
|---|------|-------|------|
| 1 | Apply DAP sign helper in `dap.adapters.lua` | agent | [x] |
| 2 | `brew upgrade neovim` → 0.12.4 | agent | [x] |
| 3 | `nvf` → `:Lazy update` `:TSUpdate` | agent | [x] |
| 4 | `:checkhealth` clean enough to work | agent | [x] |
| 5 | Smoke tests (Aerial, DAP, LSP, terminal) | agent | [x] |
| 6 | Commit nvf changes + updated `lazy-lock.json` | | [ ] |

## Execution log (2026-07-11)

- **Neovim:** upgraded `0.11.5 → 0.12.4` (Homebrew), deps bumped (tree-sitter
  `0.25.10 → 0.26.10`, luajit, libuv, luv, utf8proc).
- **Plugins:** `:Lazy update` completed; `nvim-treesitter` now tracks **main**
  and parsers updated via `require('nvim-treesitter').update()`.
- **DAP fix:** replaced inline `sign_define` loop with idempotent
  `define_dap_signs()`; verified `DapBreakpoint` sign defined on 0.12.
- **jsonc parser:** `json.lua` `ensure_installed` changed `jsonc → json`. On the
  treesitter main branch there is no separate `jsonc` parser; Neovim maps the
  `jsonc` filetype to the `json` language (verified `parser_lang=json` on a
  `.json`/jsonc buffer). This removes the `Parser not available for language
  "jsonc"` warning during `:TSUpdate`. (A leftover `jsonc` parser from the old
  master install remains on disk but is unused and harmless.)
- **Smoke tests (headless):**
  - `AerialToggle` present after opening a file, runs with **no** treesitter
    backend errors (the 0.11 failure mode is resolved).
  - `aerial` and `dap` modules require cleanly on 0.12.
  - Native `:!`/shell path works; jsonc highlighting works.
- **Known pre-existing noise (not upgrade-related):** `mcphub.nvim` logs
  `mcp-hub executable not found` at startup because the global `mcp-hub` npm
  package is not installed. Unrelated to 0.12; install with
  `npm install -g mcp-hub@latest` if you want MCP.
- **Interactive re-checks recommended in a real GUI/cmux session:** DAP
  breakpoint + continue on a Node/Go launch, LSP diagnostics/code actions,
  Avante/Cursor agent, Neotest.

---

## References

- `:help news-0.12` in Neovim 0.12
- [aerial.nvim 4.0.0 changelog](https://github.com/stevearc/aerial.nvim/blob/master/CHANGELOG.md) — drops Neovim &lt; 0.12
- [nvim-dap sign_define discussion](https://github.com/mfussenegger/nvim-dap/issues/1292)
- LazyVim treesitter pin: `lua/lazyvim/plugins/treesitter.lua` (`commit = …` when `nvim-0.12` absent)

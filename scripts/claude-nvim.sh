#!/usr/bin/env bash
# Claude Code CLI launcher used by lua/plugins/ai-claudecode.lua.
#
# Neovim may have inherited ANTHROPIC_API_KEY from project direnv; the CLI
# prefers that over the subscription login in $CLAUDE_CONFIG_DIR, silently
# switching to pay-per-token billing. Strip it unless explicitly opted in.
# (`env -u` would do the same, but claudecode.nvim's :checkhealth probes the
# first word of terminal_cmd with --version, so keep a real executable here.)
if [ "${CLAUDECODE_NVIM_USE_API_KEY:-0}" != "1" ]; then
  unset ANTHROPIC_API_KEY
fi
exec claude "$@"

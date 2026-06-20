#!/usr/bin/env bash
# Run Neovim with this config (lazy-fullstack) in diagnostic mode.
# Uses NVIM_APPNAME so only this config is targeted.
#
# Usage: ./scripts/nvim-diag.sh [nvim-args...]
# Example: ./scripts/nvim-diag.sh --headless -c "messages" -c "quit"
# Example: ./scripts/nvim-diag.sh   # interactive with verbose log

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export XDG_CONFIG_HOME="${REPO_ROOT%/*}"
export NVIM_APPNAME="${REPO_ROOT##*/}"
LOG="${TMPDIR:-/tmp}/nvim-${NVIM_APPNAME}-diag.log"

echo "Config: XDG_CONFIG_HOME=$XDG_CONFIG_HOME NVIM_APPNAME=$NVIM_APPNAME"
echo "Log: $LOG"
echo "---"

if [ $# -gt 0 ]; then
  exec env XDG_CONFIG_HOME="$XDG_CONFIG_HOME" NVIM_APPNAME="$NVIM_APPNAME" \
    nvim -V3 "-V2logfile$LOG" "$@" 2>&1 | tee -a "$LOG"
else
  exec env XDG_CONFIG_HOME="$XDG_CONFIG_HOME" NVIM_APPNAME="$NVIM_APPNAME" \
    nvim -V3 "-V2logfile$LOG" 2>&1 | tee -a "$LOG"
fi

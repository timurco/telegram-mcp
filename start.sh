#!/usr/bin/env bash
# launchd entrypoint for telegram-mcp.
# Runs the always-on streamable-HTTP daemon. Only one instance per port —
# if something is already listening on TELEGRAM_MCP_HTTP_PORT we exit 0 so
# launchd doesn't spin restarting us.
set -u

PORT="${TELEGRAM_MCP_HTTP_PORT:-47821}"
# Which checkout to run: this script's own directory, or TELEGRAM_MCP_DIR
# when the daemon should run a different one (an update staged elsewhere).
PROJECT_DIR="${TELEGRAM_MCP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
UV_BIN="${UV_BIN:-$(command -v uv || printf '%s' "$HOME/.local/bin/uv")}"

# If a daemon is already bound to the port (e.g. previous launchd cycle, or
# a manual run), exit gracefully so launchd's KeepAlive doesn't loop-crash us.
if command -v lsof >/dev/null 2>&1; then
  EXISTING_PID=$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null | head -n1 || true)
  if [ -n "$EXISTING_PID" ] && [ "$EXISTING_PID" != "$$" ]; then
    echo "[telegram-mcp] port $PORT already held by pid $EXISTING_PID, exiting." >&2
    exit 0
  fi
fi

exec "$UV_BIN" --directory "$PROJECT_DIR" run main.py

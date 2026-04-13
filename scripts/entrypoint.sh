#!/bin/sh
set -eu

PORT="${MCP_PORT:-8000}"
OUTPUT_TRANSPORT="${MCP_OUTPUT_TRANSPORT:-streamableHttp}"
STREAMABLE_HTTP_PATH="${MCP_STREAMABLE_HTTP_PATH:-/mcp}"
SESSION_TIMEOUT="${MCP_SESSION_TIMEOUT:-60000}"
LOG_LEVEL="${MCP_LOG_LEVEL:-info}"

stdio_cmd='github-mcp-server stdio'

set -- supergateway   --stdio "$stdio_cmd"   --outputTransport "$OUTPUT_TRANSPORT"   --port "$PORT"   --streamableHttpPath "$STREAMABLE_HTTP_PATH"   --healthEndpoint /healthz   --logLevel "$LOG_LEVEL"

if [ "${MCP_STATEFUL:-1}" = "1" ]; then
  set -- "$@" --stateful --sessionTimeout "$SESSION_TIMEOUT"
fi

if [ -n "${MCP_CORS:-}" ]; then
  if [ "$MCP_CORS" = "*" ]; then
    set -- "$@" --cors
  else
    OLD_IFS="$IFS"
    IFS=','
    for origin in $MCP_CORS; do
      set -- "$@" --cors "$origin"
    done
    IFS="$OLD_IFS"
  fi
fi

if [ -n "${MCP_EXTRA_ARGS:-}" ]; then
  # shellcheck disable=SC2086
  set -- "$@" ${MCP_EXTRA_ARGS}
fi

exec "$@"

#!/bin/sh
set -eu

PORT="${MCP_PORT:-8000}"
INNER_PORT="${MCP_INNER_PORT:-8001}"
OUTPUT_TRANSPORT="${MCP_OUTPUT_TRANSPORT:-streamableHttp}"
STREAMABLE_HTTP_PATH="${MCP_STREAMABLE_HTTP_PATH:-/mcp}"
SESSION_TIMEOUT="${MCP_SESSION_TIMEOUT:-60000}"
LOG_LEVEL="${MCP_LOG_LEVEL:-info}"

stdio_cmd='github-mcp-server stdio'

# Supergateway listens on the inner port; the proxy (PID 1) listens on $PORT.
set -- supergateway   --stdio "$stdio_cmd"   --outputTransport "$OUTPUT_TRANSPORT"   --port "$INNER_PORT"   --streamableHttpPath "$STREAMABLE_HTTP_PATH"   --healthEndpoint /healthz   --logLevel "$LOG_LEVEL"

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

# Start supergateway in the background on the inner port.
"$@" &

# Become PID 1: proxy handles OAuth stubs and forwards everything else.
exec node /app/proxy.js

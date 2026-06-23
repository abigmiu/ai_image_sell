#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$ROOT_DIR/.dev-run"
mkdir -p "$RUN_DIR"

BACKEND_PID=""
SUB2API_FRONTEND_PID=""
PLAYGROUND_PID=""

cleanup() {
  for pid in "$PLAYGROUND_PID" "$SUB2API_FRONTEND_PID" "$BACKEND_PID"; do
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
}

trap cleanup EXIT INT TERM

(
  cd "$ROOT_DIR/sub2api/backend"
  DATA_DIR=../.localdata SERVER_PORT=8080 SERVER_MODE=release TZ=Asia/Shanghai go run ./cmd/server
) >"$RUN_DIR/sub2api-backend.log" 2>&1 &
BACKEND_PID=$!

(
  cd "$ROOT_DIR/sub2api/frontend"
  VITE_DEV_PROXY_TARGET=http://127.0.0.1:8080 VITE_DEV_PORT=3000 pnpm dev
) >"$RUN_DIR/sub2api-frontend.log" 2>&1 &
SUB2API_FRONTEND_PID=$!

(
  cd "$ROOT_DIR/gpt_image_playground"
  npm run dev
) >"$RUN_DIR/gpt-image-playground.log" 2>&1 &
PLAYGROUND_PID=$!

cat <<EOF
sub2api backend:    http://127.0.0.1:8080
sub2api frontend:   http://127.0.0.1:3000
gpt_image_playground: http://127.0.0.1:5811

logs:
  $RUN_DIR/sub2api-backend.log
  $RUN_DIR/sub2api-frontend.log
  $RUN_DIR/gpt-image-playground.log

press Ctrl+C to stop all processes
EOF

wait "$BACKEND_PID" "$SUB2API_FRONTEND_PID" "$PLAYGROUND_PID"

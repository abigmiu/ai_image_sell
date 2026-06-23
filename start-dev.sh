#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$ROOT_DIR/.dev-run"
mkdir -p "$RUN_DIR"

BACKEND_PID=""
SUB2API_FRONTEND_PID=""
PLAYGROUND_PID=""

require_port_free() {
  local port="$1"
  local name="$2"
  local pid
  pid="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  if [ -n "$pid" ]; then
    echo "[start-dev] ${name} 启动失败：端口 ${port} 已被占用（PID: ${pid}）" >&2
    exit 1
  fi
}

wait_for_service() {
  local name="$1"
  local url="$2"
  local pid="$3"
  local log_file="$4"
  local attempt=0

  while [ "$attempt" -lt 60 ]; do
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "[start-dev] ${name} 进程提前退出，最近日志如下：" >&2
      tail -n 80 "$log_file" >&2 || true
      exit 1
    fi

    local status
    status="$(curl -sS -o /dev/null -w "%{http_code}" "$url" || true)"
    if [ "$status" != "000" ]; then
      return 0
    fi

    sleep 0.5
    attempt=$((attempt + 1))
  done

  echo "[start-dev] ${name} 启动超时，最近日志如下：" >&2
  tail -n 80 "$log_file" >&2 || true
  exit 1
}

cleanup() {
  for pid in "$PLAYGROUND_PID" "$SUB2API_FRONTEND_PID" "$BACKEND_PID"; do
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
}

trap cleanup EXIT INT TERM

require_port_free 8080 "sub2api backend"
require_port_free 3000 "sub2api frontend"
require_port_free 5811 "gpt_image_playground"

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

wait_for_service "sub2api backend" "http://127.0.0.1:8080/api/v1/settings/public" "$BACKEND_PID" "$RUN_DIR/sub2api-backend.log"
wait_for_service "sub2api frontend" "http://127.0.0.1:3000" "$SUB2API_FRONTEND_PID" "$RUN_DIR/sub2api-frontend.log"
wait_for_service "gpt_image_playground" "http://127.0.0.1:5811" "$PLAYGROUND_PID" "$RUN_DIR/gpt-image-playground.log"

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

#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[1/2] updating sub2api"
git -C "$ROOT_DIR/sub2api" pull --ff-only

echo "[2/2] updating gpt_image_playground"
git -C "$ROOT_DIR/gpt_image_playground" pull --ff-only

echo "done"

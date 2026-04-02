#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd cargo

cd "$ROOT_DIR"

echo "Running native workspace build..."
cargo build --locked --workspace

echo "Running wasm32-wasip1 workspace build..."
cargo build --locked --workspace --target wasm32-wasip1

echo "Build checks completed successfully."

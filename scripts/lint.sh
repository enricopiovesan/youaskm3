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
require_cmd npm

cd "$ROOT_DIR"

echo "Checking Rust formatting..."
cargo fmt --check

echo "Running clippy with warnings denied..."
cargo clippy --workspace --all-targets -- -D warnings

echo "Running ESLint..."
npm run lint

echo "Lint checks completed successfully."

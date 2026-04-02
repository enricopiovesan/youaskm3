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
require_cmd cargo-llvm-cov

cd "$ROOT_DIR"

PACKAGES=(
  "youaskm3-core"
  "youaskm3-ingest"
  "youaskm3-search"
)

echo "Running locked Rust tests..."
cargo test --locked

echo "Generating coverage report for business logic crates..."
for package in "${PACKAGES[@]}"; do
  cargo llvm-cov \
    --package "$package" \
    --locked \
    --summary-only
done

echo "Rust tests and coverage reporting completed successfully."

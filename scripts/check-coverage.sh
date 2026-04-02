#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES=(
  "youaskm3-core"
  "youaskm3-ingest"
  "youaskm3-search"
)

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd cargo
require_cmd cargo-llvm-cov

cd "$ROOT_DIR"

for package in "${PACKAGES[@]}"; do
  echo "Enforcing 100% line coverage for ${package}..."
  cargo llvm-cov \
    --package "$package" \
    --locked \
    --fail-under-lines 100 \
    --summary-only
done

echo "Business logic coverage target passed."

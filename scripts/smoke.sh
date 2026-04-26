#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_FILES=(
  "openspec/specs/knowledge-ingest/spec.md"
  "openspec/specs/knowledge-search/spec.md"
  "openspec/specs/mcp-interface/spec.md"
  "openspec/specs/federation/spec.md"
  "openspec/specs/pwa-shell/spec.md"
)

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

validate_openspec_file() {
  local path="$1"

  if ! grep -q '^## Purpose$' "$path"; then
    echo "OpenSpec validation failed: ${path} is missing a Purpose section." >&2
    exit 1
  fi

  if ! grep -q '^## Requirements$' "$path"; then
    echo "OpenSpec validation failed: ${path} is missing a Requirements section." >&2
    exit 1
  fi

  if ! grep -q '^#### Scenario:' "$path"; then
    echo "OpenSpec validation failed: ${path} is missing a Scenario block." >&2
    exit 1
  fi
}

require_cmd npm
require_cmd ruby

cd "$ROOT_DIR"

echo "Validating m3 init bootstrap..."
bash ./scripts/m3-init-smoke.sh

echo "Validating m3 add ingest routing..."
bash ./scripts/m3-add-smoke.sh

echo "Validating PWA shell assets..."
bash ./scripts/pwa-shell-smoke.sh

echo "Running lint checks..."
bash ./scripts/lint.sh

echo "Running build checks..."
bash ./scripts/build.sh

echo "Running Rust tests..."
bash ./scripts/test.sh

echo "Enforcing coverage..."
bash ./scripts/check-coverage.sh

echo "Running TypeScript typecheck..."
npm run typecheck

echo "Running frontend tests..."
npm test

echo "Validating GitHub workflow YAML..."
ruby -e 'require "yaml"; Dir.glob(".github/workflows/*.yml").sort.each { |path| YAML.load_file(path) }'

echo "Validating OpenSpec files..."
for spec_file in "${SPEC_FILES[@]}"; do
  validate_openspec_file "$spec_file"
done

echo "Smoke run completed successfully."

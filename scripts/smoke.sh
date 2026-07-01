#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_FILES=(
  "openspec/specs/knowledge-ingest/spec.md"
  "openspec/specs/knowledge-search/spec.md"
  "openspec/specs/knowledge-graph/spec.md"
  "openspec/specs/traverse-integration/spec.md"
  "openspec/specs/mcp-interface/spec.md"
  "openspec/specs/federation/spec.md"
  "openspec/specs/pwa-shell/spec.md"
  "openspec/specs/reasoning-assistant-skill/spec.md"
  "openspec/specs/decision-log-package/spec.md"
  "openspec/specs/reasoning-graph/spec.md"
  "openspec/specs/knowledge-gap-lifecycle/spec.md"
  "openspec/specs/local-runtime-sync/spec.md"
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

echo "Validating MarkItDown ingest routing..."
bash ./scripts/m3-markitdown-smoke.sh

echo "Validating PWA shell assets..."
bash ./scripts/pwa-shell-smoke.sh

echo "Running lint checks..."
bash ./scripts/lint.sh

echo "Running build checks..."
bash ./scripts/m3-build-smoke.sh

echo "Validating incremental sync..."
bash ./scripts/m3-sync-smoke.sh

echo "Validating sync preflight..."
bash ./scripts/sync-preflight-smoke.sh

echo "Validating m3 search and serve commands..."
bash ./scripts/m3-command-surface-smoke.sh

echo "Validating m3 serve runtime orchestration..."
bash ./scripts/m3-serve-runtime-smoke.sh

echo "Validating MVP contracts..."
bash ./scripts/mvp-contracts-smoke.sh

echo "Validating Traverse component manifests..."
bash ./scripts/traverse-component-manifests-smoke.sh

echo "Validating Traverse app registration command..."
bash ./scripts/register-traverse-app-smoke.sh

echo "Validating query answer workflow..."
bash ./scripts/query-answer-workflow-smoke.sh

echo "Validating Traverse answer workflow integration gate..."
bash ./scripts/traverse-answer-workflow-smoke.sh

echo "Validating Traverse MCP answer workflow parity..."
bash ./scripts/traverse-mcp-answer-workflow-smoke.sh

echo "Validating local runtime MCP parity..."
bash ./scripts/local-runtime-mcp-parity-smoke.sh

echo "Validating local inference policy..."
bash ./scripts/local-inference-policy-smoke.sh

echo "Validating MVP local product loop..."
bash ./scripts/mvp-local-loop-smoke.sh

echo "Validating MVP fixture corpus..."
bash ./scripts/mvp-fixture-corpus-smoke.sh

echo "Validating MVP graph artifact..."
bash ./scripts/mvp-graph-artifact-smoke.sh

echo "Validating reasoning skill adapter generation..."
bash ./scripts/reasoning-skill-adapters-smoke.sh

echo "Validating decision-log package contract..."
bash ./scripts/decision-log-package-smoke.sh

echo "Validating m3 decision-log package ingestion..."
bash ./scripts/m3-decision-log-ingest-smoke.sh

echo "Validating reasoning graph extraction..."
bash ./scripts/reasoning-graph-extraction-smoke.sh

echo "Validating knowledge gap lifecycle..."
bash ./scripts/knowledge-gap-lifecycle-smoke.sh

echo "Validating direct fact resolution..."
bash ./scripts/direct-fact-resolution-smoke.sh

echo "Validating answer context selection..."
bash ./scripts/answer-context-selector-smoke.sh

echo "Validating federation index generation..."
bash ./scripts/federation-index-smoke.sh

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

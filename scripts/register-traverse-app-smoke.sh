#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

json_file="$(mktemp "${TMPDIR:-/tmp}/youaskm3-register-traverse-app.XXXXXX")"
missing_traverse_dir="$(mktemp -d "${TMPDIR:-/tmp}/youaskm3-missing-traverse.XXXXXX")"
rmdir "$missing_traverse_dir"
trap 'rm -f "$json_file"; rm -rf "$missing_traverse_dir"' EXIT

bash scripts/register-traverse-app.sh --validate-only --json >"$json_file"

ruby -rjson -e '
payload = JSON.parse(File.read(ARGV.fetch(0)))
abort "expected validated status" unless payload.fetch("status") == "validated"
abort "expected validated code" unless payload.fetch("code") == "VALIDATED"
abort "expected youaskm3 app id" unless payload.dig("app", "app_id") == "youaskm3.knowledge-app"
abort "expected 7 components" unless payload.dig("app", "component_count") == 7
abort "expected 1 workflow" unless payload.dig("app", "workflow_count") == 1
abort "expected real WASM evidence" unless payload.dig("evidence", "missing_wasm_count") == 0
abort "expected real digest evidence" unless payload.dig("evidence", "zero_digest_component_count") == 0
' "$json_file"

set +e
TRAVERSE_REPO="$missing_traverse_dir" \
  bash scripts/register-traverse-app.sh --allow-skeleton --json >"$json_file"
status=$?
set -e

if [[ "$status" -ne 2 ]]; then
  echo "Expected missing Traverse checkout exit 2, got $status" >&2
  exit 1
fi

ruby -rjson -e '
payload = JSON.parse(File.read(ARGV.fetch(0)))
abort "expected missing Traverse checkout" unless payload.fetch("code") == "MISSING_TRAVERSE_CHECKOUT"
' "$json_file"

echo "Traverse app registration smoke passed."

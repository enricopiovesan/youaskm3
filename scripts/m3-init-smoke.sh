#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT_DIR"

bash ./scripts/m3-init.sh "$TEMP_DIR" \
  --name "Smoke Instance" \
  --shell-url "https://example.com/smoke/" \
  --instance-id "smoke-instance" \
  --active-provider "browser-demo" \
  --yes

[[ -f "$TEMP_DIR/app/site/author-instance.json" ]]
[[ -f "$TEMP_DIR/app/site/provider-config.json" ]]
[[ -f "$TEMP_DIR/.youaskm3/config.json" ]]
[[ -f "$TEMP_DIR/knowledge/index.md" ]]
[[ -f "$TEMP_DIR/knowledge/.youaskm3-knowledge-root.json" ]]
[[ -d "$TEMP_DIR/knowledge/inputs/articles" ]]
[[ -d "$TEMP_DIR/knowledge/inputs/transcripts" ]]

grep -q '"instanceId": "smoke-instance"' "$TEMP_DIR/app/site/author-instance.json"
grep -q '"title": "Smoke Instance"' "$TEMP_DIR/app/site/author-instance.json"
grep -q '"shellUrl": "https://example.com/smoke/"' "$TEMP_DIR/app/site/author-instance.json"
grep -q '"activeProviderId": "browser-demo"' "$TEMP_DIR/app/site/provider-config.json"
grep -q '"knowledge_root":' "$TEMP_DIR/.youaskm3/config.json"

EXTERNAL_ROOT="$TEMP_DIR/external-knowledge"
bash ./scripts/m3-init.sh "$TEMP_DIR/external-workspace" \
  --name "External Root Smoke" \
  --shell-url "https://example.com/external/" \
  --knowledge-root "$EXTERNAL_ROOT" \
  --offline \
  --yes

[[ -f "$EXTERNAL_ROOT/.youaskm3-knowledge-root.json" ]]
[[ -f "$TEMP_DIR/external-workspace/.youaskm3/config.json" ]]
grep -q '"offline": true' "$EXTERNAL_ROOT/.youaskm3-knowledge-root.json"
grep -q '"status": "unavailable"' "$TEMP_DIR/external-workspace/.youaskm3/config.json"

if bash ./scripts/m3-init.sh "$TEMP_DIR/invalid-traverse" \
  --name "Invalid Traverse" \
  --shell-url "https://example.com/invalid/" \
  --traverse-repo "$TEMP_DIR/missing-traverse" \
  --yes >/tmp/m3-init-invalid-traverse.out 2>/tmp/m3-init-invalid-traverse.err; then
  echo "Expected missing Traverse repo to fail." >&2
  exit 1
fi
grep -q 'TRAVERSE_REPO_UNAVAILABLE' /tmp/m3-init-invalid-traverse.err

echo "m3 init smoke passed."

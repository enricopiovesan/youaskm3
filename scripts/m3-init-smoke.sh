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
[[ -f "$TEMP_DIR/knowledge/index.md" ]]
[[ -d "$TEMP_DIR/knowledge/inputs/articles" ]]
[[ -d "$TEMP_DIR/knowledge/inputs/transcripts" ]]

grep -q '"instanceId": "smoke-instance"' "$TEMP_DIR/app/site/author-instance.json"
grep -q '"title": "Smoke Instance"' "$TEMP_DIR/app/site/author-instance.json"
grep -q '"shellUrl": "https://example.com/smoke/"' "$TEMP_DIR/app/site/author-instance.json"
grep -q '"activeProviderId": "browser-demo"' "$TEMP_DIR/app/site/provider-config.json"

echo "m3 init smoke passed."

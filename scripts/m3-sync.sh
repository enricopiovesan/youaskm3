#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$ROOT_DIR/app/site"
SYNC_STATE_FILE="$SITE_DIR/sync-state.json"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd ruby

cd "$ROOT_DIR"

if [[ ! -f "$SITE_DIR/author-instance.json" ]]; then
  echo "Missing required file: app/site/author-instance.json" >&2
  echo "Run ./scripts/m3.sh init before trying to sync a new instance." >&2
  exit 1
fi

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

ruby ./scripts/generate-site-artifacts.rb "$temp_dir"

if [[ -f "$SYNC_STATE_FILE" ]] && cmp -s "$temp_dir/sync-state.json" "$SYNC_STATE_FILE"; then
  echo "No knowledge or instance metadata changes detected; static artifacts are already up to date."
  exit 0
fi

cp "$temp_dir/search-index.json" "$SITE_DIR/search-index.json"
cp "$temp_dir/build-manifest.json" "$SITE_DIR/build-manifest.json"
cp "$temp_dir/sync-state.json" "$SITE_DIR/sync-state.json"

echo "Detected source changes; refreshed static artifacts."
echo "- app/site/search-index.json"
echo "- app/site/build-manifest.json"
echo "- app/site/sync-state.json"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/instance-a" "$TEMP_DIR/instance-b" "$TEMP_DIR/out"

cat <<EOF > "$TEMP_DIR/instance-a/search-index.json"
{
  "instanceId": "instance-a",
  "title": "Instance A",
  "shellUrl": "https://instance-a.example/",
  "documents": [
    {
      "id": "paper-a",
      "title": "Paper A",
      "source_path": "knowledge/papers/paper-a/index.md",
      "category": "papers",
      "excerpt": "Distributed systems notes."
    }
  ]
}
EOF

cat <<EOF > "$TEMP_DIR/instance-b/search-index.json"
{
  "instanceId": "instance-b",
  "title": "Instance B",
  "shellUrl": "https://instance-b.example/",
  "documents": [
    {
      "id": "blog-b",
      "title": "Blog B",
      "source_path": "knowledge/blog/blog-b.md",
      "category": "blog",
      "excerpt": "WASM field notes."
    }
  ]
}
EOF

cat <<EOF > "$TEMP_DIR/instances.json"
{
  "registry_repository": "https://github.com/youaskm3/registry",
  "instances": [
    {
      "name": "Instance A",
      "url": "https://instance-a.example/",
      "search_index_url": "file://$TEMP_DIR/instance-a/search-index.json",
      "description": "Systems writing.",
      "topics": ["systems"],
      "since": "2026-04-01"
    },
    {
      "name": "Instance B",
      "url": "https://instance-b.example/",
      "search_index_url": "file://$TEMP_DIR/instance-b/search-index.json",
      "description": "WASM writing.",
      "topics": ["wasm"],
      "since": "2026-04-02"
    }
  ]
}
EOF

ruby "$ROOT_DIR/scripts/generate-federation-index.rb" \
  "$TEMP_DIR/instances.json" \
  "$TEMP_DIR/out"

[[ -f "$TEMP_DIR/out/federation-search-index.json" ]]
[[ -f "$TEMP_DIR/out/federation-index-manifest.json" ]]

grep -q '"instanceCount": 2' "$TEMP_DIR/out/federation-search-index.json"
grep -q '"documentCount": 2' "$TEMP_DIR/out/federation-search-index.json"
grep -q '"instanceName": "Instance A"' "$TEMP_DIR/out/federation-search-index.json"
grep -q '"instanceName": "Instance B"' "$TEMP_DIR/out/federation-search-index.json"
grep -q '"searchIndexUrl": "file://' "$TEMP_DIR/out/federation-index-manifest.json"

echo "Federation index smoke passed."

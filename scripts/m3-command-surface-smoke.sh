#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/app/site" "$TEMP_DIR/scripts"

cp "$ROOT_DIR/scripts/m3.sh" "$TEMP_DIR/scripts/m3.sh"
cp "$ROOT_DIR/scripts/m3-search.rb" "$TEMP_DIR/scripts/m3-search.rb"
cp "$ROOT_DIR/scripts/m3-serve.sh" "$TEMP_DIR/scripts/m3-serve.sh"
cp "$ROOT_DIR/scripts/m3-local-runtime.rb" "$TEMP_DIR/scripts/m3-local-runtime.rb"

cat <<'EOF' > "$TEMP_DIR/app/site/index.html"
<!doctype html>
<title>youaskm3 smoke</title>
EOF

cat <<'EOF' > "$TEMP_DIR/app/site/search-index.json"
{
  "instanceId": "smoke",
  "title": "Smoke instance",
  "shellUrl": "https://example.com/",
  "sourceFingerprint": "abc123",
  "documents": [
    {
      "id": "portable-knowledge",
      "title": "Portable Knowledge",
      "category": "blog",
      "excerpt": "Git-native context remains queryable from local commands.",
      "source_path": "knowledge/blog/portable-knowledge.md"
    },
    {
      "id": "other-note",
      "title": "Other Note",
      "category": "papers",
      "excerpt": "Unrelated material.",
      "source_path": "knowledge/papers/other-note/index.md"
    }
  ]
}
EOF

search_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh search portable
)"

grep -q "Portable Knowledge" <<<"$search_output"
grep -q "knowledge/blog/portable-knowledge.md" <<<"$search_output"

empty_search_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh search nonexistent
)"

grep -q "No search results for: nonexistent" <<<"$empty_search_output"

serve_help_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh serve --help
)"

grep -q "Usage: ./scripts/m3.sh serve \\[port\\]" <<<"$serve_help_output"
grep -q "serve --runtime" <<<"$serve_help_output"

echo "m3 command surface smoke passed."

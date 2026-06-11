#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
INPUT_HTML="$TMP_DIR/portable-knowledge.html"
EXPECTED_OUTPUT="$ROOT_DIR/knowledge/inputs/notes/portable-knowledge.md"

cleanup() {
  rm -rf "$TMP_DIR"
  rm -f "$EXPECTED_OUTPUT"
}

trap cleanup EXIT

cat >"$INPUT_HTML" <<'EOF'
<!doctype html>
<html lang="en">
  <body>
    <h1>Portable Knowledge</h1>
    <p>Hello <strong>world</strong>.</p>
  </body>
</html>
EOF

bash "$ROOT_DIR/scripts/m3.sh" add "$INPUT_HTML"

[[ -f "$EXPECTED_OUTPUT" ]]
grep -q '^# portable knowledge$' "$EXPECTED_OUTPUT"
grep -q '^- type: file$' "$EXPECTED_OUTPUT"
grep -q '^- format: html$' "$EXPECTED_OUTPUT"
grep -q '^- ingested_by: `markitdown2m3`$' "$EXPECTED_OUTPUT"
grep -q 'Portable Knowledge' "$EXPECTED_OUTPUT"
grep -q 'Hello' "$EXPECTED_OUTPUT"

echo "m3 MarkItDown smoke passed."

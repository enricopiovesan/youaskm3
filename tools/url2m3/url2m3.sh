#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
  echo "Usage: tools/url2m3/url2m3.sh <url> <output.md> [title]" >&2
  exit 1
fi

require_cmd cargo
require_cmd curl

SOURCE_URL="$1"
OUTPUT_MD="$2"
TITLE="${3:-}"
TEMP_TEXT="$(mktemp)"
trap 'rm -f "$TEMP_TEXT"' EXIT

cd "$ROOT_DIR"

curl -LsS "$SOURCE_URL" > "$TEMP_TEXT"

if [[ -n "$TITLE" ]]; then
  cargo run --quiet -p youaskm3-ingest --example url2m3 -- "$TEMP_TEXT" "$OUTPUT_MD" "$SOURCE_URL" "$TITLE"
else
  cargo run --quiet -p youaskm3-ingest --example url2m3 -- "$TEMP_TEXT" "$OUTPUT_MD" "$SOURCE_URL"
fi

echo "Generated markdown artifact at ${OUTPUT_MD}"

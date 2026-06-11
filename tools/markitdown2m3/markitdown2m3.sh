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
  echo "Usage: tools/markitdown2m3/markitdown2m3.sh <input-file> <output.md> [title]" >&2
  exit 1
fi

require_cmd cargo
require_cmd python3

INPUT_FILE="$1"
OUTPUT_MD="$2"
TITLE="${3:-}"
SOURCE_NAME="${INPUT_FILE##*/}"
SOURCE_FORMAT="${SOURCE_NAME##*.}"
TEMP_MARKDOWN="$(mktemp)"
trap 'rm -f "$TEMP_MARKDOWN"' EXIT

if [[ "$SOURCE_FORMAT" == "$SOURCE_NAME" ]]; then
  echo "MarkItDown ingest requires a file with a supported extension." >&2
  exit 1
fi

MARKITDOWN_BIN="$(bash "$ROOT_DIR/scripts/setup-markitdown.sh")"

cd "$ROOT_DIR"

"$MARKITDOWN_BIN" "$INPUT_FILE" -o "$TEMP_MARKDOWN"

if [[ -n "$TITLE" ]]; then
  cargo run --quiet -p youaskm3-ingest --example markitdown2m3 -- \
    "$TEMP_MARKDOWN" \
    "$OUTPUT_MD" \
    "$INPUT_FILE" \
    "$SOURCE_FORMAT" \
    "$TITLE"
else
  cargo run --quiet -p youaskm3-ingest --example markitdown2m3 -- \
    "$TEMP_MARKDOWN" \
    "$OUTPUT_MD" \
    "$INPUT_FILE" \
    "$SOURCE_FORMAT"
fi

echo "Generated markdown artifact at ${OUTPUT_MD}"

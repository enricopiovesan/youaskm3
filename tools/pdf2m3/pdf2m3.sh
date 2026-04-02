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
  echo "Usage: tools/pdf2m3/pdf2m3.sh <input.pdf> <output.md> [source-label]" >&2
  exit 1
fi

require_cmd cargo
require_cmd pdftotext

INPUT_PDF="$1"
OUTPUT_MD="$2"
SOURCE_LABEL="${3:-$INPUT_PDF}"
TEMP_TEXT="$(mktemp)"
trap 'rm -f "$TEMP_TEXT"' EXIT

cd "$ROOT_DIR"

pdftotext "$INPUT_PDF" "$TEMP_TEXT"
cargo run --quiet -p youaskm3-ingest --example pdf2m3 -- "$TEMP_TEXT" "$OUTPUT_MD" "$SOURCE_LABEL"

echo "Generated markdown artifact at ${OUTPUT_MD}"

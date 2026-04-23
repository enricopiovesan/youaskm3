#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
FAKE_BIN_DIR="$TMP_DIR/fake-bin"
INPUT_PDF="$ROOT_DIR/ref/add-smoke-slice.pdf"
EXPECTED_OUTPUT="$ROOT_DIR/knowledge/papers/add-smoke-slice/index.md"
EXPECTED_MARKDOWN_FILE="$TMP_DIR/expected.md"

cleanup() {
  rm -rf "$TMP_DIR"
  rm -f "$EXPECTED_OUTPUT"
  rm -f "$INPUT_PDF"
  rmdir "$ROOT_DIR/knowledge/papers/add-smoke-slice" 2>/dev/null || true
}

trap cleanup EXIT

mkdir -p "$FAKE_BIN_DIR"

cat >"$FAKE_BIN_DIR/pdftotext" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cp "$1" "$2"
EOF

cat >"$FAKE_BIN_DIR/cargo" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

args=("$@")
for index in "${!args[@]}"; do
  if [[ "${args[$index]}" == "--" ]]; then
    text_path="${args[$((index + 1))]}"
    output_path="${args[$((index + 2))]}"
    source_path="${args[$((index + 3))]}"
    break
  fi
done

if [[ -z "${text_path:-}" || -z "${output_path:-}" || -z "${source_path:-}" ]]; then
  echo "cargo stub received unexpected arguments: $*" >&2
  exit 1
fi

title="${source_path##*/}"
title="${title%.pdf}"
mkdir -p "$(dirname "$output_path")"

{
  printf '# %s\n\n' "$title"
  printf '## Source\n\n'
  printf '%s\n' '- type: pdf'
  printf '%s\n' "- path: ${source_path}"
  printf '%s\n' '- ingested_by: `pdf2m3`'
  printf '\n## Extracted Text\n\n'
  cat "$text_path"
  printf '\n'
} >"$output_path"
EOF

chmod +x "$FAKE_BIN_DIR/pdftotext" "$FAKE_BIN_DIR/cargo"

printf 'Smoke input text.\n' >"$INPUT_PDF"

PATH="$FAKE_BIN_DIR:$PATH" bash "$ROOT_DIR/scripts/m3.sh" add "ref/add-smoke-slice.pdf"

if [[ ! -f "$EXPECTED_OUTPUT" ]]; then
  echo "m3 add smoke failed: expected output file was not created." >&2
  exit 1
fi

cat >"$EXPECTED_MARKDOWN_FILE" <<'EOF'
# add-smoke-slice

## Source

- type: pdf
- path: ref/add-smoke-slice.pdf
- ingested_by: `pdf2m3`

## Extracted Text

Smoke input text.

EOF

if ! diff -u "$EXPECTED_MARKDOWN_FILE" "$EXPECTED_OUTPUT"; then
  echo "m3 add smoke failed: output markdown did not match the routed ingest path." >&2
  exit 1
fi

echo "m3 add smoke passed."

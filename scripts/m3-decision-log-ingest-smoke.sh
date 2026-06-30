#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p \
  "$TEMP_DIR/app/site" \
  "$TEMP_DIR/knowledge/blog" \
  "$TEMP_DIR/knowledge/books" \
  "$TEMP_DIR/knowledge/papers" \
  "$TEMP_DIR/scripts" \
  "$TEMP_DIR/fixtures/decision-log-packages/valid" \
  "$TEMP_DIR/fixtures/decision-log-packages/invalid"

cp "$ROOT_DIR/app/site/author-instance.json" "$TEMP_DIR/app/site/author-instance.json"
cp "$ROOT_DIR/app/site/provider-config.json" "$TEMP_DIR/app/site/provider-config.json"
cp "$ROOT_DIR/scripts/m3.sh" "$TEMP_DIR/scripts/m3.sh"
cp "$ROOT_DIR/scripts/m3-sync.sh" "$TEMP_DIR/scripts/m3-sync.sh"
cp "$ROOT_DIR/scripts/generate-site-artifacts.rb" "$TEMP_DIR/scripts/generate-site-artifacts.rb"
cp "$ROOT_DIR/scripts/reasoning-graph-extractor.rb" "$TEMP_DIR/scripts/reasoning-graph-extractor.rb"
cp "$ROOT_DIR/scripts/validate-decision-log-package.rb" "$TEMP_DIR/scripts/validate-decision-log-package.rb"
cp "$ROOT_DIR/scripts/ingest-decision-log.rb" "$TEMP_DIR/scripts/ingest-decision-log.rb"
cp "$ROOT_DIR/scripts/knowledge-gap-lifecycle.rb" "$TEMP_DIR/scripts/knowledge-gap-lifecycle.rb"
cp -R "$ROOT_DIR/fixtures/decision-log-packages/valid/knowledge_addition" "$TEMP_DIR/fixtures/decision-log-packages/valid/knowledge_addition"
cp -R "$ROOT_DIR/fixtures/decision-log-packages/invalid/unsupported-note-claim" "$TEMP_DIR/fixtures/decision-log-packages/invalid/unsupported-note-claim"

(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync >/dev/null
)

ingest_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh ingest-decision-log fixtures/decision-log-packages/valid/knowledge_addition
)"

ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected accepted" unless data.fetch("status") == "accepted" && data.fetch("package_id") == "decision-log-20260629-portable-reasoning"' <<<"$ingest_output"

[[ -f "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260629-portable-reasoning/decision-log.md" ]]
[[ -f "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260629-portable-reasoning/ingestion-provenance.json" ]]
[[ -f "$TEMP_DIR/knowledge/notes/decision-logs/decision-log-20260629-portable-reasoning.md" ]]
grep -q '"original_import_path"' "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260629-portable-reasoning/ingestion-provenance.json"
grep -q 'source_package: knowledge/sources/decision-logs/decision-log-20260629-portable-reasoning' "$TEMP_DIR/knowledge/notes/decision-logs/decision-log-20260629-portable-reasoning.md"

(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync >/dev/null
)

mkdir -p "$TEMP_DIR/offline-knowledge"
printf '{"schema_version":"1.0.0","offline":true}\n' >"$TEMP_DIR/offline-knowledge/.youaskm3-knowledge-root.json"
offline_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh ingest-decision-log fixtures/decision-log-packages/valid/knowledge_addition --offline --knowledge-root "$TEMP_DIR/offline-knowledge"
)"

ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected staged offline" unless data.fetch("status") == "staged_offline" && data.fetch("knowledge_note_path").nil?' <<<"$offline_output"
[[ -f "$TEMP_DIR/offline-knowledge/sources/decision-logs/.staged/decision-log-20260629-portable-reasoning/ingestion-provenance.json" ]]
[[ ! -e "$TEMP_DIR/offline-knowledge/notes/decision-logs/decision-log-20260629-portable-reasoning.md" ]]

if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh ingest-decision-log fixtures/decision-log-packages/valid/knowledge_addition --knowledge-root "$TEMP_DIR/offline-knowledge" >/tmp/decision-log-offline-final.txt 2>&1
); then
  echo "Expected offline knowledge root to reject final ingestion." >&2
  exit 1
fi
grep -q 'OFFLINE_KNOWLEDGE_ROOT_REQUIRES_STAGING' /tmp/decision-log-offline-final.txt

if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh ingest-decision-log fixtures/decision-log-packages/invalid/unsupported-note-claim >/tmp/decision-log-invalid-ingest.txt 2>&1
); then
  echo "Expected invalid decision-log package to fail ingestion." >&2
  exit 1
fi
grep -q 'UNSUPPORTED_KNOWLEDGE_NOTE_CLAIM' /tmp/decision-log-invalid-ingest.txt
[[ -f "$TEMP_DIR/knowledge/gaps/open/gap-decision-log-20260629-unsupported-note-validation.md" ]]

if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh ingest-decision-log fixtures/decision-log-packages/valid/knowledge_addition --knowledge-root "$TEMP_DIR/external-knowledge" >/tmp/decision-log-external-root.txt 2>&1
); then
  echo "Expected uninitialized external knowledge root to fail." >&2
  exit 1
fi
grep -q 'EXTERNAL_KNOWLEDGE_ROOT_UNINITIALIZED' /tmp/decision-log-external-root.txt

if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh ingest-decision-log fixtures/decision-log-packages/invalid/archive.zip >/tmp/decision-log-archive-ingest.txt 2>&1
); then
  echo "Expected archive decision-log package to fail ingestion." >&2
  exit 1
fi
grep -q 'ARCHIVE_INPUT_UNSUPPORTED' /tmp/decision-log-archive-ingest.txt

echo "m3 decision-log ingest smoke passed."

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
  "$TEMP_DIR/fixtures/decision-log-packages/invalid" \
  "$TEMP_DIR/inbox"

cp "$ROOT_DIR/app/site/author-instance.json" "$TEMP_DIR/app/site/author-instance.json"
cp "$ROOT_DIR/app/site/provider-config.json" "$TEMP_DIR/app/site/provider-config.json"
cp "$ROOT_DIR/scripts/m3.sh" "$TEMP_DIR/scripts/m3.sh"
cp "$ROOT_DIR/scripts/m3-sync.sh" "$TEMP_DIR/scripts/m3-sync.sh"
cp "$ROOT_DIR/scripts/generate-site-artifacts.rb" "$TEMP_DIR/scripts/generate-site-artifacts.rb"
cp "$ROOT_DIR/scripts/reasoning-graph-extractor.rb" "$TEMP_DIR/scripts/reasoning-graph-extractor.rb"
cp "$ROOT_DIR/scripts/validate-decision-log-package.rb" "$TEMP_DIR/scripts/validate-decision-log-package.rb"
cp "$ROOT_DIR/scripts/ingest-decision-log.rb" "$TEMP_DIR/scripts/ingest-decision-log.rb"
cp "$ROOT_DIR/scripts/import-decision-log-package.rb" "$TEMP_DIR/scripts/import-decision-log-package.rb"
cp "$ROOT_DIR/scripts/sync-preflight.rb" "$TEMP_DIR/scripts/sync-preflight.rb"
cp "$ROOT_DIR/scripts/knowledge-gap-lifecycle.rb" "$TEMP_DIR/scripts/knowledge-gap-lifecycle.rb"
cp -R "$ROOT_DIR/fixtures/decision-log-packages/valid/knowledge_addition" "$TEMP_DIR/fixtures/decision-log-packages/valid/knowledge_addition"
cp -R "$ROOT_DIR/fixtures/decision-log-packages/invalid/unsupported-note-claim" "$TEMP_DIR/fixtures/decision-log-packages/invalid/unsupported-note-claim"

(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync >/dev/null
)

(
  cd "$TEMP_DIR/fixtures/decision-log-packages/valid"
  zip -qr "$TEMP_DIR/valid-package.zip" knowledge_addition
)

archive_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh import-decision-log archive "$TEMP_DIR/valid-package.zip"
)"

ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected archive ingestion" unless data.fetch("status") == "ingested" && data.fetch("package_id") == "decision-log-20260629-portable-reasoning"' <<<"$archive_output"
grep -q "$TEMP_DIR/valid-package.zip" "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260629-portable-reasoning/ingestion-provenance.json"

mkdir -p "$TEMP_DIR/offline-knowledge"
printf '{"schema_version":"1.0.0","offline":true}\n' >"$TEMP_DIR/offline-knowledge/.youaskm3-knowledge-root.json"
offline_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh import-decision-log archive "$TEMP_DIR/valid-package.zip" --offline --knowledge-root "$TEMP_DIR/offline-knowledge"
)"
ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected staged archive" unless data.fetch("status") == "staged"' <<<"$offline_output"
[[ -f "$TEMP_DIR/offline-knowledge/sources/decision-logs/.staged/decision-log-20260629-portable-reasoning/ingestion-provenance.json" ]]

(
  cd "$TEMP_DIR/fixtures/decision-log-packages/invalid"
  zip -qr "$TEMP_DIR/invalid-package.zip" unsupported-note-claim
)
if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh import-decision-log archive "$TEMP_DIR/invalid-package.zip" >/tmp/package-import-invalid.json
); then
  echo "Expected invalid archive import to fail before knowledge writes." >&2
  exit 1
fi
ruby -rjson -e 'data=JSON.parse(File.read("/tmp/package-import-invalid.json")); abort "expected rejected invalid archive" unless data.fetch("status") == "rejected" && data.fetch("error").fetch("code") == "UNSUPPORTED_KNOWLEDGE_NOTE_CLAIM"'
[[ ! -f "$TEMP_DIR/knowledge/gaps/open/gap-decision-log-20260629-unsupported-note-validation.md" ]]

mkdir -p "$TEMP_DIR/unsafe-archive/root"
printf 'bad\n' >"$TEMP_DIR/unsafe-archive/evil.txt"
(
  cd "$TEMP_DIR/unsafe-archive/root"
  zip -q "$TEMP_DIR/unsafe.zip" ../evil.txt
)
if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh import-decision-log archive "$TEMP_DIR/unsafe.zip" >/tmp/package-import-unsafe.json
); then
  echo "Expected unsafe archive import to fail." >&2
  exit 1
fi
ruby -rjson -e 'data=JSON.parse(File.read("/tmp/package-import-unsafe.json")); abort "expected unsafe path rejection" unless data.fetch("status") == "rejected" && data.fetch("error").fetch("code") == "ARCHIVE_UNSAFE_PATH"'
[[ ! -e "$TEMP_DIR/evil.txt" ]]

cp -R "$TEMP_DIR/fixtures/decision-log-packages/valid/knowledge_addition" "$TEMP_DIR/inbox/knowledge_addition"
cp "$TEMP_DIR/invalid-package.zip" "$TEMP_DIR/inbox/invalid-package.zip"
printf 'notes\n' >"$TEMP_DIR/inbox/readme.txt"
mkdir -p "$TEMP_DIR/inbox-offline-knowledge"
printf '{"schema_version":"1.0.0","offline":true}\n' >"$TEMP_DIR/inbox-offline-knowledge/.youaskm3-knowledge-root.json"
inbox_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh import-decision-log inbox "$TEMP_DIR/inbox" --offline --knowledge-root "$TEMP_DIR/inbox-offline-knowledge"
)"
ruby -rjson -e 'data=JSON.parse(STDIN.read); counts=data.fetch("counts"); abort "expected staged, rejected counts" unless counts.fetch("staged") == 1 && counts.fetch("rejected") == 2 && data.fetch("results").all? { |result| result.key?("result_path") }' <<<"$inbox_output"
[[ "$(find "$TEMP_DIR/inbox/.youaskm3-import-results" -type f | wc -l | tr -d ' ')" == "3" ]]

echo "Package import automation smoke passed."

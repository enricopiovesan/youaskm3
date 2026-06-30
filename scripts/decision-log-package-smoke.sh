#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="ruby ./scripts/validate-decision-log-package.rb"

cd "$ROOT_DIR"

for mode in knowledge_addition gap_resolution direct_fact_resolution conflict_resolution; do
  $VALIDATOR "fixtures/decision-log-packages/valid/${mode}" --semantic-validation unavailable \
    | ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected valid package" unless data.fetch("valid") && data.dig("validation", "semantic", "status") == "unavailable"'
done

$VALIDATOR fixtures/decision-log-packages/valid/knowledge_addition --semantic-validation passed \
  | ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected semantic pass" unless data.fetch("valid") && data.dig("validation", "semantic", "status") == "passed"'

if $VALIDATOR fixtures/decision-log-packages/valid/knowledge_addition --semantic-validation failed >/tmp/decision-log-semantic-failed.json; then
  echo "Expected semantic validation failure to exit non-zero." >&2
  exit 1
fi
ruby -rjson -e 'data=JSON.parse(File.read("/tmp/decision-log-semantic-failed.json")); abort "expected semantic gap creation" unless !data.fetch("valid") && data.fetch("gap_creation").fetch("reason") == "semantic_validation_failed"'

invalid_expectations=(
  "missing-file:MISSING_REQUIRED_FILE"
  "unsupported-mode:UNSUPPORTED_PACKAGE_MODE"
  "incomplete-sections:DECISION_SECTION_MISSING"
  "mismatched-id:PACKAGE_ID_MISMATCH"
  "unsupported-note-claim:UNSUPPORTED_KNOWLEDGE_NOTE_CLAIM"
)

for pair in "${invalid_expectations[@]}"; do
  fixture="${pair%%:*}"
  expected="${pair#*:}"
  output="/tmp/decision-log-${fixture}.json"
  if $VALIDATOR "fixtures/decision-log-packages/invalid/${fixture}" >"$output"; then
    echo "Expected invalid fixture to fail: ${fixture}" >&2
    exit 1
  fi
  ruby -rjson -e 'data=JSON.parse(File.read(ARGV[0])); expected=ARGV[1]; codes=data.fetch("errors").map { |error| error.fetch("code") }; abort "missing expected error #{expected}: #{codes.inspect}" unless codes.include?(expected)' "$output" "$expected"
done

if $VALIDATOR fixtures/decision-log-packages/invalid/archive.zip >/tmp/decision-log-archive.json; then
  echo "Expected archive input to fail." >&2
  exit 1
fi
ruby -rjson -e 'data=JSON.parse(File.read("/tmp/decision-log-archive.json")); codes=data.fetch("errors").map { |error| error.fetch("code") }; abort "missing archive rejection" unless codes.include?("ARCHIVE_INPUT_UNSUPPORTED")'

echo "Decision-log package smoke passed."

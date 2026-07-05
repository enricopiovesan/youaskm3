#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT_DIR"

KNOWLEDGE_ROOT="$TEMP_DIR/knowledge"
mkdir -p "$KNOWLEDGE_ROOT"
printf '{"schema_version":"1.0.0","offline":true}\n' >"$KNOWLEDGE_ROOT/.youaskm3-knowledge-root.json"

cat >"$TEMP_DIR/reports.json" <<'JSON'
{
  "reports": [
    {
      "report_id": "gap_public_001",
      "collector_id": "collector-smoke",
      "status": "pending",
      "schema_version": "public-gap-report/0.1.0",
      "validation_version": "hosted-gap-collector/0.1.0",
      "question": "What does the public instance know about collector import?",
      "missing_knowledge": "No source-backed citation explains owner import of hosted gap reports.",
      "published_scope": "smoke-public-scope",
      "checked_evidence": ["search-index:0 results", "knowledge-graph:no matching node"],
      "source_url": "https://example.test/chat?q=collector-import",
      "submitted_at": "2026-07-05T12:00:00Z",
      "reporter_context": "Visitor expected CLI review."
    },
    {
      "report_id": "gap_public_002",
      "collector_id": "collector-smoke",
      "status": "pending",
      "schema_version": "public-gap-report/0.1.0",
      "validation_version": "hosted-gap-collector/0.1.0",
      "question": "Should this report be archived?",
      "missing_knowledge": "The visitor submitted a duplicate-looking gap.",
      "published_scope": "smoke-public-scope",
      "checked_evidence": ["manual review"],
      "source_url": "https://example.test/chat?q=archive",
      "submitted_at": "2026-07-05T12:05:00Z"
    }
  ]
}
JSON

list_output="$(bash ./scripts/m3.sh hosted-gaps list --knowledge-root "$KNOWLEDGE_ROOT" --collector-file "$TEMP_DIR/reports.json")"
ruby -rjson -e 'reports=JSON.parse(STDIN.read); abort "expected two reports" unless reports.length == 2; abort "missing review context" unless reports.first.fetch("checked_evidence").include?("search-index:0 results")' <<<"$list_output"

if bash ./scripts/m3.sh hosted-gaps import --knowledge-root "$KNOWLEDGE_ROOT" --collector-file "$TEMP_DIR/reports.json" --report-id gap_public_001 >/tmp/hosted-gap-import-no-accept.out 2>/tmp/hosted-gap-import-no-accept.err; then
  echo "Expected import without --accept to fail." >&2
  exit 1
fi
grep -q 'HOSTED_GAP_OWNER_IMPORT_FAILED' /tmp/hosted-gap-import-no-accept.err

import_output="$(bash ./scripts/m3.sh hosted-gaps import --knowledge-root "$KNOWLEDGE_ROOT" --collector-file "$TEMP_DIR/reports.json" --report-id gap_public_001 --accept)"
ruby -rjson -e 'result=JSON.parse(STDIN.read); abort "expected imported" unless result.fetch("status") == "imported"; abort "missing gap id" unless result.fetch("gap_id") == "gap-hosted-gap-public-001"' <<<"$import_output"

GAP_PATH="$KNOWLEDGE_ROOT/gaps/open/gap-hosted-gap-public-001.md"
[[ -f "$GAP_PATH" ]]
grep -q 'hosted_report_id: gap_public_001' "$GAP_PATH"
grep -q 'hosted_source_url: https://example.test/chat?q=collector-import' "$GAP_PATH"
grep -q 'hosted_published_scope: smoke-public-scope' "$GAP_PATH"
grep -q 'hosted_schema_version: public-gap-report/0.1.0' "$GAP_PATH"
grep -q 'hosted_validation_version: hosted-gap-collector/0.1.0' "$GAP_PATH"

if bash ./scripts/m3.sh hosted-gaps import --knowledge-root "$KNOWLEDGE_ROOT" --collector-file "$TEMP_DIR/reports.json" --report-id gap_public_001 --accept >/tmp/hosted-gap-duplicate.out 2>/tmp/hosted-gap-duplicate.err; then
  echo "Expected duplicate import to fail." >&2
  exit 1
fi
grep -q 'Hosted report already imported' /tmp/hosted-gap-duplicate.err

bash ./scripts/m3.sh hosted-gaps reject --knowledge-root "$KNOWLEDGE_ROOT" --collector-file "$TEMP_DIR/reports.json" --report-id gap_public_002 >/tmp/hosted-gap-reject.json
grep -q '"status": "reject"' /tmp/hosted-gap-reject.json

filtered_output="$(bash ./scripts/m3.sh hosted-gaps list --knowledge-root "$KNOWLEDGE_ROOT" --collector-file "$TEMP_DIR/reports.json")"
ruby -rjson -e 'reports=JSON.parse(STDIN.read); abort "expected rejected report filtered" unless reports.map { |r| r.fetch("report_id") } == ["gap_public_001"]' <<<"$filtered_output"

cat >"$TEMP_DIR/invalid-reports.json" <<'JSON'
{ "reports": [{ "report_id": "gap_bad", "status": "pending" }] }
JSON
if bash ./scripts/m3.sh hosted-gaps list --knowledge-root "$KNOWLEDGE_ROOT" --collector-file "$TEMP_DIR/invalid-reports.json" >/tmp/hosted-gap-invalid.out 2>/tmp/hosted-gap-invalid.err; then
  echo "Expected invalid remote payload to fail." >&2
  exit 1
fi
grep -q 'HOSTED_GAP_REPORT_INVALID' /tmp/hosted-gap-invalid.err

if bash ./scripts/m3.sh hosted-gaps list --knowledge-root "$KNOWLEDGE_ROOT" --collector-url 'http://127.0.0.1:9/reports' >/tmp/hosted-gap-unavailable.out 2>/tmp/hosted-gap-unavailable.err; then
  echo "Expected unavailable collector to fail." >&2
  exit 1
fi
grep -q 'HOSTED_GAP_OWNER_IMPORT_FAILED' /tmp/hosted-gap-unavailable.err

echo "Hosted gap reports smoke passed."

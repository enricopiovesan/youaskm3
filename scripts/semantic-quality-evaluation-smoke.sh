#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p \
  "$TEMP_DIR/knowledge" \
  "$TEMP_DIR/fixtures/decision-log-packages/valid" \
  "$TEMP_DIR/fixtures/semantic-quality/claim-validation" \
  "$TEMP_DIR/fixtures/semantic-quality/answer-benchmarks" \
  "$TEMP_DIR/scripts"

cp "$ROOT_DIR/scripts/semantic-quality-evaluation.rb" "$TEMP_DIR/scripts/semantic-quality-evaluation.rb"
cp "$ROOT_DIR/scripts/validate-decision-log-package.rb" "$TEMP_DIR/scripts/validate-decision-log-package.rb"
cp "$ROOT_DIR/scripts/knowledge-gap-lifecycle.rb" "$TEMP_DIR/scripts/knowledge-gap-lifecycle.rb"
cp -R "$ROOT_DIR/fixtures/decision-log-packages/valid/knowledge_addition" "$TEMP_DIR/fixtures/decision-log-packages/valid/knowledge_addition"
cp "$ROOT_DIR/fixtures/semantic-quality/claim-validation/partial.json" "$TEMP_DIR/fixtures/semantic-quality/claim-validation/partial.json"
cp "$ROOT_DIR/fixtures/semantic-quality/answer-benchmarks/basic.json" "$TEMP_DIR/fixtures/semantic-quality/answer-benchmarks/basic.json"

(
  cd "$TEMP_DIR"
  partial_output="$(ruby ./scripts/semantic-quality-evaluation.rb partial-ingest fixtures/decision-log-packages/valid/knowledge_addition fixtures/semantic-quality/claim-validation/partial.json --knowledge-root "$TEMP_DIR/knowledge")"
  ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected partial status" unless data.fetch("status") == "partial" && data.fetch("accepted_claim_count") == 1 && data.fetch("rejected_claim_count") == 1' <<<"$partial_output"
)

[[ -f "$TEMP_DIR/knowledge/claims/decision-log-20260629-portable-reasoning/claim-provenance-package.json" ]]
[[ -f "$TEMP_DIR/knowledge/gaps/open/gap-decision-log-20260629-portable-reasoning-claim-semantic-validation-order.md" ]]
[[ -f "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260629-portable-reasoning/claim-validation.json" ]]

ruby -rjson -e 'data=JSON.parse(File.read(ARGV[0])); abort "expected partial record" unless data.fetch("status") == "partial" && data.fetch("accepted_claims").length == 1 && data.fetch("rejected_claims").length == 1' \
  "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260629-portable-reasoning/claim-validation.json"

before_count="$(find "$TEMP_DIR/knowledge" -type f | wc -l | tr -d ' ')"
benchmark_output="$(
  cd "$TEMP_DIR"
  ruby ./scripts/semantic-quality-evaluation.rb benchmark fixtures/semantic-quality/answer-benchmarks/basic.json --report "$TEMP_DIR/benchmark-report.json"
)"
after_count="$(find "$TEMP_DIR/knowledge" -type f | wc -l | tr -d ' ')"
[[ "$before_count" == "$after_count" ]]
[[ -f "$TEMP_DIR/benchmark-report.json" ]]

ruby -rjson -e 'data=JSON.parse(STDIN.read); metrics=data.fetch("metrics"); abort "expected non-mutating report" unless data.fetch("mutates_knowledge") == false && data.fetch("case_count") == 3 && metrics.fetch("grounded_answer_rate") > 0 && metrics.fetch("unsupported_claim_rate") > 0 && metrics.fetch("conflict_disclosure_rate") > 0 && metrics.fetch("gap_behavior_rate") > 0 && metrics.fetch("provenance_completeness_rate") > 0' <<<"$benchmark_output"

echo "Semantic quality evaluation smoke passed."

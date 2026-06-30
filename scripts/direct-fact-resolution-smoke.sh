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
  "$TEMP_DIR/scripts"

cp "$ROOT_DIR/app/site/author-instance.json" "$TEMP_DIR/app/site/author-instance.json"
cp "$ROOT_DIR/app/site/provider-config.json" "$TEMP_DIR/app/site/provider-config.json"
cp "$ROOT_DIR/scripts/m3.sh" "$TEMP_DIR/scripts/m3.sh"
cp "$ROOT_DIR/scripts/m3-sync.sh" "$TEMP_DIR/scripts/m3-sync.sh"
cp "$ROOT_DIR/scripts/generate-site-artifacts.rb" "$TEMP_DIR/scripts/generate-site-artifacts.rb"
cp "$ROOT_DIR/scripts/reasoning-graph-extractor.rb" "$TEMP_DIR/scripts/reasoning-graph-extractor.rb"
cp "$ROOT_DIR/scripts/validate-decision-log-package.rb" "$TEMP_DIR/scripts/validate-decision-log-package.rb"
cp "$ROOT_DIR/scripts/ingest-decision-log.rb" "$TEMP_DIR/scripts/ingest-decision-log.rb"
cp "$ROOT_DIR/scripts/knowledge-gap-lifecycle.rb" "$TEMP_DIR/scripts/knowledge-gap-lifecycle.rb"
cp "$ROOT_DIR/scripts/resolve-direct-fact-gap.rb" "$TEMP_DIR/scripts/resolve-direct-fact-gap.rb"

(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync >/dev/null
)

ruby "$TEMP_DIR/scripts/knowledge-gap-lifecycle.rb" create-gap \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --gap-id gap-author-name \
  --source-question "What is the author name?" \
  --confidence-reason "missing simple fact" \
  --trace-id trace-direct-fact \
  --deterministic-complexity simple_factual >/tmp/direct-fact-gap-create.json

resolve_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh gaps resolve-fact gap-author-name \
    --answer "The author name is Enrico Piovesan." \
    --package-id decision-log-20260630-gap-author-name-direct-fact
)"

ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected direct fact resolved" unless data.fetch("status") == "direct_fact_resolved" && data.fetch("gap_id") == "gap-author-name" && data.fetch("package_id") == "decision-log-20260630-gap-author-name-direct-fact"' <<<"$resolve_output"

[[ -f "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260630-gap-author-name-direct-fact/decision-log.md" ]]
[[ -f "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260630-gap-author-name-direct-fact/ingestion-provenance.json" ]]
[[ -f "$TEMP_DIR/knowledge/notes/decision-logs/decision-log-20260630-gap-author-name-direct-fact.md" ]]
[[ -f "$TEMP_DIR/knowledge/gaps/resolved/gap-author-name.md" ]]
[[ ! -e "$TEMP_DIR/knowledge/gaps/open/gap-author-name.md" ]]

grep -q 'linked_package_id: decision-log-20260630-gap-author-name-direct-fact' "$TEMP_DIR/knowledge/gaps/resolved/gap-author-name.md"
grep -q '"mode": "direct_fact_resolution"' "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260630-gap-author-name-direct-fact/ingestion-provenance.json"

ruby -rjson -e 'graph=JSON.parse(File.read(ARGV[0])); abort "missing graph package provenance" unless graph.fetch("generated_from").include?("decision-log-20260630-gap-author-name-direct-fact"); labels=graph.fetch("nodes").map { |node| node.fetch("label") }; abort "missing direct fact claim node" unless labels.include?("The author name is Enrico Piovesan.")' "$TEMP_DIR/app/site/knowledge-graph.json"

ruby "$TEMP_DIR/scripts/knowledge-gap-lifecycle.rb" create-gap \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --gap-id gap-runtime-strategy \
  --source-question "What should the runtime strategy be?" \
  --confidence-reason "requires architecture tradeoff" \
  --trace-id trace-heavy \
  --deterministic-complexity reasoning_heavy >/tmp/direct-fact-heavy-gap.json

if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh gaps resolve-fact gap-runtime-strategy --answer "Use a shortcut." >/tmp/direct-fact-heavy-out.json 2>/tmp/direct-fact-heavy-err.txt
); then
  echo "Expected reasoning-heavy gap to reject direct fact resolution." >&2
  exit 1
fi
grep -q 'GAP_REQUIRES_DECISION_LOG_PACKAGE' /tmp/direct-fact-heavy-err.txt

if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh gaps resolve-fact gap-runtime-strategy --answer "" >/tmp/direct-fact-empty-out.json 2>/tmp/direct-fact-empty-err.txt
); then
  echo "Expected empty direct answer to fail." >&2
  exit 1
fi
grep -q 'DIRECT_FACT_ANSWER_REQUIRED' /tmp/direct-fact-empty-err.txt

echo "Direct fact resolution smoke passed."

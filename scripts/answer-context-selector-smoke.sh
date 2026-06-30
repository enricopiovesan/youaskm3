#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT_DIR"

ruby ./scripts/extract-reasoning-graph.rb fixtures/decision-log-packages/valid/gap_resolution >"$TEMP_DIR/reasoning-graph.json"

declare -a cases=(
  "List claim support for Traverse gaps:factual:claim,citation,source_artifact,validation_result"
  "Why was the downstream shortcut rejected?:decision:decision,tradeoff,option,assumption,citation,validation_result"
  "What remains uncertain about the runtime policy?:uncertainty:assumption,open_question,source_gap,confidence_assessment,validation_result"
  "Explain the Traverse runtime concept:concept_explanation:concept,claim,citation,knowledge_note"
  "What is still missing from me?:gap_oriented:source_gap,open_question,validation_result,knowledge_note"
)

for entry in "${cases[@]}"; do
  query="${entry%%:*}"
  rest="${entry#*:}"
  expected_type="${rest%%:*}"
  expected_nodes="${rest#*:}"
  ruby ./scripts/answer-context-selector.rb --query "$query" --graph "$TEMP_DIR/reasoning-graph.json" --knowledge-root "$TEMP_DIR/knowledge" \
    | ruby -rjson -e 'data=JSON.parse(STDIN.read); expected_type=ARGV[0]; expected_nodes=ARGV[1].split(","); trace=data.fetch("trace"); abort "wrong answer type" unless trace.fetch("deterministic_answer_type") == expected_type && trace.fetch("final_answer_type") == expected_type; abort "wrong node strategy" unless data.fetch("selected_node_types") == expected_nodes; abort "expected selected nodes" if data.fetch("selected_nodes").empty?' "$expected_type" "$expected_nodes"
done

ruby ./scripts/answer-context-selector.rb \
  --query "Explain the Traverse runtime concept" \
  --graph "$TEMP_DIR/reasoning-graph.json" \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --agent-answer-type uncertainty \
  | ruby -rjson -e 'data=JSON.parse(STDIN.read); trace=data.fetch("trace"); abort "expected agent override" unless trace.fetch("agent_answer_type") == "uncertainty" && trace.fetch("final_answer_type") == "uncertainty"'

ruby ./scripts/knowledge-gap-lifecycle.rb create-conflict \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --conflict-id conflict-runtime-shortcut \
  --summary "Downstream shortcuts conflict with Traverse governed runtime acceptance." >/dev/null

ruby ./scripts/answer-context-selector.rb \
  --query "Does a runtime shortcut conflict with MVP acceptance?" \
  --graph "$TEMP_DIR/reasoning-graph.json" \
  --knowledge-root "$TEMP_DIR/knowledge" \
  | ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected conflict evidence" if data.fetch("conflicts").empty?; abort "expected gap creation" unless data.fetch("gap_created").fetch("gap_id") == "gap-conflict-affects-answer"'

[[ -f "$TEMP_DIR/knowledge/gaps/open/gap-conflict-affects-answer.md" ]]

echo "Answer context selector smoke passed."

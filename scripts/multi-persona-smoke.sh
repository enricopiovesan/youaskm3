#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT_DIR"

ruby -rjson -e 'JSON.parse(File.read("contracts/persona-registry.schema.json")); JSON.parse(File.read("fixtures/multi-persona/personas.json")); JSON.parse(File.read("fixtures/multi-persona/graph.json"))'

research_output="$(
  ruby ./scripts/answer-context-selector.rb \
    --query "List claim support" \
    --graph fixtures/multi-persona/graph.json \
    --knowledge-root "$TEMP_DIR/knowledge" \
    --persona-registry fixtures/multi-persona/personas.json \
    --active-persona research
)"
ruby -rjson -e 'data=JSON.parse(STDIN.read); ids=data.fetch("selected_nodes").map { |node| node.fetch("node_id") }; trace=data.fetch("trace"); abort "expected research persona" unless trace.fetch("active_persona_id") == "research"; abort "expected private and shared research nodes only: #{ids.inspect}" unless ids.sort == ["research-claim", "shared-product-claim"]' <<<"$research_output"

personal_output="$(
  ruby ./scripts/answer-context-selector.rb \
    --query "List claim support" \
    --graph fixtures/multi-persona/graph.json \
    --knowledge-root "$TEMP_DIR/knowledge" \
    --persona-registry fixtures/multi-persona/personas.json \
    --active-persona personal
)"
ruby -rjson -e 'data=JSON.parse(STDIN.read); ids=data.fetch("selected_nodes").map { |node| node.fetch("node_id") }; abort "expected personal node only: #{ids.inspect}" unless ids == ["personal-claim"]' <<<"$personal_output"

ruby ./scripts/knowledge-gap-lifecycle.rb create-conflict \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --conflict-id conflict-shared-product \
  --persona-id research \
  --summary "Shared product scope conflicts with research persona assumptions." >/dev/null

conflict_output="$(
  ruby ./scripts/answer-context-selector.rb \
    --query "Does shared product conflict with research assumptions?" \
    --graph fixtures/multi-persona/graph.json \
    --knowledge-root "$TEMP_DIR/knowledge" \
    --persona-registry fixtures/multi-persona/personas.json \
    --active-persona research
)"
ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected persona conflict" unless data.fetch("conflicts").map { |conflict| conflict.fetch("conflict_id") }.include?("conflict-shared-product") && data.fetch("gap_created").fetch("gap_id") == "gap-conflict-affects-answer"' <<<"$conflict_output"

ruby ./scripts/generate-reasoning-skill-adapters.rb \
  --persona-registry fixtures/multi-persona/personas.json \
  --persona-id research \
  --output-dir "$TEMP_DIR/persona-adapters"

grep -q 'Persona id: `research`' "$TEMP_DIR/persona-adapters/adapters/chatgpt.md"
grep -q 'Allowed shared scopes: `shared-product`' "$TEMP_DIR/persona-adapters/adapters/chatgpt.md"
if grep -q 'Personal persona has a private planning note' "$TEMP_DIR/persona-adapters/adapters/chatgpt.md"; then
  echo "Persona adapter leaked private knowledge content." >&2
  exit 1
fi

ruby ./scripts/generate-reasoning-skill-adapters.rb --check

echo "Multi-persona smoke passed."

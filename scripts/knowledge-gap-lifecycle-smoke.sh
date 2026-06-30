#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT_DIR"

ruby ./scripts/knowledge-gap-lifecycle.rb create-gap \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --gap-id gap-question-time-source-grounding \
  --source-question "What evidence supports source grounding?" \
  --confidence-reason "unsupported answer from available knowledge" \
  --trace-id trace-gap-smoke \
  --relevant-graph-nodes node.source-grounding >/tmp/gap-create.json

ruby ./scripts/knowledge-gap-lifecycle.rb create-gap \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --gap-id gap-question-time-source-grounding \
  --source-question "What evidence supports source grounding?" \
  --confidence-reason "unsupported answer from available knowledge" \
  --trace-id trace-gap-smoke-updated >/tmp/gap-update.json

ruby ./scripts/knowledge-gap-lifecycle.rb create-gap \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --gap-id gap-semantic-validation-failed \
  --source-question "Package semantic validation failed" \
  --confidence-reason "semantic validation rejected package" \
  --trace-id trace-validation \
  --linked-package-id decision-log-20260629-portable-reasoning >/tmp/gap-validation.json

ruby ./scripts/knowledge-gap-lifecycle.rb create-conflict \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --conflict-id conflict-runtime-boundary \
  --summary "Two claims disagree about whether downstream shortcuts can count as MVP acceptance." >/tmp/conflict-create.json

list_output="$(ruby ./scripts/knowledge-gap-lifecycle.rb list-gaps --knowledge-root "$TEMP_DIR/knowledge")"
ruby -rjson -e 'gaps=JSON.parse(STDIN.read); abort "expected two open gaps" unless gaps.length == 2; abort "expected stable resolution path" unless gaps.any? { |gap| gap.fetch("gap_id") == "gap-semantic-validation-failed" && gap.fetch("allowed_resolution_path") == "decision_log_package" }' <<<"$list_output"

ruby ./scripts/knowledge-gap-lifecycle.rb resolve-gap \
  --knowledge-root "$TEMP_DIR/knowledge" \
  --gap-id gap-question-time-source-grounding >/tmp/gap-resolve.json

[[ -f "$TEMP_DIR/knowledge/gaps/resolved/gap-question-time-source-grounding.md" ]]
[[ ! -e "$TEMP_DIR/knowledge/gaps/open/gap-question-time-source-grounding.md" ]]
[[ -f "$TEMP_DIR/knowledge/conflicts/open/conflict-runtime-boundary.md" ]]
grep -q 'resolution_package_mode: conflict_resolution' "$TEMP_DIR/knowledge/conflicts/open/conflict-runtime-boundary.md"

mkdir -p "$TEMP_DIR/knowledge/gaps/open"
cat >"$TEMP_DIR/knowledge/gaps/open/gap-invalid.md" <<'EOF'
---
kind: knowledge_gap
gap_id: gap-invalid
---

# Invalid
EOF

if ruby ./scripts/knowledge-gap-lifecycle.rb list-gaps --knowledge-root "$TEMP_DIR/knowledge" >/tmp/gap-invalid-list.json 2>/tmp/gap-invalid-list.err; then
  echo "Expected invalid gap front matter to fail." >&2
  exit 1
fi
grep -q 'GAP_FRONT_MATTER_INVALID' /tmp/gap-invalid-list.err

echo "Knowledge gap lifecycle smoke passed."

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-${TRAVERSE_CHECKOUT:-}}"
REQUIRED="${TRAVERSE_ANSWER_WORKFLOW_REQUIRED:-0}"

cd "$ROOT_DIR"

if [[ -z "$TRAVERSE_REPO" && "$REQUIRED" == "1" && -d "$ROOT_DIR/../Traverse/.git" ]]; then
  TRAVERSE_REPO="$ROOT_DIR/../Traverse"
fi

json_file="$(mktemp "${TMPDIR:-/tmp}/youaskm3-answer-workflow.XXXXXX.json")"
trap 'rm -f "$json_file"' EXIT

bash scripts/query-answer-workflow-smoke.sh

ruby <<'RUBY'
require "json"

def read_json(path)
  JSON.parse(File.read(path))
rescue JSON::ParserError => error
  abort "Invalid JSON in #{path}: #{error.message}"
end

search_index = read_json("app/site/search-index.json")
graph = read_json("app/site/knowledge-graph.json")
workflow = read_json("traverse/youaskm3-app/workflows/knowledge-query-answer.workflow.json")
app = read_json("traverse/youaskm3-app/manifest.json")

documents = search_index.fetch("documents")
abort "answer workflow smoke requires prepared search documents" if documents.empty?
documents.each do |document|
  abort "search document missing source_path" unless document.fetch("source_path", "").end_with?(".md")
end

edges = graph.fetch("edges")
abort "answer workflow smoke requires graph edges" if edges.empty?
unless edges.any? { |edge| edge.fetch("source_chunk_ids", []).any? && edge.fetch("source_paths", []).any? }
  abort "answer workflow smoke requires graph source evidence"
end

trace = workflow.fetch("trace")
abort "answer workflow must require public traces" unless trace.fetch("required") == true
%w[source_evidence graph_evidence model_dependency failure_reasons].each do |evidence|
  abort "answer workflow trace missing #{evidence}" unless trace.fetch("evidence").include?(evidence)
end

failure_policy = workflow.fetch("failure_policy")
missing_model = failure_policy.fetch("missing_model_dependency")
abort "answer workflow missing inference dependency policy" unless missing_model.fetch("code") == "MISSING_INFERENCE_DEPENDENCY"
abort "answer workflow missing inference failure must be recoverable" unless missing_model.fetch("recoverable") == true

model_dependencies = app.fetch("model_dependencies")
unless model_dependencies.any? { |dependency| dependency.fetch("required_capabilities").include?("text_generation") }
  abort "app manifest must declare text_generation model dependency"
end
RUBY

if [[ -z "$TRAVERSE_REPO" || ! -d "$TRAVERSE_REPO/.git" ]]; then
  message="Traverse answer workflow smoke skipped: set TRAVERSE_REPO to run the live Traverse v0.4.0 gate."
  if [[ "$REQUIRED" == "1" ]]; then
    echo "$message" >&2
    exit 2
  fi
  echo "$message"
  exit 0
fi

TRAVERSE_REPO="$TRAVERSE_REPO" bash scripts/traverse-readiness.sh

TRAVERSE_REPO="$TRAVERSE_REPO" \
  bash scripts/register-traverse-app.sh --allow-skeleton --json >"$json_file"

ruby -rjson -e '
payload = JSON.parse(File.read(ARGV.fetch(0)))
case payload.fetch("code")
when "SKELETON_PENDING_WASM_COMPONENTS"
  abort "expected missing WASM evidence" unless payload.dig("evidence", "missing_wasm_count").to_i.positive?
  abort "expected skipped skeleton status" unless payload.fetch("status") == "skipped_skeleton_pending_wasm"
  puts "Traverse answer workflow smoke reached registration boundary: skeleton pending WASM; execution skipped."
when "REGISTERED", "VALIDATED"
  abort "registered workflow must expose no errors" unless payload.fetch("errors").empty?
  puts "Traverse answer workflow registration evidence passed."
else
  abort "unexpected Traverse answer workflow registration result: #{payload.fetch("code")}"
end
' "$json_file"

echo "Traverse answer workflow smoke passed."

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

ruby <<'RUBY'
require "json"

APP_MANIFEST = "traverse/youaskm3-app/manifest.json"
WORKFLOW = "traverse/youaskm3-app/workflows/knowledge-query-answer.workflow.json"

def read_json(path)
  JSON.parse(File.read(path))
rescue JSON::ParserError => error
  abort "Invalid JSON in #{path}: #{error.message}"
end

app = read_json(APP_MANIFEST)
workflow = read_json(WORKFLOW)

abort "query-answer workflow must be lifecycle=mvp" unless workflow.fetch("lifecycle") == "mvp"
abort "query-answer workflow must require trace evidence" unless workflow.dig("trace", "required") == true

expected_capabilities = [
  "knowledge.retrieve",
  "knowledge.graph.expand",
  "knowledge.context.pack",
  "knowledge.infer",
  "knowledge.answer.validate",
  "knowledge.answer.format"
]

nodes = workflow.fetch("nodes")
actual_capabilities = nodes.map { |node| node.fetch("capability_id") }
abort "query-answer workflow capabilities mismatch: #{actual_capabilities.inspect}" unless actual_capabilities == expected_capabilities

expected_edges = nodes.each_cons(2).map { |left, right| [left.fetch("node_id"), right.fetch("node_id")] }
actual_edges = workflow.fetch("edges").map { |edge| [edge.fetch("from"), edge.fetch("to")] }
abort "query-answer workflow edges mismatch: #{actual_edges.inspect}" unless actual_edges == expected_edges

trace_required = [
  "knowledge.graph.expand",
  "knowledge.context.pack",
  "knowledge.answer.validate",
  "knowledge.answer.format"
]

nodes.each do |node|
  input = node.fetch("input")
  if trace_required.include?(node.fetch("capability_id"))
    abort "#{node.fetch("node_id")} does not receive workflow trace id" unless input.fetch("from_workflow_trace").include?("trace_id")
  end
end

state_driven_nodes = nodes.drop(1)
state_driven_nodes.each do |node|
  input = node.fetch("input")
  abort "#{node.fetch("node_id")} must consume workflow state" unless input.key?("from_workflow_state")
end

failure_policy = workflow.fetch("failure_policy")
[
  "MISSING_CHILD_CAPABILITY",
  "MISSING_INFERENCE_DEPENDENCY",
  "ANSWER_VALIDATION_FAILED"
].each do |code|
  unless failure_policy.values.any? { |policy| policy.fetch("code") == code && policy.fetch("recoverable") == true }
    abort "query-answer workflow missing recoverable failure policy #{code}"
  end
end

model_dependencies = app.fetch("model_dependencies")
required_model_dependency = model_dependencies.any? do |dependency|
  dependency.fetch("required_capabilities").include?("text_generation") &&
    dependency.fetch("selection_policy").fetch("allow_fallback") == true
end
abort "app manifest must declare governed text generation dependency" unless required_model_dependency

component_capabilities = app.fetch("components").map do |component|
  manifest = read_json(File.join("traverse/youaskm3-app", component.fetch("manifest_path")))
  manifest.fetch("capability_id")
end

missing = (["knowledge.query.answer"] + expected_capabilities) - component_capabilities
abort "app manifest missing workflow component capabilities: #{missing.join(", ")}" unless missing.empty?
RUBY

echo "Query answer workflow smoke passed."

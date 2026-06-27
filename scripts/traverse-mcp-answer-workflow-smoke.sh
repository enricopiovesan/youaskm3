#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-${TRAVERSE_CHECKOUT:-}}"
REQUIRED="${TRAVERSE_MCP_ANSWER_WORKFLOW_REQUIRED:-0}"

cd "$ROOT_DIR"

ruby <<'RUBY'
require "json"
require "pathname"

ROOT = Pathname.new(Dir.pwd)

def read_json(path)
  JSON.parse(File.read(path))
rescue JSON::ParserError => error
  abort "Invalid JSON in #{path}: #{error.message}"
end

def relative_contract_path(component_manifest_path, component_manifest)
  Pathname
    .new(component_manifest_path)
    .dirname
    .join(component_manifest.fetch("contract_path"))
    .cleanpath
    .relative_path_from(ROOT)
    .to_s
rescue ArgumentError
  Pathname
    .new(component_manifest_path)
    .dirname
    .join(component_manifest.fetch("contract_path"))
    .cleanpath
    .to_s
end

app = read_json("traverse/youaskm3-app/manifest.json")
workflow_entry = app.fetch("workflows").find { |entry| entry.fetch("workflow_id") == "youaskm3.knowledge.query-answer" }
abort "app manifest missing query answer workflow" unless workflow_entry

workflow_path = "traverse/youaskm3-app/#{workflow_entry.fetch("path")}"
workflow = read_json(workflow_path)
abort "query answer workflow id mismatch" unless workflow.fetch("id") == workflow_entry.fetch("workflow_id")
abort "app manifest must expose MCP public surface" unless app.fetch("public_surfaces").include?("mcp")

mcp_tools = read_json("contracts/mcp-tools.json").fetch("tools")
mcp_tool = mcp_tools.find { |tool| tool.fetch("name") == "knowledge.query.answer" }
abort "MCP tools contract missing knowledge.query.answer" unless mcp_tool
abort "MCP answer tool must map to capability contract" unless mcp_tool.fetch("capability_id") == "knowledge.query.answer"
abort "MCP answer tool must map to registered workflow" unless mcp_tool.fetch("workflow_id") == workflow.fetch("id")
abort "MCP answer tool must use Traverse MCP surface" unless mcp_tool.fetch("surface") == "traverse_mcp"
abort "MCP answer tool contract path mismatch" unless mcp_tool.fetch("contract_path") == "contracts/capabilities/knowledge.query.answer.json"
abort "MCP answer tool workflow path mismatch" unless mcp_tool.fetch("workflow_path") == workflow_path

query_component_entry = app.fetch("components").find do |entry|
  entry.fetch("component_id") == "youaskm3.knowledge.query-answer-component"
end
abort "app manifest missing query answer component" unless query_component_entry
query_component_path = "traverse/youaskm3-app/#{query_component_entry.fetch("manifest_path")}"
query_component = read_json(query_component_path)
abort "query answer component capability mismatch" unless query_component.fetch("capability_id") == "knowledge.query.answer"
abort "query answer component must permit local placement" unless query_component.fetch("permitted_targets").include?("local")

query_contract = read_json(mcp_tool.fetch("contract_path"))
abort "query answer contract id mismatch" unless query_contract.fetch("id") == mcp_tool.fetch("capability_id")
abort "query answer contract must permit MCP" unless query_contract.fetch("execution").fetch("permitted_targets").include?("mcp")
abort "query answer contract must require trace" unless query_contract.fetch("execution").fetch("requires_trace") == true

required_output = %w[answer citations graph_evidence trace_id validation]
missing_output = required_output - mcp_tool.fetch("output_schema").fetch("required")
abort "MCP answer tool output missing #{missing_output.join(", ")}" unless missing_output.empty?

trace = workflow.fetch("trace")
abort "MCP parity requires workflow trace" unless trace.fetch("required") == true
%w[capability_ids placement source_evidence graph_evidence model_dependency validation_outcome failure_reasons].each do |evidence|
  abort "workflow trace missing #{evidence}" unless trace.fetch("evidence").include?(evidence)
end

model_dependencies = app.fetch("model_dependencies")
model_dependency = model_dependencies.find do |dependency|
  dependency.fetch("interface_id") == "traverse.inference.generate" &&
    dependency.fetch("required_capabilities").include?("text_generation")
end
abort "app manifest missing Traverse text generation model dependency" unless model_dependency
abort "model dependency must include at least one candidate" if model_dependency.fetch("candidates").empty?

failure_policy = workflow.fetch("failure_policy")
%w[MISSING_CHILD_CAPABILITY MISSING_INFERENCE_DEPENDENCY ANSWER_VALIDATION_FAILED].each do |code|
  unless failure_policy.values.any? { |policy| policy.fetch("code") == code && policy.fetch("recoverable") == true }
    abort "workflow missing recoverable MCP-visible failure policy #{code}"
  end
end

workflow_capabilities = workflow.fetch("nodes").map { |node| node.fetch("capability_id") }
component_manifests = app.fetch("components").map do |entry|
  path = "traverse/youaskm3-app/#{entry.fetch("manifest_path")}"
  [path, read_json(path)]
end
component_by_capability = component_manifests.to_h { |path, manifest| [manifest.fetch("capability_id"), [path, manifest]] }

workflow_capabilities.each do |capability_id|
  manifest_path, manifest = component_by_capability.fetch(capability_id) do
    abort "workflow capability #{capability_id} is not registered as an app component"
  end
  abort "#{capability_id} component must permit local placement" unless manifest.fetch("permitted_targets").include?("local")

  traverse_contract = read_json(relative_contract_path(manifest_path, manifest))
  abort "#{capability_id} Traverse contract id mismatch" unless traverse_contract.fetch("id") == capability_id

  product_contract = read_json("contracts/capabilities/#{capability_id}.json")
  abort "#{capability_id} product contract must permit MCP" unless product_contract.fetch("execution").fetch("permitted_targets").include?("mcp")
  abort "#{capability_id} product contract must require trace" unless product_contract.fetch("execution").fetch("requires_trace") == true
end

format_contract = read_json("contracts/capabilities/knowledge.answer.format.json")
target_enum = format_contract.fetch("inputs").fetch("schema").fetch("properties").fetch("target").fetch("enum")
abort "answer format contract must support MCP target" unless target_enum.include?("mcp")

puts "Traverse MCP answer workflow local parity checks passed."
RUBY

if [[ -z "$TRAVERSE_REPO" ]] || ! git -C "$TRAVERSE_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  message="Traverse MCP answer workflow smoke skipped: set TRAVERSE_REPO to run the live Traverse MCP parity gate."
  if [[ "$REQUIRED" == "1" ]]; then
    echo "$message" >&2
    exit 2
  fi
  echo "$message"
  exit 0
fi

(cd "$TRAVERSE_REPO" && bash scripts/ci/downstream_mcp_smoke.sh)

echo "Traverse MCP answer workflow smoke passed."

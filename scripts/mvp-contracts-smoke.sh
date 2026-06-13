#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

ruby <<'RUBY'
require "json"

required_capabilities = [
  "knowledge.query.answer",
  "knowledge.retrieve",
  "knowledge.graph.expand",
  "knowledge.context.pack",
  "knowledge.infer",
  "knowledge.answer.validate",
  "knowledge.answer.format"
]

def read_json(path)
  JSON.parse(File.read(path))
rescue JSON::ParserError => error
  abort "Invalid JSON in #{path}: #{error.message}"
end

required_capabilities.each do |capability_id|
  path = File.join("contracts", "capabilities", "#{capability_id}.json")
  abort "Missing capability contract: #{path}" unless File.file?(path)

  contract = read_json(path)
  {
    "kind" => "youaskm3.capability_contract",
    "id" => capability_id
  }.each do |key, expected|
    actual = contract[key]
    abort "#{path} has #{key}=#{actual.inspect}, expected #{expected.inspect}" unless actual == expected
  end

  ["schema_version", "version", "summary", "description", "execution", "inputs", "outputs"].each do |key|
    abort "#{path} is missing #{key}" unless contract.key?(key)
  end

  ["runtime", "business_logic", "permitted_targets", "requires_trace"].each do |key|
    abort "#{path} execution is missing #{key}" unless contract.fetch("execution").key?(key)
  end

  input_schema = contract.fetch("inputs").fetch("schema")
  output_schema = contract.fetch("outputs").fetch("schema")
  abort "#{path} input schema must be an object" unless input_schema["type"] == "object"
  abort "#{path} output schema must be an object" unless output_schema["type"] == "object"
end

schema_expectations = {
  "contracts/markdown-artifact.schema.json" => ["artifact_id", "title", "source", "conversion", "sections", "chunks"],
  "contracts/knowledge-graph.schema.json" => ["graph_id", "generated_from", "nodes", "edges"]
}

schema_expectations.each do |path, required|
  schema = read_json(path)
  missing = required - schema.fetch("required")
  abort "#{path} is missing required fields: #{missing.join(", ")}" unless missing.empty?
end

example_pairs = {
  "contracts/examples/markdown-artifact.example.json" => ["artifact_id", "source", "conversion", "sections", "chunks"],
  "contracts/examples/knowledge-graph.example.json" => ["graph_id", "nodes", "edges"]
}

example_pairs.each do |path, required|
  example = read_json(path)
  missing = required.reject { |key| example.key?(key) }
  abort "#{path} is missing example fields: #{missing.join(", ")}" unless missing.empty?
end
RUBY

echo "MVP contract smoke passed."

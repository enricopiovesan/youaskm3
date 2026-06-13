#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

ruby ./scripts/generate-site-artifacts.rb app/site

ruby <<'RUBY'
require "json"

search_index = JSON.parse(File.read("app/site/search-index.json"))
graph = JSON.parse(File.read("app/site/knowledge-graph.json"))

documents = search_index.fetch("documents")
source_paths = documents.map { |document| document.fetch("source_path") }.sort

abort "Graph artifact must include a schema version" unless graph.fetch("schema_version") == "0.1.0"
abort "Graph generated_from must match indexed documents" unless graph.fetch("generated_from").sort == documents.map { |document| document.fetch("id") }.sort

nodes = graph.fetch("nodes")
edges = graph.fetch("edges")

expected_node_count = documents.length * 2
abort "Expected #{expected_node_count} graph nodes, found #{nodes.length}" unless nodes.length == expected_node_count
abort "Expected #{documents.length} graph edges, found #{edges.length}" unless edges.length == documents.length

graph_source_paths = (nodes + edges).flat_map { |entry| entry.fetch("source_paths") }.uniq.sort
abort "Graph source paths do not match search index source paths" unless graph_source_paths == source_paths

node_ids = nodes.map { |node| node.fetch("node_id") }
abort "Graph node ids must be unique" unless node_ids.uniq.length == node_ids.length

edges.each do |edge|
  abort "Graph edge references missing source node: #{edge.fetch("edge_id")}" unless node_ids.include?(edge.fetch("from_node_id"))
  abort "Graph edge references missing target node: #{edge.fetch("edge_id")}" unless node_ids.include?(edge.fetch("to_node_id"))
  abort "Graph edge must use deterministic extraction" unless edge.fetch("extraction_method") == "deterministic-site-artifact-generator"
end
RUBY

echo "MVP graph artifact smoke passed."

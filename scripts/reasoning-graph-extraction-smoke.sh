#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT_DIR"

ruby ./scripts/extract-reasoning-graph.rb fixtures/decision-log-packages/valid/gap_resolution \
  | ruby -rjson -e 'graph=JSON.parse(STDIN.read); types=graph.fetch("nodes").map { |node| node.fetch("type") }.uniq; required=%w[concept question option tradeoff assumption decision claim open_question source_gap knowledge_note citation source_artifact confidence_assessment validation_result]; missing=required-types; abort "missing reasoning node types: #{missing.inspect}" unless missing.empty?; abort "expected source gap" unless graph.fetch("nodes").any? { |node| node.fetch("type") == "source_gap" && node.fetch("label") == "gap-runtime-policy" }; abort "expected deterministic edges" unless graph.fetch("edges").all? { |edge| edge.fetch("extraction_method") == "deterministic-reasoning-graph-extractor" }'

if ruby ./scripts/extract-reasoning-graph.rb fixtures/decision-log-packages/invalid/incomplete-sections >/tmp/reasoning-graph-invalid.json 2>/tmp/reasoning-graph-invalid.err; then
  echo "Expected invalid decision-log package graph extraction to fail." >&2
  exit 1
fi
grep -Eq 'Missing extractable|Missing label' /tmp/reasoning-graph-invalid.err

mkdir -p \
  "$TEMP_DIR/app/site" \
  "$TEMP_DIR/knowledge/blog" \
  "$TEMP_DIR/knowledge/books" \
  "$TEMP_DIR/knowledge/papers" \
  "$TEMP_DIR/knowledge/sources/decision-logs" \
  "$TEMP_DIR/scripts"

cp "$ROOT_DIR/app/site/author-instance.json" "$TEMP_DIR/app/site/author-instance.json"
cp "$ROOT_DIR/app/site/provider-config.json" "$TEMP_DIR/app/site/provider-config.json"
cp "$ROOT_DIR/scripts/generate-site-artifacts.rb" "$TEMP_DIR/scripts/generate-site-artifacts.rb"
cp "$ROOT_DIR/scripts/reasoning-graph-extractor.rb" "$TEMP_DIR/scripts/reasoning-graph-extractor.rb"
cp -R "$ROOT_DIR/fixtures/decision-log-packages/valid/gap_resolution" "$TEMP_DIR/knowledge/sources/decision-logs/decision-log-20260629-gap-resolution"

(
  cd "$TEMP_DIR"
  ruby ./scripts/generate-site-artifacts.rb app/site
)

ruby -rjson -e 'graph=JSON.parse(File.read(ARGV[0])); abort "missing package in generated_from" unless graph.fetch("generated_from").include?("decision-log-20260629-gap-resolution"); abort "missing reasoning graph node" unless graph.fetch("nodes").any? { |node| node.fetch("type") == "validation_result" }; abort "missing reasoning graph edge" unless graph.fetch("edges").any? { |edge| edge.fetch("extraction_method") == "deterministic-reasoning-graph-extractor" }' "$TEMP_DIR/app/site/knowledge-graph.json"

echo "Reasoning graph extraction smoke passed."

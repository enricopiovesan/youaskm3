#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

ruby ./scripts/generate-site-artifacts.rb app/site

ruby <<'RUBY'
require "json"

index = JSON.parse(File.read("app/site/search-index.json"))
documents = index.fetch("documents")
fixture_documents = documents.select { |document| document.fetch("source_path").include?("mvp-fixture") }

abort "Expected at least 3 MVP fixture documents, found #{fixture_documents.length}" if fixture_documents.length < 3
if fixture_documents.any? { |document| document.fetch("excerpt").include?("youaskm3:fixture") }
  abort "Fixture metadata leaked into generated search excerpts"
end

required_queries = {
  "portable" => "Portable Knowledge Article",
  "architecture" => "MVP Architecture Handbook",
  "grounding" => "Source Grounding Note"
}

required_queries.each do |query, expected_title|
  matches = fixture_documents.select do |document|
    [document.fetch("title"), document.fetch("excerpt"), document.fetch("source_path")].any? do |value|
      value.downcase.include?(query)
    end
  end

  unless matches.any? { |document| document.fetch("title") == expected_title }
    abort "Expected query #{query.inspect} to match #{expected_title.inspect}"
  end
end
RUBY

portable_output="$(./scripts/m3.sh search portable)"
architecture_output="$(./scripts/m3.sh search architecture)"

grep -q "Portable Knowledge Article" <<<"$portable_output"
grep -q "MVP Architecture Handbook" <<<"$architecture_output"

echo "MVP fixture corpus smoke passed."

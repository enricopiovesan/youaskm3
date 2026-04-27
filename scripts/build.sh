#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd cargo
require_cmd ruby

cd "$ROOT_DIR"

echo "Generating static knowledge and site artifacts..."
ruby <<'RUBY'
require "json"

root = Dir.pwd
site_dir = File.join(root, "app/site")
knowledge_dir = File.join(root, "knowledge")
author_instance_path = File.join(site_dir, "author-instance.json")

def trimmed_excerpt(markdown)
  markdown
    .each_line
    .map(&:strip)
    .reject(&:empty?)
    .reject { |line| line.start_with?("#", "-", "|", "<!--") }
    .first
    .to_s[0, 180]
end

def document_title(markdown_path, markdown)
  heading = markdown.each_line.map(&:strip).find { |line| line.start_with?("# ") }
  return heading.delete_prefix("# ").strip unless heading.nil? || heading.empty?

  File.basename(markdown_path, ".md").tr("_-", "  ").split.join(" ")
end

author_instance = JSON.parse(File.read(author_instance_path))

knowledge_documents = Dir.glob(File.join(knowledge_dir, "{books,papers,blog}/**/*.md")).sort.map do |path|
  relative_path = path.delete_prefix("#{root}/")
  markdown = File.read(path)
  category = relative_path.split("/")[1]

  {
    "id" => relative_path.delete_suffix(".md").gsub("/", "--"),
    "title" => document_title(path, markdown),
    "source_path" => relative_path,
    "category" => category,
    "excerpt" => trimmed_excerpt(markdown)
  }
end

pending_inputs = Dir.glob(File.join(knowledge_dir, "inputs/**/*")).sort.select { |path| File.file?(path) }

search_index = {
  "instanceId" => author_instance.fetch("instanceId"),
  "title" => author_instance.fetch("title"),
  "shellUrl" => author_instance.fetch("shellUrl"),
  "documents" => knowledge_documents
}

build_manifest = {
  "instanceId" => author_instance.fetch("instanceId"),
  "shellUrl" => author_instance.fetch("shellUrl"),
  "knowledgeDocumentCount" => knowledge_documents.length,
  "pendingInputCount" => pending_inputs.length,
  "artifacts" => [
    "app/site/search-index.json",
    "app/site/build-manifest.json",
    "app/site/author-instance.json",
    "app/site/provider-config.json"
  ]
}

File.write(File.join(site_dir, "search-index.json"), JSON.pretty_generate(search_index) + "\n")
File.write(File.join(site_dir, "build-manifest.json"), JSON.pretty_generate(build_manifest) + "\n")
RUBY

echo "Running native workspace build..."
cargo build --locked --workspace

echo "Running wasm32-wasip1 workspace build..."
cargo build --locked --workspace --target wasm32-wasip1

echo "Build checks completed successfully."

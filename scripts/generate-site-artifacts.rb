#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"

root = File.expand_path("..", __dir__)
output_dir = File.expand_path(ARGV[0] || File.join(root, "app/site"), root)
knowledge_dir = File.join(root, "knowledge")
author_instance_path = File.join(root, "app/site/author-instance.json")

abort("Missing required file: app/site/author-instance.json") unless File.file?(author_instance_path)

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

def normalize_relative_path(path, root)
  path.delete_prefix("#{root}/")
end

def source_entry(path, root, kind)
  relative_path = normalize_relative_path(path, root)

  {
    "path" => relative_path,
    "kind" => kind,
    "sha256" => Digest::SHA256.hexdigest(File.read(path))
  }
end

author_instance = JSON.parse(File.read(author_instance_path))

processed_document_paths = Dir.glob(File.join(knowledge_dir, "{books,papers,blog}/**/*.md")).sort
pending_input_paths = Dir.glob(File.join(knowledge_dir, "inputs/**/*")).sort.select { |path| File.file?(path) }

source_entries = [
  source_entry(author_instance_path, root, "instance-manifest")
]

source_entries.concat(processed_document_paths.map { |path| source_entry(path, root, "processed-knowledge") })
source_entries.concat(pending_input_paths.map { |path| source_entry(path, root, "pending-input") })

source_fingerprint = Digest::SHA256.hexdigest(
  source_entries.map { |entry| [entry.fetch("path"), entry.fetch("kind"), entry.fetch("sha256")].join(":") }.join("\n")
)

knowledge_documents = processed_document_paths.map do |path|
  relative_path = normalize_relative_path(path, root)
  markdown = File.read(path)
  matching_source = source_entries.find { |entry| entry.fetch("path") == relative_path }
  category = relative_path.split("/")[1]

  {
    "id" => relative_path.delete_suffix(".md").gsub("/", "--"),
    "title" => document_title(path, markdown),
    "source_path" => relative_path,
    "category" => category,
    "excerpt" => trimmed_excerpt(markdown),
    "content_sha256" => matching_source.fetch("sha256")
  }
end

search_index = {
  "instanceId" => author_instance.fetch("instanceId"),
  "title" => author_instance.fetch("title"),
  "shellUrl" => author_instance.fetch("shellUrl"),
  "sourceFingerprint" => source_fingerprint,
  "documents" => knowledge_documents
}

build_manifest = {
  "instanceId" => author_instance.fetch("instanceId"),
  "shellUrl" => author_instance.fetch("shellUrl"),
  "sourceFingerprint" => source_fingerprint,
  "knowledgeDocumentCount" => knowledge_documents.length,
  "pendingInputCount" => pending_input_paths.length,
  "artifacts" => [
    "app/site/search-index.json",
    "app/site/build-manifest.json",
    "app/site/sync-state.json",
    "app/site/author-instance.json",
    "app/site/provider-config.json"
  ],
  "sources" => source_entries
}

sync_state = {
  "instanceId" => author_instance.fetch("instanceId"),
  "sourceFingerprint" => source_fingerprint,
  "knowledgeDocumentCount" => knowledge_documents.length,
  "pendingInputCount" => pending_input_paths.length,
  "trackedSourcePaths" => source_entries.map { |entry| entry.fetch("path") },
  "sources" => source_entries
}

FileUtils.mkdir_p(output_dir)
File.write(File.join(output_dir, "search-index.json"), JSON.pretty_generate(search_index) + "\n")
File.write(File.join(output_dir, "build-manifest.json"), JSON.pretty_generate(build_manifest) + "\n")
File.write(File.join(output_dir, "sync-state.json"), JSON.pretty_generate(sync_state) + "\n")

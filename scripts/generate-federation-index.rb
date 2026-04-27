#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open-uri"
require "uri"

def abort_with(message)
  warn(message)
  exit(1)
end

def fetch_json(source)
  if source.start_with?("http://", "https://")
    JSON.parse(URI.open(source, &:read))
  elsif source.start_with?("file://")
    file_path = URI.parse(source).path
    JSON.parse(File.read(file_path))
  else
    JSON.parse(File.read(source))
  end
rescue Errno::ENOENT
  abort_with("Federation crawl failed: missing file #{source}.")
rescue OpenURI::HTTPError => error
  abort_with("Federation crawl failed while fetching #{source}: #{error.message}.")
rescue JSON::ParserError => error
  abort_with("Federation crawl failed: invalid JSON at #{source}: #{error.message}.")
end

def required_string(hash, key, context)
  value = hash[key]
  abort_with("Federation crawl failed: #{context} is missing required field #{key}.") unless value.is_a?(String) && !value.empty?

  value
end

def required_array(hash, key, context)
  value = hash[key]
  abort_with("Federation crawl failed: #{context} is missing required array #{key}.") unless value.is_a?(Array)

  value
end

registry_source = ARGV[0]
output_dir = ARGV[1]

abort_with("Usage: ruby scripts/generate-federation-index.rb <registry-json> <output-dir>") if registry_source.nil? || output_dir.nil?

registry = fetch_json(registry_source)
registry_repository = required_string(registry, "registry_repository", "registry document")
instances = required_array(registry, "instances", "registry document")

aggregated_instances = []
aggregated_documents = []
fingerprint_inputs = [registry_repository]

instances.each do |instance|
  name = required_string(instance, "name", "registry instance")
  url = required_string(instance, "url", "registry instance")
  search_index_url = required_string(instance, "search_index_url", "registry instance")
  description = required_string(instance, "description", "registry instance")
  topics = required_array(instance, "topics", "registry instance")
  since = required_string(instance, "since", "registry instance")

  search_index = fetch_json(search_index_url)
  instance_id = required_string(search_index, "instanceId", "search index")
  title = required_string(search_index, "title", "search index")
  shell_url = required_string(search_index, "shellUrl", "search index")
  documents = required_array(search_index, "documents", "search index")

  normalized_documents = documents.sort_by do |document|
    source_path = required_string(document, "source_path", "search index document")
    [source_path, required_string(document, "id", "search index document")]
  end.map do |document|
    document_id = required_string(document, "id", "search index document")
    source_path = required_string(document, "source_path", "search index document")
    fingerprint_inputs << "#{instance_id}:#{document_id}:#{source_path}"

    {
      "id" => "#{instance_id}--#{document_id}",
      "instanceId" => instance_id,
      "instanceName" => name,
      "instanceUrl" => url,
      "instanceShellUrl" => shell_url,
      "title" => required_string(document, "title", "search index document"),
      "source_path" => source_path,
      "category" => required_string(document, "category", "search index document"),
      "excerpt" => required_string(document, "excerpt", "search index document"),
      "topics" => topics
    }
  end

  aggregated_instances << {
    "instanceId" => instance_id,
    "name" => name,
    "title" => title,
    "url" => url,
    "shellUrl" => shell_url,
    "searchIndexUrl" => search_index_url,
    "description" => description,
    "topics" => topics,
    "since" => since,
    "documentCount" => normalized_documents.length
  }

  aggregated_documents.concat(normalized_documents)
end

aggregated_instances.sort_by! { |instance| [instance.fetch("name"), instance.fetch("instanceId")] }
aggregated_documents.sort_by! { |document| [document.fetch("instanceName"), document.fetch("source_path"), document.fetch("id")] }

source_fingerprint = Digest::SHA256.hexdigest(fingerprint_inputs.join("\n"))

federation_search_index = {
  "registryRepository" => registry_repository,
  "sourceFingerprint" => source_fingerprint,
  "instanceCount" => aggregated_instances.length,
  "documentCount" => aggregated_documents.length,
  "instances" => aggregated_instances,
  "documents" => aggregated_documents
}

federation_manifest = {
  "registryRepository" => registry_repository,
  "sourceFingerprint" => source_fingerprint,
  "artifacts" => [
    "app/site/federation-search-index.json",
    "app/site/federation-index-manifest.json"
  ],
  "instanceSources" => aggregated_instances.map do |instance|
    {
      "instanceId" => instance.fetch("instanceId"),
      "searchIndexUrl" => instance.fetch("searchIndexUrl"),
      "documentCount" => instance.fetch("documentCount")
    }
  end
}

FileUtils.mkdir_p(output_dir)
File.write(File.join(output_dir, "federation-search-index.json"), JSON.pretty_generate(federation_search_index) + "\n")
File.write(File.join(output_dir, "federation-index-manifest.json"), JSON.pretty_generate(federation_manifest) + "\n")

#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "time"

ROOT = Pathname.new(__dir__).join("..").expand_path
DEFAULT_KNOWLEDGE_ROOT = ROOT.join("knowledge")

def usage
  abort <<~USAGE
    Usage:
      ./scripts/m3.sh federated-answer answer --query QUERY --federation-index PATH --policy PATH [--knowledge-root PATH]
      ./scripts/m3.sh federated-answer import --evidence PATH [--knowledge-root PATH]
  USAGE
end

def parse_flags(argv)
  flags = { "knowledge_root" => DEFAULT_KNOWLEDGE_ROOT.to_s }
  until argv.empty?
    key = argv.shift
    usage unless key.start_with?("--")
    flags[key.delete_prefix("--").tr("-", "_")] = argv.shift || usage
  end
  flags
end

def read_json(path)
  JSON.parse(Pathname.new(path).read)
rescue JSON::ParserError => error
  abort "INVALID_JSON: #{path} is not valid JSON: #{error.message}"
end

def query_terms(query)
  query.downcase.scan(/[a-z0-9]+/).reject { |term| term.length < 3 }
end

def score_document(document, terms)
  haystack = [document["title"], document["excerpt"], document["category"]].compact.join(" ").downcase
  terms.count { |term| haystack.include?(term) }
end

def remote_evidence(document, query, score)
  {
    "evidence_kind" => "remote",
    "remote_instance" => {
      "id" => document.fetch("instanceId"),
      "name" => document.fetch("instanceName"),
      "url" => document.fetch("instanceUrl")
    },
    "source_artifact" => {
      "id" => document.fetch("documentId"),
      "title" => document.fetch("title"),
      "path" => document.fetch("sourcePath"),
      "category" => document.fetch("category")
    },
    "retrieval" => {
      "query" => query,
      "path" => "federation-search-index",
      "score" => score
    },
    "confidence" => document.fetch("confidence", "unknown"),
    "excerpt" => document.fetch("excerpt")
  }
end

def answer(flags)
  query = flags.fetch("query")
  policy = read_json(flags.fetch("policy"))
  unless policy.fetch("allow_federated_answers", false)
    puts JSON.pretty_generate(
      {
        "status" => "local_only",
        "federated_answers_allowed" => false,
        "remote_query_performed" => false,
        "answer" => "Federated answers are disabled; use local knowledge only.",
        "evidence" => []
      }
    )
    return
  end

  index = read_json(flags.fetch("federation_index"))
  terms = query_terms(query)
  evidence = index.fetch("documents").map do |document|
    score = score_document(document, terms)
    score.positive? ? remote_evidence(document, query, score) : nil
  end.compact.sort_by { |item| -item.fetch("retrieval").fetch("score") }

  puts JSON.pretty_generate(
    {
      "status" => evidence.empty? ? "no_remote_evidence" : "remote_evidence",
      "federated_answers_allowed" => true,
      "remote_query_performed" => true,
      "answer" => evidence.empty? ? "No federated evidence matched." : "Federated evidence is available, but it is not personal knowledge unless explicitly imported.",
      "evidence" => evidence
    }
  )
end

def slug(value)
  value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
end

def import(flags)
  evidence = read_json(flags.fetch("evidence"))
  first = evidence.fetch("evidence").find { |item| item.fetch("evidence_kind") == "remote" } ||
    abort("REMOTE_EVIDENCE_MISSING: evidence file does not contain remote evidence")
  knowledge_root = Pathname.new(flags.fetch("knowledge_root")).expand_path
  instance_id = first.fetch("remote_instance").fetch("id")
  artifact_id = first.fetch("source_artifact").fetch("id")
  path = knowledge_root.join("sources", "federated", slug(instance_id), "#{slug(artifact_id)}.json")
  FileUtils.mkdir_p(path.dirname)
  record = {
    "schema_version" => "1.0.0",
    "kind" => "federated_source_artifact",
    "ingestion_status" => "imported_remote_evidence",
    "personal_knowledge" => false,
    "imported_at" => Time.now.utc.iso8601,
    "remote_provenance" => first
  }
  path.write(JSON.pretty_generate(record) + "\n")
  puts JSON.pretty_generate(
    {
      "status" => "imported",
      "path" => path.relative_path_from(ROOT).to_s,
      "remote_instance_id" => instance_id,
      "source_artifact_id" => artifact_id,
      "personal_knowledge" => false
    }
  )
end

command = ARGV.shift || usage
flags = parse_flags(ARGV)
case command
when "answer"
  answer(flags)
when "import"
  import(flags)
else
  usage
end

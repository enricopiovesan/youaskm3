#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "time"

ROOT = Pathname.new(__dir__).join("..").expand_path
DEFAULT_KNOWLEDGE_ROOT = ROOT.join("knowledge")
REQUIRED_GAP_KEYS = ["kind", "gap_id", "status", "persona_id", "source_question", "confidence_reason", "trace_id", "deterministic_complexity", "final_complexity", "allowed_resolution_path", "created_at", "updated_at"].freeze

def stable_error(code, message)
  warn "#{code}: #{message}"
  exit 1
end

def slug(value)
  value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
end

def parse_flags(argv)
  flags = {}
  until argv.empty?
    key = argv.shift
    stable_error("INVALID_ARGUMENT", "Expected flag, got #{key}") unless key.start_with?("--")
    flags[key.delete_prefix("--").tr("-", "_")] = argv.shift || stable_error("INVALID_ARGUMENT", "Missing value for #{key}")
  end
  flags
end

def front_matter(markdown)
  lines = markdown.lines
  stable_error("FRONT_MATTER_MISSING", "Markdown record is missing front matter.") unless lines.first&.strip == "---"
  closing = lines[1..].find_index { |line| line.strip == "---" }
  stable_error("FRONT_MATTER_MISSING", "Markdown record front matter is not closed.") if closing.nil?

  lines[1, closing].each_with_object({}) do |line, data|
    next if line.strip.empty?
    key, value = line.split(":", 2)
    stable_error("FRONT_MATTER_INVALID", "Invalid front matter line: #{line.strip}") if value.nil?
    value = value.strip
    data[key.strip] = if value == "null"
                         nil
                       elsif value.start_with?("[") && value.end_with?("]")
                         value.delete_prefix("[").delete_suffix("]").split(",").map(&:strip).reject(&:empty?)
                       else
                         value
                       end
  end
end

def classify(reason, question)
  text = "#{reason} #{question}".downcase
  if text.match?(/\b(architecture|strategic|strategy|concept|conflict|ambiguous|semantic|tradeoff|assumption)\b/)
    "reasoning_heavy"
  else
    "simple_factual"
  end
end

def resolution_path(complexity)
  complexity == "simple_factual" ? "direct_chat" : "decision_log_package"
end

def write_record(path, front, body)
  FileUtils.mkdir_p(path.dirname)
  serialized = front.map do |key, value|
    rendered = value.is_a?(Array) ? "[#{value.join(", ")}]" : (value.nil? ? "null" : value)
    "#{key}: #{rendered}"
  end.join("\n")
  path.write("---\n#{serialized}\n---\n\n#{body}\n")
end

def create_gap(flags)
  knowledge_root = Pathname.new(flags.fetch("knowledge_root", DEFAULT_KNOWLEDGE_ROOT.to_s))
  question = flags.fetch("source_question")
  reason = flags.fetch("confidence_reason")
  gap_id = flags["gap_id"] || "gap-#{slug(question)[0, 48].gsub(/-\z/, "")}"
  path = knowledge_root.join("gaps", "open", "#{gap_id}.md")
  now = Time.now.utc.iso8601
  existing = path.file? ? front_matter(path.read) : {}
  deterministic = flags["deterministic_complexity"] || classify(reason, question)
  final = flags["final_complexity"] || flags["agent_complexity"] || deterministic

  front = {
    "kind" => "knowledge_gap",
    "gap_id" => gap_id,
    "status" => "open",
    "persona_id" => flags.fetch("persona_id", "default"),
    "source_question" => question,
    "confidence_reason" => reason,
    "trace_id" => flags.fetch("trace_id", "trace-unavailable"),
    "deterministic_complexity" => deterministic,
    "agent_complexity" => flags["agent_complexity"],
    "final_complexity" => final,
    "allowed_resolution_path" => flags["allowed_resolution_path"] || resolution_path(final),
    "linked_package_id" => flags["linked_package_id"],
    "relevant_graph_nodes" => Array(flags["relevant_graph_nodes"]).flat_map { |value| value.to_s.split(",") }.map(&:strip).reject(&:empty?),
    "created_at" => existing["created_at"] || now,
    "updated_at" => now
  }

  write_record(path, front, "## Clarification Need\n\n#{reason}\n")
  puts JSON.pretty_generate({ "status" => "open", "gap_id" => gap_id, "path" => path.relative_path_from(ROOT).to_s })
end

def create_conflict(flags)
  knowledge_root = Pathname.new(flags.fetch("knowledge_root", DEFAULT_KNOWLEDGE_ROOT.to_s))
  summary = flags.fetch("summary")
  conflict_id = flags["conflict_id"] || "conflict-#{slug(summary)[0, 48].gsub(/-\z/, "")}"
  path = knowledge_root.join("conflicts", "open", "#{conflict_id}.md")
  now = Time.now.utc.iso8601

  front = {
    "kind" => "knowledge_conflict",
    "conflict_id" => conflict_id,
    "status" => "open",
    "persona_id" => flags.fetch("persona_id", "default"),
    "summary" => summary,
    "resolution_package_mode" => "conflict_resolution",
    "linked_package_id" => flags["linked_package_id"],
    "created_at" => now,
    "updated_at" => now
  }

  write_record(path, front, "## Conflict\n\n#{summary}\n")
  puts JSON.pretty_generate({ "status" => "open", "conflict_id" => conflict_id, "path" => path.relative_path_from(ROOT).to_s })
end

def resolve_gap(flags)
  knowledge_root = Pathname.new(flags.fetch("knowledge_root", DEFAULT_KNOWLEDGE_ROOT.to_s))
  gap_id = flags.fetch("gap_id")
  open_path = knowledge_root.join("gaps", "open", "#{gap_id}.md")
  stable_error("GAP_NOT_FOUND", "Open gap not found: #{gap_id}") unless open_path.file?
  data = front_matter(open_path.read)
  data["status"] = "resolved"
  data["linked_package_id"] = flags["linked_package_id"] if flags["linked_package_id"]
  data["updated_at"] = Time.now.utc.iso8601
  resolved_path = knowledge_root.join("gaps", "resolved", "#{gap_id}.md")
  write_record(resolved_path, data, open_path.read.split("---", 3).fetch(2, "").strip)
  open_path.delete
  puts JSON.pretty_generate({ "status" => "resolved", "gap_id" => gap_id, "path" => resolved_path.relative_path_from(ROOT).to_s })
end

def list_gaps(flags)
  knowledge_root = Pathname.new(flags.fetch("knowledge_root", DEFAULT_KNOWLEDGE_ROOT.to_s))
  paths = Dir.glob(knowledge_root.join("gaps", "open", "*.md")).sort
  records = paths.map do |path|
    data = front_matter(File.read(path))
    missing = REQUIRED_GAP_KEYS.reject { |key| data.key?(key) && !data[key].to_s.empty? }
    stable_error("GAP_FRONT_MATTER_INVALID", "#{path} is missing #{missing.join(", ")}") unless missing.empty?
    {
      "gap_id" => data.fetch("gap_id"),
      "status" => data.fetch("status"),
      "source_question" => data.fetch("source_question"),
      "allowed_resolution_path" => data.fetch("allowed_resolution_path"),
      "final_complexity" => data.fetch("final_complexity"),
      "path" => Pathname.new(path).relative_path_from(ROOT).to_s
    }
  end
  puts JSON.pretty_generate(records)
end

command = ARGV.shift || stable_error("INVALID_ARGUMENT", "Missing lifecycle command.")
flags = parse_flags(ARGV)

case command
when "create-gap"
  create_gap(flags)
when "create-conflict"
  create_conflict(flags)
when "resolve-gap"
  resolve_gap(flags)
when "list-gaps"
  list_gaps(flags)
else
  stable_error("INVALID_ARGUMENT", "Unknown lifecycle command: #{command}")
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "pathname"
require "rbconfig"

ROOT = Pathname.new(__dir__).join("..").expand_path
DEFAULT_KNOWLEDGE_ROOT = ROOT.join("knowledge")

STRATEGIES = {
  "factual" => ["claim", "citation", "source_artifact", "validation_result"],
  "decision" => ["decision", "tradeoff", "option", "assumption", "citation", "validation_result"],
  "uncertainty" => ["assumption", "open_question", "source_gap", "confidence_assessment", "validation_result"],
  "concept_explanation" => ["concept", "claim", "citation", "knowledge_note"],
  "gap_oriented" => ["source_gap", "open_question", "validation_result", "knowledge_note"]
}.freeze

def usage
  abort "Usage: ruby scripts/answer-context-selector.rb --query QUERY --graph PATH [--knowledge-root PATH] [--agent-answer-type TYPE]"
end

def parse_args(argv)
  flags = { "knowledge_root" => DEFAULT_KNOWLEDGE_ROOT.to_s }
  until argv.empty?
    key = argv.shift
    usage unless key.start_with?("--")
    flags[key.delete_prefix("--").tr("-", "_")] = argv.shift || usage
  end
  usage unless flags["query"] && flags["graph"]
  flags
end

def deterministic_type(query)
  text = query.downcase
  return "gap_oriented" if text.match?(/\b(missing|need from me|gap|unresolved|clarify)\b/)
  return "decision" if text.match?(/\b(why|decision|decide|decided|choose|chosen|tradeoff)\b/)
  return "uncertainty" if text.match?(/\b(unknown|uncertain|risk|assumption|confidence)\b/)
  return "concept_explanation" if text.match?(/\b(what is|explain|concept|how does|describe)\b/)

  "factual"
end

def front_matter(markdown)
  lines = markdown.lines
  return {} unless lines.first&.strip == "---"
  closing = lines[1..].find_index { |line| line.strip == "---" }
  return {} if closing.nil?

  lines[1, closing].each_with_object({}) do |line, data|
    key, value = line.split(":", 2)
    data[key.strip] = value.strip if key && value
  end
end

def open_conflicts(knowledge_root)
  Dir.glob(Pathname.new(knowledge_root).join("conflicts", "open", "*.md")).sort.map do |path|
    data = front_matter(File.read(path))
    data.merge("path" => Pathname.new(path).to_s)
  end
end

def relevant_conflicts(query, conflicts)
  text = query.downcase
  conflicts.select do |conflict|
    summary = conflict.fetch("summary", "").downcase
    text.include?("conflict") || summary.split(/\W+/).any? { |word| word.length > 5 && text.include?(word) }
  end
end

def create_conflict_gap(query, knowledge_root, conflicts)
  return nil if conflicts.empty?

  first = conflicts.first
  stdout, stderr, status = Open3.capture3(
    RbConfig.ruby,
    ROOT.join("scripts", "knowledge-gap-lifecycle.rb").to_s,
    "create-gap",
    "--knowledge-root", knowledge_root.to_s,
    "--gap-id", "gap-conflict-affects-answer",
    "--source-question", query,
    "--confidence-reason", "conflict affects answer confidence: #{first.fetch("summary")}",
    "--trace-id", "answer-context-selector",
    "--deterministic-complexity", "reasoning_heavy"
  )
  raise stderr unless status.success?

  JSON.parse(stdout)
end

flags = parse_args(ARGV)
query = flags.fetch("query")
graph = JSON.parse(File.read(flags.fetch("graph")))
deterministic = deterministic_type(query)
agent = flags["agent_answer_type"]
final = agent && STRATEGIES.key?(agent) ? agent : deterministic
selected_types = STRATEGIES.fetch(final)
selected_nodes = graph.fetch("nodes").select { |node| selected_types.include?(node.fetch("type")) }
conflicts = relevant_conflicts(query, open_conflicts(flags.fetch("knowledge_root")))
gap = create_conflict_gap(query, flags.fetch("knowledge_root"), conflicts)

result = {
  "trace" => {
    "deterministic_answer_type" => deterministic,
    "agent_answer_type" => agent,
    "final_answer_type" => final,
    "context_strategy" => "#{final}:#{selected_types.join(",")}"
  },
  "selected_node_types" => selected_types,
  "selected_nodes" => selected_nodes.map { |node| node.slice("node_id", "label", "type", "source_paths") },
  "conflicts" => conflicts.map { |conflict| conflict.slice("conflict_id", "summary", "path") },
  "gap_created" => gap
}

puts JSON.pretty_generate(result)

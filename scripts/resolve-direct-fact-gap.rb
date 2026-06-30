#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "pathname"
require "rbconfig"
require "tmpdir"
require "time"

ROOT = Pathname.new(__dir__).join("..").expand_path
DEFAULT_KNOWLEDGE_ROOT = ROOT.join("knowledge")

def usage
  abort "Usage: ./scripts/m3.sh gaps resolve-fact <gap-id> --answer TEXT [--knowledge-root PATH] [--persona-id ID] [--package-id ID]"
end

def stable_error(code, message)
  warn "#{code}: #{message}"
  exit 1
end

def slug(value)
  value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
end

def parse_args(argv)
  usage if argv.empty?
  gap_id = argv.shift
  flags = { "knowledge_root" => DEFAULT_KNOWLEDGE_ROOT.to_s, "persona_id" => "default" }

  until argv.empty?
    flag = argv.shift
    usage unless flag.start_with?("--")
    flags[flag.delete_prefix("--").tr("-", "_")] = argv.shift || usage
  end

  stable_error("DIRECT_FACT_ANSWER_REQUIRED", "Direct fact resolution requires a non-empty --answer.") if flags["answer"].to_s.strip.empty?
  [gap_id, flags]
end

def front_matter(markdown)
  lines = markdown.lines
  stable_error("FRONT_MATTER_MISSING", "Gap record is missing front matter.") unless lines.first&.strip == "---"
  closing = lines[1..].find_index { |line| line.strip == "---" }
  stable_error("FRONT_MATTER_MISSING", "Gap record front matter is not closed.") if closing.nil?

  lines[1, closing].each_with_object({}) do |line, data|
    next if line.strip.empty?
    key, value = line.split(":", 2)
    stable_error("FRONT_MATTER_INVALID", "Invalid gap front matter line: #{line.strip}") if value.nil?
    data[key.strip] = value.strip == "null" ? nil : value.strip
  end
end

def run_or_fail(code, message, *command)
  stdout, stderr, status = Open3.capture3(*command)
  stable_error(code, "#{message}: #{stderr.strip.empty? ? stdout.strip : stderr.strip}") unless status.success?
  stdout
end

def write_package(package_dir, package_id, gap_id, persona_id, question, answer)
  created_at = Time.now.utc.iso8601
  package_dir.join("decision-log.md").write(<<~MARKDOWN)
    # Direct Fact Decision Log

    ## Package ID
    #{package_id}

    ## Persona ID
    #{persona_id}

    ## Package Mode
    direct_fact_resolution

    ## Direct Fact Resolution
    Captured a simple factual answer from chat for gap `#{gap_id}`.

    ## Conversation Goal
    Resolve the simple factual knowledge gap `#{gap_id}`.

    ## Questions Asked
    - #{question}

    ## Options Considered
    - Resolve the factual gap directly in chat.
    - Require a full decision-log package.

    ## Pros and Cons
    - Direct chat resolution: appropriate for a simple factual answer; preserves validation and provenance through an internal package.
    - Full decision-log package: appropriate for reasoning-heavy gaps; unnecessary for this simple factual answer.

    ## Recommendation
    Use the direct chat answer as an internal mini decision-log package.

    ## Assumptions
    - The open gap is classified as simple_factual.

    ## Challenged Assumptions
    - Every gap requires a full external decision-log package.

    ## Decisions
    - Gap `#{gap_id}` is resolved through direct fact resolution.

    ## Claims
    - #{answer}

    ## Confidence Assessment
    Direct user-provided factual answer; deterministic validation required before ingestion.

    ## Citations
    - Direct chat answer for gap `#{gap_id}`.

    ## Remaining Non-Blocking Open Questions
    - None.

    ## Blocking Clarifications
    None.
  MARKDOWN

  package_dir.join("knowledge-note.md").write(<<~MARKDOWN)
    # Direct Fact Knowledge Note

    ## Package ID
    #{package_id}

    ## Title
    Direct fact resolution for #{gap_id}

    ## Summary
    #{answer}

    ## Supported Claims
    - #{answer}

    ## Decisions To Remember
    - Gap `#{gap_id}` is resolved through direct fact resolution.

    ## Assumptions To Revisit
    - None.

    ## Provenance
    Distilled from `decision-log.md`.
  MARKDOWN

  package_dir.join("metadata.json").write(JSON.pretty_generate({
    "schema_version" => "1.0.0",
    "package_id" => package_id,
    "persona_id" => persona_id,
    "mode" => "direct_fact_resolution",
    "created_by" => "youaskm3.reasoning-assistant",
    "created_at" => created_at,
    "source_gap_id" => gap_id,
    "required_files" => ["decision-log.md", "knowledge-note.md", "metadata.json"]
  }) + "\n")
end

gap_id, flags = parse_args(ARGV)
knowledge_root = Pathname.new(flags.fetch("knowledge_root")).expand_path
gap_path = knowledge_root.join("gaps", "open", "#{gap_id}.md")
stable_error("GAP_NOT_FOUND", "Open gap not found: #{gap_id}") unless gap_path.file?

gap = front_matter(gap_path.read)
unless gap["status"] == "open" && gap["final_complexity"] == "simple_factual" && gap["allowed_resolution_path"] == "direct_chat"
  stable_error("GAP_REQUIRES_DECISION_LOG_PACKAGE", "Gap #{gap_id} is not eligible for direct chat resolution; use a decision-log package.")
end

answer = flags.fetch("answer").strip.gsub(/\s+/, " ")
stable_error("DIRECT_FACT_ANSWER_REQUIRED", "Direct fact resolution requires a non-empty --answer.") if answer.empty?
package_id = flags["package_id"] || "decision-log-#{Time.now.utc.strftime("%Y%m%d")}-#{slug(gap_id)}-direct-fact"

Dir.mktmpdir("youaskm3-direct-fact-") do |dir|
  package_dir = Pathname.new(dir).join(package_id)
  FileUtils.mkdir_p(package_dir)
  write_package(package_dir, package_id, gap_id, flags.fetch("persona_id"), gap.fetch("source_question"), answer)

  ingest_stdout = run_or_fail(
    "DIRECT_FACT_INGEST_FAILED",
    "Internal direct fact package ingestion failed",
    RbConfig.ruby,
    ROOT.join("scripts", "ingest-decision-log.rb").to_s,
    package_dir.to_s,
    "--knowledge-root",
    knowledge_root.to_s
  )
  ingest_result = JSON.parse(ingest_stdout)

  resolve_stdout = run_or_fail(
    "DIRECT_FACT_GAP_UPDATE_FAILED",
    "Direct fact package ingested but gap resolution failed",
    RbConfig.ruby,
    ROOT.join("scripts", "knowledge-gap-lifecycle.rb").to_s,
    "resolve-gap",
    "--knowledge-root",
    knowledge_root.to_s,
    "--gap-id",
    gap_id,
    "--linked-package-id",
    package_id
  )

  run_or_fail("DIRECT_FACT_SYNC_FAILED", "Direct fact package ingested but graph sync failed", "bash", ROOT.join("scripts", "m3-sync.sh").to_s) if knowledge_root == DEFAULT_KNOWLEDGE_ROOT

  puts JSON.pretty_generate({
    "status" => "direct_fact_resolved",
    "gap_id" => gap_id,
    "package_id" => package_id,
    "package_path" => ingest_result.fetch("package_path"),
    "knowledge_note_path" => ingest_result.fetch("knowledge_note_path"),
    "gap_update" => JSON.parse(resolve_stdout)
  })
end

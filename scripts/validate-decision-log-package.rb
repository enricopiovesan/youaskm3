#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path
REQUIRED_FILES = ["decision-log.md", "knowledge-note.md", "metadata.json"].freeze
ALLOWED_MODES = ["knowledge_addition", "gap_resolution", "direct_fact_resolution", "conflict_resolution"].freeze
ARCHIVE_EXTENSIONS = [".zip", ".tar", ".tgz", ".tar.gz", ".gz"].freeze
PACKAGE_ID_PATTERN = /\Adecision-log-\d{8}-[a-z0-9]+(?:-[a-z0-9]+)*\z/
SEMANTIC_STATES = ["unavailable", "passed", "failed"].freeze

DECISION_SECTIONS = [
  "Package ID",
  "Persona ID",
  "Package Mode",
  "Conversation Goal",
  "Questions Asked",
  "Options Considered",
  "Pros and Cons",
  "Recommendation",
  "Assumptions",
  "Challenged Assumptions",
  "Decisions",
  "Claims",
  "Confidence Assessment",
  "Citations",
  "Remaining Non-Blocking Open Questions",
  "Blocking Clarifications"
].freeze

NOTE_SECTIONS = [
  "Package ID",
  "Title",
  "Summary",
  "Supported Claims",
  "Decisions To Remember",
  "Assumptions To Revisit",
  "Provenance"
].freeze

MODE_SECTION = {
  "knowledge_addition" => "Knowledge Addition",
  "gap_resolution" => "Gap Resolution",
  "direct_fact_resolution" => "Direct Fact Resolution",
  "conflict_resolution" => "Conflict Resolution"
}.freeze

def usage
  abort "Usage: ruby scripts/validate-decision-log-package.rb <package-dir> [--semantic-validation unavailable|passed|failed]"
end

def parse_args(argv)
  usage if argv.empty?
  path = argv.shift
  semantic = "unavailable"

  until argv.empty?
    flag = argv.shift
    case flag
    when "--semantic-validation"
      semantic = argv.shift || usage
    else
      usage
    end
  end

  usage unless SEMANTIC_STATES.include?(semantic)
  [Pathname.new(path), semantic]
end

def section_map(markdown)
  sections = {}
  current = nil

  markdown.each_line do |line|
    if (match = line.match(/\A##\s+(.+?)\s*\z/))
      current = match[1]
      sections[current] = +""
    elsif current
      sections[current] << line
    end
  end

  sections.transform_values(&:strip)
end

def bullets(section)
  section.each_line.each_with_object([]) do |line, values|
    match = line.match(/\A-\s+(.+?)\s*\z/)
    values << match[1].strip if match
  end
end

def json_result(ok:, package_id: nil, mode: nil, errors: [], semantic: "unavailable")
  result = {
    "valid" => ok,
    "package_id" => package_id,
    "mode" => mode,
    "errors" => errors,
    "validation" => {
      "deterministic" => ok && semantic != "failed" ? "passed" : "failed",
      "semantic" => {
        "status" => semantic
      }
    }
  }

  if semantic == "failed"
    result["valid"] = false
    result["errors"] << {
      "code" => "SEMANTIC_VALIDATION_FAILED",
      "message" => "Traverse semantic validation rejected the decision-log package."
    }
    result["gap_creation"] = {
      "kind" => "knowledge_gap",
      "source_package_id" => package_id,
      "reason" => "semantic_validation_failed"
    }
  end

  result
end

def add_error(errors, code, message)
  errors << { "code" => code, "message" => message }
end

package_path, semantic = parse_args(ARGV)
errors = []

if ARCHIVE_EXTENSIONS.any? { |ext| package_path.to_s.end_with?(ext) }
  result = json_result(ok: false, errors: [{ "code" => "ARCHIVE_INPUT_UNSUPPORTED", "message" => "Decision-log package input must be a directory, not an archive." }], semantic: semantic)
  puts JSON.pretty_generate(result)
  exit 1
end

unless package_path.directory?
  result = json_result(ok: false, errors: [{ "code" => "PACKAGE_NOT_DIRECTORY", "message" => "Decision-log package input must be a directory." }], semantic: semantic)
  puts JSON.pretty_generate(result)
  exit 1
end

missing_files = REQUIRED_FILES.reject { |file| package_path.join(file).file? }
unless missing_files.empty?
  missing_files.each { |file| add_error(errors, "MISSING_REQUIRED_FILE", "Missing required package file: #{file}") }
  puts JSON.pretty_generate(json_result(ok: false, errors: errors, semantic: semantic))
  exit 1
end

metadata = nil
begin
  metadata = JSON.parse(package_path.join("metadata.json").read)
rescue JSON::ParserError => error
  add_error(errors, "INVALID_METADATA_JSON", "metadata.json is not valid JSON: #{error.message}")
end

if metadata
  required_metadata = ["schema_version", "package_id", "persona_id", "mode", "created_by", "created_at", "source_gap_id", "required_files"]
  (required_metadata - metadata.keys).each { |key| add_error(errors, "METADATA_FIELD_MISSING", "metadata.json is missing #{key}") }

  package_id = metadata["package_id"]
  mode = metadata["mode"]
  add_error(errors, "UNSUPPORTED_PACKAGE_ID", "metadata.json package_id must match #{PACKAGE_ID_PATTERN.inspect}") unless package_id.is_a?(String) && package_id.match?(PACKAGE_ID_PATTERN)
  add_error(errors, "UNSUPPORTED_PACKAGE_MODE", "metadata.json mode must be one of #{ALLOWED_MODES.join(", ")}") unless ALLOWED_MODES.include?(mode)
  add_error(errors, "UNSUPPORTED_SCHEMA_VERSION", "metadata.json schema_version must be 1.0.0") unless metadata["schema_version"] == "1.0.0"
  add_error(errors, "UNSUPPORTED_CREATED_BY", "metadata.json created_by must be youaskm3.reasoning-assistant") unless metadata["created_by"] == "youaskm3.reasoning-assistant"

  unless metadata["required_files"].is_a?(Array) && metadata["required_files"].sort == REQUIRED_FILES.sort
    add_error(errors, "REQUIRED_FILES_MISMATCH", "metadata.json required_files must contain decision-log.md, knowledge-note.md, and metadata.json")
  end

  if mode == "gap_resolution" && (!metadata["source_gap_id"].is_a?(String) || metadata["source_gap_id"].empty?)
    add_error(errors, "SOURCE_GAP_ID_REQUIRED", "gap_resolution packages require source_gap_id")
  end
end

decision = section_map(package_path.join("decision-log.md").read)
note = section_map(package_path.join("knowledge-note.md").read)

DECISION_SECTIONS.each do |section|
  value = decision[section]
  add_error(errors, "DECISION_SECTION_MISSING", "decision-log.md is missing ## #{section}") if value.nil? || value.empty?
end

NOTE_SECTIONS.each do |section|
  value = note[section]
  add_error(errors, "NOTE_SECTION_MISSING", "knowledge-note.md is missing ## #{section}") if value.nil? || value.empty?
end

if metadata
  package_id = metadata["package_id"]
  mode = metadata["mode"]
  mode_section = MODE_SECTION[mode]

  add_error(errors, "MODE_SECTION_MISSING", "decision-log.md is missing ## #{mode_section}") if mode_section && decision[mode_section].to_s.empty?
  add_error(errors, "PACKAGE_ID_MISMATCH", "decision-log.md package id does not match metadata.json") unless decision["Package ID"].to_s.include?(package_id.to_s)
  add_error(errors, "PACKAGE_ID_MISMATCH", "knowledge-note.md package id does not match metadata.json") unless note["Package ID"].to_s.include?(package_id.to_s)
  add_error(errors, "MODE_MISMATCH", "decision-log.md package mode does not match metadata.json") unless decision["Package Mode"].to_s.include?(mode.to_s)

  if !decision["Blocking Clarifications"].to_s.match?(/\b[Nn]one\b/)
    add_error(errors, "BLOCKING_CLARIFICATIONS_OPEN", "decision-log.md must state that no blocking clarifications remain")
  end

  decision_claims = bullets(decision["Claims"].to_s)
  note_claims = bullets(note["Supported Claims"].to_s)
  unsupported = note_claims - decision_claims
  unsupported.each { |claim| add_error(errors, "UNSUPPORTED_KNOWLEDGE_NOTE_CLAIM", "knowledge-note.md claim is not supported by decision-log.md: #{claim}") }
end

ok = errors.empty?
result = json_result(ok: ok, package_id: metadata && metadata["package_id"], mode: metadata && metadata["mode"], errors: errors, semantic: semantic)
puts JSON.pretty_generate(result)
exit(ok && semantic != "failed" ? 0 : 1)

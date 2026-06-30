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
REQUIRED_PACKAGE_FILES = ["decision-log.md", "knowledge-note.md", "metadata.json"].freeze
ARCHIVE_EXTENSIONS = [".zip", ".tar", ".tgz", ".tar.gz", ".gz"].freeze

def usage
  abort "Usage: ./scripts/m3.sh ingest-decision-log <package-dir> [--knowledge-root PATH] [--offline]"
end

def parse_args(argv)
  usage if argv.empty?
  package_path = Pathname.new(argv.shift)
  knowledge_root = DEFAULT_KNOWLEDGE_ROOT
  offline = false

  until argv.empty?
    flag = argv.shift
    case flag
    when "--knowledge-root"
      knowledge_root = Pathname.new(argv.shift || usage)
    when "--offline"
      offline = true
    else
      usage
    end
  end

  [package_path.expand_path, knowledge_root.expand_path, offline]
end

def stable_error(code, message)
  warn "#{code}: #{message}"
  exit 1
end

def write_validation_gap(knowledge_root, validation, error)
  package_id = validation["package_id"] || "unknown-package"
  gap_id = "gap-#{package_id.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")}-validation"
  system(
    RbConfig.ruby,
    ROOT.join("scripts", "knowledge-gap-lifecycle.rb").to_s,
    "create-gap",
    "--knowledge-root", knowledge_root.to_s,
    "--gap-id", gap_id,
    "--source-question", "Decision-log package validation failed for #{package_id}",
    "--confidence-reason", error.fetch("message"),
    "--trace-id", "decision-log-validation",
    "--linked-package-id", package_id,
    out: File::NULL
  )
end

def archive_path?(path)
  ARCHIVE_EXTENSIONS.any? { |extension| path.to_s.end_with?(extension) }
end

def relative_to?(path, root)
  path.ascend.any? { |ancestor| ancestor == root }
end

def validate_knowledge_root!(knowledge_root)
  if knowledge_root == DEFAULT_KNOWLEDGE_ROOT
    FileUtils.mkdir_p(knowledge_root)
    return
  end

  marker = knowledge_root.join(".youaskm3-knowledge-root.json")
  stable_error("EXTERNAL_KNOWLEDGE_ROOT_UNINITIALIZED", "External knowledge roots must be initialized before writes: #{knowledge_root}") unless marker.file?
end

def sync_preflight!(knowledge_root)
  return unless knowledge_root == DEFAULT_KNOWLEDGE_ROOT

  author_instance = ROOT.join("app", "site", "author-instance.json")
  sync_state = ROOT.join("app", "site", "sync-state.json")
  stable_error("INSTANCE_NOT_INITIALIZED", "Run ./scripts/m3.sh init before ingesting decision-log packages.") unless author_instance.file?
  return unless sync_state.file?

  Dir.mktmpdir do |tmpdir|
    system(RbConfig.ruby, ROOT.join("scripts", "generate-site-artifacts.rb").to_s, tmpdir, out: File::NULL, err: File::NULL) ||
      stable_error("SYNC_PREFLIGHT_FAILED", "Unable to compute sync preflight state.")
    generated = Pathname.new(tmpdir).join("sync-state.json")
    unless generated.read == sync_state.read
      stable_error("SYNC_PREFLIGHT_DIRTY", "Current knowledge artifacts are stale. Run ./scripts/m3.sh sync before ingesting.")
    end
  end
end

def run_validator(package_path)
  stdout, stderr, status = Open3.capture3(RbConfig.ruby, ROOT.join("scripts", "validate-decision-log-package.rb").to_s, package_path.to_s)
  data = JSON.parse(stdout)
  [data, stderr, status.success?]
rescue JSON::ParserError => error
  stable_error("VALIDATOR_OUTPUT_INVALID", "Decision-log package validator returned invalid JSON: #{error.message}")
end

def copy_required_package_files(source, destination)
  FileUtils.mkdir_p(destination)
  REQUIRED_PACKAGE_FILES.each do |file|
    FileUtils.cp(source.join(file), destination.join(file))
  end
end

def write_provenance(destination, package_path, validation, offline)
  metadata = JSON.parse(destination.join("metadata.json").read)
  provenance = {
    "schema_version" => "1.0.0",
    "package_id" => metadata.fetch("package_id"),
    "persona_id" => metadata.fetch("persona_id"),
    "mode" => metadata.fetch("mode"),
    "original_import_path" => package_path.to_s,
    "imported_at" => Time.now.utc.iso8601,
    "ingestion_status" => offline ? "staged_offline" : "accepted",
    "validation_evidence" => validation.fetch("validation"),
    "traverse" => {
      "semantic_validation" => validation.fetch("validation").fetch("semantic").fetch("status")
    }
  }
  destination.join("ingestion-provenance.json").write(JSON.pretty_generate(provenance) + "\n")
end

def write_normalized_note(knowledge_root, package_id, package_destination)
  notes_dir = knowledge_root.join("notes", "decision-logs")
  FileUtils.mkdir_p(notes_dir)
  note = package_destination.join("knowledge-note.md").read
  notes_dir.join("#{package_id}.md").write(<<~MARKDOWN)
    ---
    source_package: knowledge/sources/decision-logs/#{package_id}
    source_decision_log: knowledge/sources/decision-logs/#{package_id}/decision-log.md
    provenance: decision-log-package
    ---

    #{note}
  MARKDOWN
end

package_path, knowledge_root, offline = parse_args(ARGV)
stable_error("ARCHIVE_INPUT_UNSUPPORTED", "Decision-log package input must be a directory, not an archive.") if archive_path?(package_path)
stable_error("PACKAGE_NOT_DIRECTORY", "Decision-log package input must be a directory.") unless package_path.directory?

validate_knowledge_root!(knowledge_root)
sync_preflight!(knowledge_root)

validation, validator_stderr, ok = run_validator(package_path)
unless ok && validation.fetch("valid")
  first_error = validation.fetch("errors").first || { "code" => "PACKAGE_VALIDATION_FAILED", "message" => validator_stderr }
  write_validation_gap(knowledge_root, validation, first_error)
  stable_error(first_error.fetch("code"), first_error.fetch("message"))
end

package_id = validation.fetch("package_id")
destination_root = offline ? knowledge_root.join("sources", "decision-logs", ".staged") : knowledge_root.join("sources", "decision-logs")
destination = destination_root.join(package_id)
stable_error("PACKAGE_ALREADY_EXISTS", "Decision-log package already exists: #{destination}") if destination.exist?

copy_required_package_files(package_path, destination)
write_provenance(destination, package_path, validation, offline)
write_normalized_note(knowledge_root, package_id, destination) unless offline

result = {
  "status" => offline ? "staged_offline" : "accepted",
  "package_id" => package_id,
  "package_path" => destination.relative_path_from(ROOT).to_s,
  "knowledge_note_path" => offline ? nil : knowledge_root.join("notes", "decision-logs", "#{package_id}.md").relative_path_from(ROOT).to_s
}

puts JSON.pretty_generate(result)

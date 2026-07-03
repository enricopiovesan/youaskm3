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
DEFAULT_MAX_ARCHIVE_BYTES = 5 * 1024 * 1024
$collect_failures = false

class ImportFailure < StandardError
  attr_reader :result

  def initialize(result)
    @result = result
    super(result.fetch("error").fetch("message"))
  end
end

def usage
  abort <<~USAGE
    Usage:
      ./scripts/m3.sh import-decision-log archive <package.zip> [--knowledge-root PATH] [--offline] [--max-archive-bytes N]
      ./scripts/m3.sh import-decision-log inbox <inbox-dir> [--knowledge-root PATH] [--offline] [--max-archive-bytes N]
  USAGE
end

def parse_common_options(argv)
  knowledge_root = DEFAULT_KNOWLEDGE_ROOT
  offline = false
  max_archive_bytes = DEFAULT_MAX_ARCHIVE_BYTES

  until argv.empty?
    flag = argv.shift
    case flag
    when "--knowledge-root"
      knowledge_root = Pathname.new(argv.shift || usage)
    when "--offline"
      offline = true
    when "--max-archive-bytes"
      max_archive_bytes = Integer(argv.shift || usage, exception: false) || usage
    else
      usage
    end
  end

  [knowledge_root.expand_path, offline, max_archive_bytes]
end

def json_result(status:, source_path:, package_id: nil, ingestion: nil, error: nil, result_path: nil)
  result = {
    "status" => status,
    "source_path" => source_path.to_s,
    "package_id" => package_id,
    "ingestion" => ingestion,
    "error" => error
  }
  result["result_path"] = result_path.to_s if result_path
  result
end

def stable_failure(code, message, source_path)
  result = json_result(
    status: "rejected",
    source_path: source_path,
    error: { "code" => code, "message" => message }
  )
  raise ImportFailure, result if $collect_failures

  puts JSON.pretty_generate(result)
  exit 1
end

def archive?(path)
  path.to_s.end_with?(".zip")
end

def list_zip_entries(archive_path)
  stdout, stderr, status = Open3.capture3("unzip", "-l", archive_path.to_s)
  stable_failure("ARCHIVE_LIST_FAILED", stderr.strip.empty? ? "Unable to list archive entries." : stderr.strip, archive_path) unless status.success?

  entries = []
  stdout.each_line do |line|
    next unless (match = line.match(/\A\s*(\d+)\s+\S+\s+\d{2}:\d{2}\s+(.+?)\s*\z/))

    entries << { "bytes" => Integer(match[1]), "name" => match[2] }
  end
  entries
end

def validate_zip_entries!(archive_path, entries, max_archive_bytes)
  stable_failure("ARCHIVE_EMPTY", "Archive contains no package files.", archive_path) if entries.empty?

  total_bytes = entries.sum { |entry| entry.fetch("bytes") }
  if total_bytes > max_archive_bytes
    stable_failure("ARCHIVE_TOO_LARGE", "Archive expands to #{total_bytes} bytes, above limit #{max_archive_bytes}.", archive_path)
  end

  entries.each do |entry|
    name = entry.fetch("name")
    clean = Pathname.new(name).cleanpath.to_s
    if name.start_with?("/", "\\") || clean == "." || clean.start_with?("../") || clean == ".." || clean.include?("/../")
      stable_failure("ARCHIVE_UNSAFE_PATH", "Archive entry escapes extraction root: #{name}", archive_path)
    end
  end
end

def extract_zip(archive_path, destination)
  stdout, stderr, status = Open3.capture3("unzip", "-q", archive_path.to_s, "-d", destination.to_s)
  return if status.success?

  stable_failure("ARCHIVE_EXTRACT_FAILED", stderr.strip.empty? ? stdout.strip : stderr.strip, archive_path)
end

def package_dir_from_extraction(extract_root, source_path)
  candidates = [extract_root] + extract_root.children.select(&:directory?)
  package_dirs = candidates.select do |candidate|
    REQUIRED_PACKAGE_FILES.all? { |file| candidate.join(file).file? }
  end

  if package_dirs.empty?
    stable_failure("ARCHIVE_PACKAGE_FILES_MISSING", "Archive does not contain a decision-log package with required files.", source_path)
  end
  if package_dirs.length > 1
    stable_failure("ARCHIVE_AMBIGUOUS_PACKAGE", "Archive contains multiple decision-log package roots.", source_path)
  end

  package_dirs.first
end

def validate_package_before_write!(package_dir, source_path)
  stdout, stderr, status = Open3.capture3(RbConfig.ruby, ROOT.join("scripts", "validate-decision-log-package.rb").to_s, package_dir.to_s)
  validation = JSON.parse(stdout)
  return validation if status.success? && validation.fetch("valid")

  first_error = validation.fetch("errors").first || { "code" => "PACKAGE_VALIDATION_FAILED", "message" => stderr }
  stable_failure(first_error.fetch("code"), first_error.fetch("message"), source_path)
rescue JSON::ParserError => error
  stable_failure("VALIDATOR_OUTPUT_INVALID", "Decision-log package validator returned invalid JSON: #{error.message}", source_path)
end

def ingest_package(package_dir, source_path, knowledge_root, offline)
  args = [
    RbConfig.ruby,
    ROOT.join("scripts", "ingest-decision-log.rb").to_s,
    package_dir.to_s,
    "--knowledge-root", knowledge_root.to_s,
    "--original-import-path", source_path.to_s
  ]
  args << "--offline" if offline

  stdout, stderr, status = Open3.capture3(*args)
  if status.success?
    ingestion = JSON.parse(stdout)
    status_name = ingestion.fetch("status") == "staged_offline" ? "staged" : "ingested"
    return json_result(
      status: status_name,
      source_path: source_path,
      package_id: ingestion.fetch("package_id"),
      ingestion: ingestion
    )
  end

  code = stderr[/\A([A-Z0-9_]+):/, 1] || "IMPORT_BLOCKED"
  json_result(
    status: "blocked",
    source_path: source_path,
    error: { "code" => code, "message" => stderr.strip.empty? ? stdout.strip : stderr.strip }
  )
rescue JSON::ParserError => error
  json_result(
    status: "blocked",
    source_path: source_path,
    error: { "code" => "INGEST_OUTPUT_INVALID", "message" => "Decision-log ingestion returned invalid JSON: #{error.message}" }
  )
end

def import_archive(archive_path, knowledge_root, offline, max_archive_bytes)
  stable_failure("ARCHIVE_INPUT_REQUIRED", "Archive import requires a .zip package.", archive_path) unless archive?(archive_path)
  stable_failure("ARCHIVE_NOT_FOUND", "Archive does not exist: #{archive_path}", archive_path) unless archive_path.file?

  entries = list_zip_entries(archive_path)
  validate_zip_entries!(archive_path, entries, max_archive_bytes)

  Dir.mktmpdir("youaskm3-decision-log-import-") do |temp|
    extract_root = Pathname.new(temp)
    extract_zip(archive_path, extract_root)
    package_dir = package_dir_from_extraction(extract_root, archive_path)
    validate_package_before_write!(package_dir, archive_path)
    ingest_package(package_dir, archive_path, knowledge_root, offline)
  end
end

def import_directory(package_dir, knowledge_root, offline)
  validate_package_before_write!(package_dir, package_dir)
  ingest_package(package_dir, package_dir, knowledge_root, offline)
end

def result_records_dir(inbox_dir)
  inbox_dir.join(".youaskm3-import-results")
end

def write_inbox_result(inbox_dir, source_path, result)
  FileUtils.mkdir_p(result_records_dir(inbox_dir))
  slug = source_path.basename.to_s.gsub(/[^a-zA-Z0-9.-]+/, "-")
  result_path = result_records_dir(inbox_dir).join("#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}-#{slug}.json")
  result["result_path"] = result_path.to_s
  result_path.write(JSON.pretty_generate(result) + "\n")
  result
end

def import_inbox(inbox_dir, knowledge_root, offline, max_archive_bytes)
  stable_failure("INBOX_NOT_DIRECTORY", "Inbox path must be a directory: #{inbox_dir}", inbox_dir) unless inbox_dir.directory?

  entries = inbox_dir.children.reject { |entry| entry.basename.to_s == ".youaskm3-import-results" }.sort_by(&:to_s)
  results = entries.map do |entry|
    result = nil
    begin
      $collect_failures = true
      result =
        if entry.directory?
          import_directory(entry, knowledge_root, offline)
        elsif archive?(entry)
          import_archive(entry, knowledge_root, offline, max_archive_bytes)
        else
          json_result(
            status: "rejected",
            source_path: entry,
            error: { "code" => "INBOX_UNSUPPORTED_ENTRY", "message" => "Inbox entries must be package directories or .zip archives." }
          )
        end
    rescue ImportFailure => error
      result = error.result
    ensure
      $collect_failures = false
    end
    write_inbox_result(inbox_dir, entry, result)
  end

  {
    "status" => "processed",
    "inbox_path" => inbox_dir.to_s,
    "counts" => results.each_with_object(Hash.new(0)) { |result, counts| counts[result.fetch("status")] += 1 },
    "results" => results
  }
end

command = ARGV.shift || usage
source = Pathname.new(ARGV.shift || usage).expand_path
knowledge_root, offline, max_archive_bytes = parse_common_options(ARGV)

case command
when "archive"
  puts JSON.pretty_generate(import_archive(source, knowledge_root, offline, max_archive_bytes))
when "inbox"
  puts JSON.pretty_generate(import_inbox(source, knowledge_root, offline, max_archive_bytes))
else
  usage
end

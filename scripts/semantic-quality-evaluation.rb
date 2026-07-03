#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "pathname"
require "rbconfig"
require "time"

ROOT = Pathname.new(__dir__).join("..").expand_path
DEFAULT_KNOWLEDGE_ROOT = ROOT.join("knowledge")
VALID_CLAIM_STATUSES = ["accepted", "rejected"].freeze

def usage
  abort <<~USAGE
    Usage:
      ./scripts/m3.sh semantic-quality partial-ingest <package-dir> <claim-validation.json> [--knowledge-root PATH]
      ./scripts/m3.sh semantic-quality benchmark <benchmark-corpus.json> [--report PATH]
  USAGE
end

def parse_options(argv)
  flags = {}
  until argv.empty?
    key = argv.shift
    usage unless key.start_with?("--")
    flags[key.delete_prefix("--").tr("-", "_")] = argv.shift || usage
  end
  flags
end

def stable_error(code, message)
  warn "#{code}: #{message}"
  exit 1
end

def read_json(path)
  JSON.parse(path.read)
rescue JSON::ParserError => error
  stable_error("INVALID_JSON", "#{path} is not valid JSON: #{error.message}")
end

def validate_claim_validation!(validation, package_id)
  stable_error("UNSUPPORTED_SCHEMA_VERSION", "Claim validation schema_version must be 1.0.0.") unless validation["schema_version"] == "1.0.0"
  stable_error("PACKAGE_ID_MISMATCH", "Claim validation package_id must match package metadata.") unless validation["package_id"] == package_id

  claims = validation["claims"]
  stable_error("CLAIMS_MISSING", "Claim validation must include at least one claim.") unless claims.is_a?(Array) && !claims.empty?

  claim_ids = {}
  claims.each do |claim|
    ["claim_id", "text", "status", "reason", "provenance"].each do |key|
      stable_error("CLAIM_FIELD_MISSING", "Claim validation entry is missing #{key}.") unless claim.key?(key)
    end
    stable_error("CLAIM_ID_DUPLICATE", "Duplicate claim id: #{claim.fetch("claim_id")}") if claim_ids[claim.fetch("claim_id")]
    claim_ids[claim.fetch("claim_id")] = true
    stable_error("CLAIM_STATUS_UNSUPPORTED", "Claim status must be accepted or rejected.") unless VALID_CLAIM_STATUSES.include?(claim.fetch("status"))
    stable_error("CLAIM_TEXT_EMPTY", "Claim text cannot be empty.") if claim.fetch("text").to_s.strip.empty?
    stable_error("CLAIM_REASON_EMPTY", "Claim reason cannot be empty.") if claim.fetch("reason").to_s.strip.empty?
  end
end

def run_package_validator(package_dir)
  stdout, stderr, status = Open3.capture3(RbConfig.ruby, ROOT.join("scripts", "validate-decision-log-package.rb").to_s, package_dir.to_s)
  validation = JSON.parse(stdout)
  return validation if status.success? && validation.fetch("valid")

  first_error = validation.fetch("errors").first || { "code" => "PACKAGE_VALIDATION_FAILED", "message" => stderr }
  stable_error(first_error.fetch("code"), first_error.fetch("message"))
rescue JSON::ParserError => error
  stable_error("VALIDATOR_OUTPUT_INVALID", "Decision-log package validator returned invalid JSON: #{error.message}")
end

def write_accepted_claim(knowledge_root, package_id, claim)
  path = knowledge_root.join("claims", package_id, "#{claim.fetch("claim_id")}.json")
  FileUtils.mkdir_p(path.dirname)
  record = {
    "schema_version" => "1.0.0",
    "kind" => "accepted_claim",
    "package_id" => package_id,
    "claim_id" => claim.fetch("claim_id"),
    "text" => claim.fetch("text"),
    "status" => "accepted",
    "reason" => claim.fetch("reason"),
    "provenance" => claim.fetch("provenance"),
    "recorded_at" => Time.now.utc.iso8601
  }
  path.write(JSON.pretty_generate(record) + "\n")
  path
end

def create_rejected_claim_gap(knowledge_root, package_id, claim)
  gap_id = "gap-#{package_id}-#{claim.fetch("claim_id")}".gsub(/[^a-z0-9-]+/, "-")
  stdout, stderr, status = Open3.capture3(
    RbConfig.ruby,
    ROOT.join("scripts", "knowledge-gap-lifecycle.rb").to_s,
    "create-gap",
    "--knowledge-root", knowledge_root.to_s,
    "--gap-id", gap_id,
    "--source-question", "Validate rejected claim: #{claim.fetch("text")}",
    "--confidence-reason", claim.fetch("reason"),
    "--trace-id", "semantic-quality-partial-ingest",
    "--linked-package-id", package_id,
    "--deterministic-complexity", "reasoning_heavy"
  )
  stable_error("GAP_CREATION_FAILED", stderr.strip.empty? ? stdout.strip : stderr.strip) unless status.success?

  JSON.parse(stdout)
end

def write_partial_record(package_dir, knowledge_root, package_id, validation, accepted, rejected)
  record = {
    "schema_version" => "1.0.0",
    "package_id" => package_id,
    "status" => rejected.empty? ? "accepted" : "partial",
    "source_package_path" => package_dir.to_s,
    "accepted_claims" => accepted,
    "rejected_claims" => rejected,
    "claim_validation" => validation,
    "recorded_at" => Time.now.utc.iso8601
  }
  path = knowledge_root.join("sources", "decision-logs", package_id, "claim-validation.json")
  FileUtils.mkdir_p(path.dirname)
  path.write(JSON.pretty_generate(record) + "\n")
  path
end

def partial_ingest(argv)
  usage unless argv.length >= 2
  package_dir = Pathname.new(argv.shift).expand_path
  validation_path = Pathname.new(argv.shift).expand_path
  flags = parse_options(argv)
  knowledge_root = Pathname.new(flags.fetch("knowledge_root", DEFAULT_KNOWLEDGE_ROOT.to_s)).expand_path

  stable_error("PACKAGE_NOT_DIRECTORY", "Decision-log package input must be a directory.") unless package_dir.directory?
  stable_error("CLAIM_VALIDATION_NOT_FOUND", "Claim validation file does not exist: #{validation_path}") unless validation_path.file?

  package_validation = run_package_validator(package_dir)
  package_id = package_validation.fetch("package_id")
  claim_validation = read_json(validation_path)
  validate_claim_validation!(claim_validation, package_id)

  accepted = []
  rejected = []
  claim_validation.fetch("claims").each do |claim|
    if claim.fetch("status") == "accepted"
      path = write_accepted_claim(knowledge_root, package_id, claim)
      accepted << {
        "claim_id" => claim.fetch("claim_id"),
        "path" => path.relative_path_from(ROOT).to_s
      }
    else
      gap = create_rejected_claim_gap(knowledge_root, package_id, claim)
      rejected << {
        "claim_id" => claim.fetch("claim_id"),
        "gap_id" => gap.fetch("gap_id"),
        "path" => gap.fetch("path")
      }
    end
  end

  record_path = write_partial_record(package_dir, knowledge_root, package_id, claim_validation, accepted, rejected)
  puts JSON.pretty_generate(
    {
      "status" => rejected.empty? ? "accepted" : "partial",
      "package_id" => package_id,
      "accepted_claim_count" => accepted.length,
      "rejected_claim_count" => rejected.length,
      "partial_record_path" => record_path.relative_path_from(ROOT).to_s,
      "accepted_claims" => accepted,
      "rejected_claims" => rejected
    }
  )
end

def benchmark(argv)
  usage if argv.empty?
  corpus_path = Pathname.new(argv.shift).expand_path
  flags = parse_options(argv)
  corpus = read_json(corpus_path)
  stable_error("UNSUPPORTED_SCHEMA_VERSION", "Benchmark corpus schema_version must be 1.0.0.") unless corpus["schema_version"] == "1.0.0"
  cases = corpus.fetch("cases")
  stable_error("BENCHMARK_EMPTY", "Benchmark corpus must contain cases.") unless cases.is_a?(Array) && !cases.empty?

  total = cases.length
  unsupported_claims = cases.sum { |item| item.fetch("unsupported_claims", []).length }
  conflict_cases = cases.count { |item| !item.fetch("conflicts_disclosed", []).empty? }
  gap_cases = cases.count { |item| item.fetch("gap_created", false) }
  provenance_complete = cases.count { |item| item.fetch("provenance_complete", false) && !item.fetch("citations", []).empty? }
  grounded = cases.count { |item| item.fetch("unsupported_claims", []).empty? && item.fetch("provenance_complete", false) }

  report = {
    "schema_version" => "1.0.0",
    "benchmark_id" => corpus.fetch("benchmark_id"),
    "mutates_knowledge" => false,
    "case_count" => total,
    "metrics" => {
      "grounded_answer_rate" => (grounded.to_f / total).round(4),
      "unsupported_claim_rate" => (unsupported_claims.to_f / total).round(4),
      "conflict_disclosure_rate" => (conflict_cases.to_f / total).round(4),
      "gap_behavior_rate" => (gap_cases.to_f / total).round(4),
      "provenance_completeness_rate" => (provenance_complete.to_f / total).round(4)
    },
    "cases" => cases.map do |item|
      {
        "case_id" => item.fetch("case_id"),
        "query" => item.fetch("query"),
        "unsupported_claims" => item.fetch("unsupported_claims", []),
        "conflicts_disclosed" => item.fetch("conflicts_disclosed", []),
        "gap_created" => item.fetch("gap_created", false),
        "provenance_complete" => item.fetch("provenance_complete", false)
      }
    end
  }

  if flags["report"]
    report_path = Pathname.new(flags.fetch("report")).expand_path
    FileUtils.mkdir_p(report_path.dirname)
    report_path.write(JSON.pretty_generate(report) + "\n")
    report["report_path"] = report_path.to_s
  end

  puts JSON.pretty_generate(report)
end

command = ARGV.shift || usage
case command
when "partial-ingest"
  partial_ingest(ARGV)
when "benchmark"
  benchmark(ARGV)
else
  usage
end

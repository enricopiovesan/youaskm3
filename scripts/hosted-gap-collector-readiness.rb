#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path
DEFAULT_CONFIG = ROOT.join("app", "site", "author-instance.json")
DEFAULT_DOCS = [
  ROOT.join("docs", "hosted-gap-collector-deployment.md"),
  ROOT.join("docs", "hosted-gap-collector-architecture.md")
].freeze
REQUIRED_DISCLOSURE_FIELDS = %w[public_gap_data storage_location readable_by retention_expectation owner_deletion_export_path].freeze
LIMIT_FIELDS = %w[max_body_bytes rate_limit_max rate_limit_window_seconds].freeze
AUTOMATIC_CAPTURE_PATTERN = /\b(automatic|one-click|painless)\b.*\b(gap capture|gap submission|public gap)\b/i
HONEST_FALLBACK_PATTERN = /\b(fallback|manual|not configured|collector absent|without a collector)\b/i

def stable_error(code, message)
  warn "#{code}: #{message}"
  exit 1
end

def parse_flags(argv)
  flags = {
    "config" => DEFAULT_CONFIG.to_s,
    "docs" => DEFAULT_DOCS.map(&:to_s)
  }

  until argv.empty?
    key = argv.shift
    case key
    when "--config"
      flags["config"] = argv.shift || stable_error("INVALID_ARGUMENT", "Missing value for --config")
    when "--docs"
      flags["docs"] = (argv.shift || stable_error("INVALID_ARGUMENT", "Missing value for --docs")).split(",")
    else
      stable_error("INVALID_ARGUMENT", "Unknown flag: #{key}")
    end
  end

  flags
end

def load_json(path)
  JSON.parse(Pathname.new(path).read)
rescue Errno::ENOENT
  stable_error("HOSTED_GAP_READINESS_CONFIG_MISSING", "Config file not found: #{path}")
rescue JSON::ParserError => e
  stable_error("HOSTED_GAP_READINESS_CONFIG_INVALID", "Config JSON is invalid: #{e.message}")
end

def read_docs(paths)
  paths.map do |path|
    expanded = Pathname.new(path)
    stable_error("HOSTED_GAP_READINESS_DOCS_MISSING", "Readiness doc not found: #{path}") unless expanded.file?
    [path, expanded.read]
  end
end

def require_doc_sections!(docs)
  joined = docs.map(&:last).join("\n")
  [
    "Public Gap Data",
    "Storage And Access",
    "Retention",
    "Owner Deletion And Export",
    "Free-Tier And Cost Assumptions"
  ].each do |section|
    stable_error("HOSTED_GAP_DISCLOSURE_MISSING", "Hosted collector docs are missing #{section}.") unless joined.include?("## #{section}") || joined.include?("### #{section}")
  end
end

def collector_config(config)
  collector = config["hostedGapCollector"]
  stable_error("HOSTED_GAP_READINESS_CONFIG_INVALID", "hostedGapCollector must be an object when present.") if collector && !collector.is_a?(Hash)
  collector || {}
end

def enabled?(collector)
  collector["enabled"] == true
end

def positive_integer?(value)
  value.is_a?(Integer) && value.positive?
end

def validate_enabled_collector!(collector)
  stable_error("HOSTED_GAP_READINESS_CONFIG_INVALID", "Enabled collector requires endpoint.") unless collector["endpoint"].is_a?(String) && !collector["endpoint"].empty?

  disclosure = collector["privacyDisclosure"]
  missing_disclosure = REQUIRED_DISCLOSURE_FIELDS.reject { |field| disclosure.is_a?(Hash) && disclosure[field].is_a?(String) && !disclosure[field].empty? }
  stable_error("HOSTED_GAP_DISCLOSURE_MISSING", "Enabled collector is missing privacy disclosure fields: #{missing_disclosure.join(", ")}.") unless missing_disclosure.empty?

  abuse_control = collector["abuseControl"]
  stable_error("HOSTED_GAP_ABUSE_CONTROL_MISSING", "Enabled collector requires configured abuseControl.") unless abuse_control.is_a?(Hash)
  stable_error("HOSTED_GAP_ABUSE_CONTROL_MISSING", "Enabled collector requires challenge abuse control.") unless abuse_control["challenge"] == true
  stable_error("HOSTED_GAP_ABUSE_CONTROL_MISSING", "Enabled collector requires origin policy.") unless abuse_control["originPolicy"].is_a?(Array) && !abuse_control["originPolicy"].empty?

  missing_limits = LIMIT_FIELDS.reject { |field| positive_integer?(collector[field]) }
  stable_error("HOSTED_GAP_LIMIT_MISSING", "Enabled collector is missing conservative limit fields: #{missing_limits.join(", ")}.") unless missing_limits.empty?
end

def validate_fallback!(collector)
  fallback_issue = collector["fallbackIssueUrl"].is_a?(String) && !collector["fallbackIssueUrl"].empty?
  fallback_package = collector["fallbackPackageName"].is_a?(String) && !collector["fallbackPackageName"].empty?
  stable_error("HOSTED_GAP_FALLBACK_MISSING", "Fallback-only deployments require a manual issue URL or download package name.") unless fallback_issue || fallback_package
end

def validate_no_false_automatic_claims!(docs, collector)
  return if enabled?(collector)

  docs.each do |path, text|
    text.lines.each_with_index do |line, index|
      next unless line.match?(AUTOMATIC_CAPTURE_PATTERN)
      next if line.match?(HONEST_FALLBACK_PATTERN) || line.match?(/\b(no|not|without|must not|does not|cannot|absent)\b/i)
      stable_error("HOSTED_GAP_FALLBACK_CLAIM_INVALID", "#{path}:#{index + 1} claims automatic hosted gap capture while collector is disabled.")
    end
  end
end

flags = parse_flags(ARGV)
config = load_json(flags.fetch("config"))
collector = collector_config(config)
docs = read_docs(flags.fetch("docs"))

require_doc_sections!(docs)
if enabled?(collector)
  validate_enabled_collector!(collector)
else
  validate_fallback!(collector)
  validate_no_false_automatic_claims!(docs, collector)
end

puts JSON.pretty_generate({
  "status" => "ready",
  "collector_enabled" => enabled?(collector),
  "hosted_accounts_required" => false,
  "hosted_sync_required" => false,
  "hosted_teams_required" => false,
  "hosted_runtime_required" => false
})

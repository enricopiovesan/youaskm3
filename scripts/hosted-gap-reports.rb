#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "net/http"
require "pathname"
require "time"
require "uri"

ROOT = Pathname.new(__dir__).join("..").expand_path
DEFAULT_KNOWLEDGE_ROOT = ROOT.join("knowledge")
VALIDATION_VERSION = "hosted-gap-collector/0.1.0"
SCHEMA_VERSION = "public-gap-report/0.1.0"
REQUIRED_REPORT_KEYS = %w[report_id schema_version validation_version question missing_knowledge published_scope checked_evidence source_url submitted_at].freeze
LOCAL_REVIEW_ACTIONS = %w[reject archive].freeze

def stable_error(code, message)
  warn "#{code}: #{message}"
  exit 1
end

def usage
  stable_error(
    "INVALID_ARGUMENT",
    "Usage: ./scripts/m3.sh hosted-gaps {list|import|reject|archive} --collector-url URL|--collector-file PATH [--knowledge-root PATH] [--collector-token TOKEN] [--report-id ID] [--accept]"
  )
end

def parse_args(argv)
  command = argv.shift || usage
  flags = {
    "knowledge_root" => DEFAULT_KNOWLEDGE_ROOT.to_s,
    "collector_url" => ENV["M3_HOSTED_GAP_COLLECTOR_URL"],
    "collector_token" => ENV["M3_HOSTED_GAP_COLLECTOR_TOKEN"],
    "accept" => false
  }

  until argv.empty?
    key = argv.shift
    case key
    when "--knowledge-root", "--collector-url", "--collector-file", "--collector-token", "--report-id"
      flags[key.delete_prefix("--").tr("-", "_")] = argv.shift || stable_error("INVALID_ARGUMENT", "Missing value for #{key}")
    when "--accept"
      flags["accept"] = true
    else
      stable_error("INVALID_ARGUMENT", "Unknown flag: #{key}")
    end
  end

  [command, flags]
end

def slug(value)
  value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
end

def relative(path)
  Pathname.new(path).expand_path.relative_path_from(ROOT).to_s
rescue ArgumentError
  Pathname.new(path).expand_path.to_s
end

def load_json_file(path)
  JSON.parse(Pathname.new(path).read)
rescue Errno::ENOENT
  stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Collector export file not found: #{path}")
rescue JSON::ParserError => e
  stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Collector export JSON is invalid: #{e.message}")
end

def fetch_collector_json(flags)
  if flags["collector_file"]
    return load_json_file(flags.fetch("collector_file"))
  end

  collector_url = flags["collector_url"] || stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Missing --collector-url or --collector-file.")
  uri = URI(collector_url)
  request = Net::HTTP::Get.new(uri)
  request["accept"] = "application/json"
  request["authorization"] = "Bearer #{flags["collector_token"]}" if flags["collector_token"]

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
    http.request(request)
  end
  stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Collector returned HTTP #{response.code}.") unless response.is_a?(Net::HTTPSuccess)
  JSON.parse(response.body)
rescue URI::InvalidURIError, SocketError, SystemCallError, Timeout::Error, JSON::ParserError => e
  stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Hosted collector is unavailable or returned invalid JSON: #{e.message}")
end

def pending_reports(flags)
  data = fetch_collector_json(flags)
  reports = if data.is_a?(Array)
              data
            elsif data.is_a?(Hash) && data["reports"].is_a?(Array)
              data.fetch("reports")
            else
              stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Collector response must be an array or { reports: [...] }.")
            end

  reports.map { |report| normalize_report(report) }.select { |report| report.fetch("status", "pending") == "pending" }
end

def normalize_report(raw)
  stable_error("HOSTED_GAP_REPORT_INVALID", "Hosted report must be an object.") unless raw.is_a?(Hash)
  nested = raw["report"].is_a?(Hash) ? raw.fetch("report") : raw
  report = {
    "report_id" => raw["report_id"] || raw["reportId"],
    "collector_id" => raw["collector_id"] || raw["collectorId"],
    "status" => raw["status"] || "pending",
    "schema_version" => nested["schema_version"],
    "validation_version" => nested["validation_version"],
    "question" => nested["question"],
    "missing_knowledge" => nested["missing_knowledge"],
    "published_scope" => nested["published_scope"],
    "checked_evidence" => nested["checked_evidence"],
    "source_url" => nested["source_url"],
    "submitted_at" => nested["submitted_at"],
    "reporter_context" => nested["reporter_context"],
    "received_at" => raw["received_at"] || raw["receivedAt"]
  }

  validate_report!(report)
  report
end

def validate_report!(report)
  missing = REQUIRED_REPORT_KEYS.reject { |key| valid_required_value?(report[key]) }
  stable_error("HOSTED_GAP_REPORT_INVALID", "Hosted report is missing #{missing.join(", ")}.") unless missing.empty?
  stable_error("HOSTED_GAP_REPORT_INVALID", "Unsupported schema_version: #{report["schema_version"]}.") unless report["schema_version"] == SCHEMA_VERSION
  stable_error("HOSTED_GAP_REPORT_INVALID", "Unsupported validation_version: #{report["validation_version"]}.") unless report["validation_version"] == VALIDATION_VERSION
  stable_error("HOSTED_GAP_REPORT_INVALID", "checked_evidence must be an array of strings.") unless report["checked_evidence"].is_a?(Array) && report["checked_evidence"].all? { |item| item.is_a?(String) && !item.empty? }
  stable_error("HOSTED_GAP_REPORT_INVALID", "source_url must be http(s).") unless report["source_url"].match?(/\Ahttps?:\/\//)
  Time.iso8601(report["submitted_at"])
rescue ArgumentError
  stable_error("HOSTED_GAP_REPORT_INVALID", "submitted_at must be an ISO-8601 timestamp.")
end

def valid_required_value?(value)
  if value.is_a?(String)
    !value.empty?
  elsif value.is_a?(Array)
    !value.empty?
  else
    !value.nil?
  end
end

def front_matter(markdown)
  lines = markdown.lines
  return {} unless lines.first&.strip == "---"

  closing = lines[1..].find_index { |line| line.strip == "---" }
  return {} if closing.nil?

  lines[1, closing].each_with_object({}) do |line, data|
    next if line.strip.empty?
    key, value = line.split(":", 2)
    next if value.nil?
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

def write_record(path, front, body)
  FileUtils.mkdir_p(path.dirname)
  rendered = front.map do |key, value|
    line_value = value.is_a?(Array) ? "[#{value.join(", ")}]" : (value.nil? ? "null" : value)
    "#{key}: #{line_value}"
  end.join("\n")
  path.write("---\n#{rendered}\n---\n\n#{body}\n")
end

def validate_knowledge_root!(knowledge_root)
  return FileUtils.mkdir_p(knowledge_root) if knowledge_root == DEFAULT_KNOWLEDGE_ROOT

  marker = knowledge_root.join(".youaskm3-knowledge-root.json")
  stable_error("EXTERNAL_KNOWLEDGE_ROOT_UNINITIALIZED", "External knowledge roots must be initialized before writes: #{knowledge_root}") unless marker.file?
end

def sync_preflight!(knowledge_root)
  return unless knowledge_root == DEFAULT_KNOWLEDGE_ROOT

  system("ruby", ROOT.join("scripts", "sync-preflight.rb").to_s, "--knowledge-root", knowledge_root.to_s, out: File::NULL) ||
    stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Sync preflight failed before hosted gap import.")
end

def imported_report_ids(knowledge_root)
  Dir.glob(knowledge_root.join("gaps", "{open,resolved}", "*.md")).each_with_object({}) do |path, ids|
    data = front_matter(File.read(path))
    ids[data["hosted_report_id"]] = path if data["hosted_report_id"]
  end
end

def local_review_state_path(knowledge_root)
  knowledge_root.join(".youaskm3-hosted-gap-reports", "review-state.json")
end

def local_review_state(knowledge_root)
  path = local_review_state_path(knowledge_root)
  return {} unless path.file?

  JSON.parse(path.read)
rescue JSON::ParserError
  stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Local hosted gap review state is invalid: #{path}")
end

def write_local_review_state(knowledge_root, state)
  path = local_review_state_path(knowledge_root)
  FileUtils.mkdir_p(path.dirname)
  path.write(JSON.pretty_generate(state) + "\n")
end

def filtered_reports(flags, knowledge_root)
  ignored = local_review_state(knowledge_root)
  pending_reports(flags).reject { |report| ignored.key?(report.fetch("report_id")) }
end

def list_reports(flags)
  knowledge_root = Pathname.new(flags.fetch("knowledge_root")).expand_path
  reports = filtered_reports(flags, knowledge_root).map do |report|
    {
      "report_id" => report.fetch("report_id"),
      "status" => report.fetch("status"),
      "question" => report.fetch("question"),
      "missing_knowledge" => report.fetch("missing_knowledge"),
      "source_url" => report.fetch("source_url"),
      "published_scope" => report.fetch("published_scope"),
      "checked_evidence" => report.fetch("checked_evidence"),
      "submitted_at" => report.fetch("submitted_at"),
      "validation_version" => report.fetch("validation_version")
    }
  end
  puts JSON.pretty_generate(reports)
end

def select_report!(flags, knowledge_root)
  report_id = flags["report_id"] || stable_error("INVALID_ARGUMENT", "Missing --report-id.")
  report = filtered_reports(flags, knowledge_root).find { |candidate| candidate.fetch("report_id") == report_id }
  stable_error("HOSTED_GAP_REPORT_INVALID", "Pending hosted report not found: #{report_id}") unless report
  report
end

def import_report(flags)
  stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Hosted gap import requires explicit --accept.") unless flags["accept"]

  knowledge_root = Pathname.new(flags.fetch("knowledge_root")).expand_path
  validate_knowledge_root!(knowledge_root)
  sync_preflight!(knowledge_root)
  report = select_report!(flags, knowledge_root)

  existing = imported_report_ids(knowledge_root)[report.fetch("report_id")]
  stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Hosted report already imported at #{existing}.") if existing

  now = Time.now.utc.iso8601
  gap_id = "gap-hosted-#{slug(report.fetch("report_id"))[0, 48].gsub(/-\z/, "")}"
  path = knowledge_root.join("gaps", "open", "#{gap_id}.md")
  front = {
    "kind" => "knowledge_gap",
    "gap_id" => gap_id,
    "status" => "open",
    "persona_id" => "default",
    "source_question" => report.fetch("question"),
    "confidence_reason" => "Hosted public gap report #{report.fetch("report_id")}: #{report.fetch("missing_knowledge")}",
    "trace_id" => "hosted-gap-#{slug(report.fetch("report_id"))}",
    "deterministic_complexity" => "reasoning_heavy",
    "agent_complexity" => nil,
    "final_complexity" => "reasoning_heavy",
    "allowed_resolution_path" => "decision_log_package",
    "linked_package_id" => nil,
    "relevant_graph_nodes" => [],
    "hosted_report_id" => report.fetch("report_id"),
    "hosted_collector_id" => report["collector_id"],
    "hosted_source_url" => report.fetch("source_url"),
    "hosted_published_scope" => report.fetch("published_scope"),
    "hosted_reporter_context" => report["reporter_context"],
    "hosted_submitted_at" => report.fetch("submitted_at"),
    "hosted_schema_version" => report.fetch("schema_version"),
    "hosted_validation_version" => report.fetch("validation_version"),
    "created_at" => now,
    "updated_at" => now
  }

  body = <<~MARKDOWN
    ## Clarification Need

    #{report.fetch("missing_knowledge")}

    ## Hosted Report Provenance

    | Field | Value |
    |---|---|
    | Hosted report id | #{report.fetch("report_id")} |
    | Collector source | #{report["collector_id"] || "unknown"} |
    | Source URL | #{report.fetch("source_url")} |
    | Published scope | #{report.fetch("published_scope")} |
    | Submitted at | #{report.fetch("submitted_at")} |
    | Schema version | #{report.fetch("schema_version")} |
    | Validation version | #{report.fetch("validation_version")} |
    | Reporter context | #{report["reporter_context"] || "none"} |

    ## Checked Evidence

    #{report.fetch("checked_evidence").map { |item| "- #{item}" }.join("\n")}
  MARKDOWN

  write_record(path, front, body)
  validate_imported_gap!(path)
  puts JSON.pretty_generate({ "status" => "imported", "report_id" => report.fetch("report_id"), "gap_id" => gap_id, "path" => relative(path) })
end

def validate_imported_gap!(path)
  data = front_matter(path.read)
  required = %w[kind gap_id status persona_id source_question confidence_reason trace_id deterministic_complexity final_complexity allowed_resolution_path created_at updated_at hosted_report_id hosted_source_url hosted_published_scope hosted_schema_version hosted_validation_version]
  missing = required.reject { |key| data.key?(key) && !data[key].to_s.empty? }
  stable_error("HOSTED_GAP_OWNER_IMPORT_FAILED", "Imported gap is missing #{missing.join(", ")}.") unless missing.empty?
end

def record_local_review_action(flags, action)
  knowledge_root = Pathname.new(flags.fetch("knowledge_root")).expand_path
  validate_knowledge_root!(knowledge_root)
  report = select_report!(flags, knowledge_root)
  state = local_review_state(knowledge_root)
  state[report.fetch("report_id")] = {
    "status" => action,
    "recorded_at" => Time.now.utc.iso8601,
    "source_url" => report.fetch("source_url"),
    "published_scope" => report.fetch("published_scope")
  }
  write_local_review_state(knowledge_root, state)
  puts JSON.pretty_generate({ "status" => action, "report_id" => report.fetch("report_id"), "review_state_path" => relative(local_review_state_path(knowledge_root)) })
end

command, flags = parse_args(ARGV)

case command
when "list"
  list_reports(flags)
when "import"
  import_report(flags)
when *LOCAL_REVIEW_ACTIONS
  record_local_review_action(flags, command)
else
  usage
end

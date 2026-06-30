#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "net/http"
require "pathname"
require "securerandom"
require "uri"
require "webrick"

ROOT = Pathname.new(__dir__).join("..").expand_path

OPERATIONS = {
  "answer" => {
    "capability_id" => "knowledge.query.answer",
    "workflow_id" => "youaskm3.knowledge.query-answer",
    "contract_path" => "contracts/capabilities/knowledge.query.answer.json"
  },
  "gaps.list" => {
    "capability_id" => "knowledge.gaps.list",
    "workflow_id" => "youaskm3.knowledge.gaps-list",
    "contract_path" => "contracts/capabilities/knowledge.gaps.list.json"
  },
  "gaps.resolve_fact" => {
    "capability_id" => "knowledge.gaps.resolve_fact",
    "workflow_id" => "youaskm3.knowledge.gaps-resolve-fact",
    "contract_path" => "contracts/capabilities/knowledge.gaps.resolve_fact.json"
  }
}.freeze

ROUTES = {
  ["POST", "/api/answer"] => ["http", "answer"],
  ["GET", "/api/gaps"] => ["http", "gaps.list"],
  ["POST", "/api/gaps/resolve-fact"] => ["http", "gaps.resolve_fact"],
  ["POST", "/mcp/tools/knowledge.query.answer"] => ["mcp", "answer"],
  ["POST", "/mcp/tools/knowledge.gaps.list"] => ["mcp", "gaps.list"],
  ["POST", "/mcp/tools/knowledge.gaps.resolve_fact"] => ["mcp", "gaps.resolve_fact"]
}.freeze

def usage
  abort "Usage: ruby scripts/m3-local-runtime.rb [--port PORT] [--traverse-endpoint URL] [--workspace-id ID] [--routes-json] [--simulate METHOD PATH --body JSON]"
end

def parse_args(argv)
  config = {
    "port" => "8787",
    "traverse_endpoint" => ENV["TRAVERSE_ENDPOINT"].to_s,
    "workspace_id" => ENV.fetch("TRAVERSE_WORKSPACE_ID", "local-default"),
    "config_path" => ENV.fetch("M3_PROJECT_CONFIG", ROOT.join(".youaskm3", "config.json").to_s),
    "explicit_traverse_endpoint" => ENV.key?("TRAVERSE_ENDPOINT"),
    "routes_json" => false,
    "simulate" => nil,
    "body" => "{}"
  }

  until argv.empty?
    flag = argv.shift
    case flag
    when "--port"
      config["port"] = argv.shift || usage
    when "--traverse-endpoint"
      config["traverse_endpoint"] = argv.shift || usage
      config["explicit_traverse_endpoint"] = true
    when "--workspace-id"
      config["workspace_id"] = argv.shift || usage
    when "--config"
      config["config_path"] = argv.shift || usage
    when "--routes-json"
      config["routes_json"] = true
    when "--simulate"
      method = argv.shift || usage
      path = argv.shift || usage
      config["simulate"] = [method, path]
    when "--body"
      config["body"] = argv.shift || usage
    when "--help", "-h"
      usage
    else
      usage
    end
  end

  abort "m3 local runtime expects a numeric port." unless config.fetch("port").match?(/\A\d+\z/)
  apply_project_config(config)
  config
end

def apply_project_config(config)
  path = Pathname.new(config.fetch("config_path"))
  return unless path.file?

  project_config = JSON.parse(path.read)
  if !config.fetch("explicit_traverse_endpoint") && config.fetch("traverse_endpoint").empty?
    config["traverse_endpoint"] = project_config.dig("traverse", "endpoint").to_s
  end
  config["knowledge_root"] ||= project_config["knowledge_root"]
rescue JSON::ParserError => error
  abort "PROJECT_CONFIG_INVALID: #{path} is not valid JSON: #{error.message}"
end

def read_json_request(request)
  return {} if request.body.to_s.strip.empty?

  JSON.parse(request.body)
rescue JSON::ParserError => error
  raise WEBrick::HTTPStatus::BadRequest, "Invalid JSON request body: #{error.message}"
end

def parse_json_body(body)
  return {} if body.to_s.strip.empty?

  JSON.parse(body)
end

def build_traverse_request(surface, operation, input, workspace_id)
  operation_contract = OPERATIONS.fetch(operation)
  request_id = input["request_id"] || "youaskm3-local-#{operation.tr(".", "-")}-#{SecureRandom.hex(6)}"

  {
    "kind" => "runtime_request",
    "schema_version" => "1.0.0",
    "request_id" => request_id,
    "workspace_id" => workspace_id,
    "surface" => surface,
    "intent" => operation_contract,
    "input" => input.reject { |key, _| key == "request_id" },
    "lookup" => {
      "scope" => "prefer_private",
      "allow_ambiguity" => false
    },
    "context" => {
      "requested_target" => surface == "mcp" ? "mcp" : "local",
      "caller" => surface == "mcp" ? "youaskm3-mcp" : "youaskm3-http-json"
    },
    "governing_spec" => "openspec/specs/local-runtime-sync/spec.md"
  }
end

def missing_traverse_response(surface, operation, request)
  operation_contract = OPERATIONS.fetch(operation)

  {
    "status" => "blocked",
    "code" => "MISSING_TRAVERSE_RUNTIME",
    "message" => "Set TRAVERSE_ENDPOINT or pass --traverse-endpoint to proxy #{operation} through Traverse.",
    "recoverable" => true,
    "trace_id" => "local-runtime:#{request.fetch("request_id")}",
    "surface" => surface,
    "operation" => operation,
    "capability_id" => operation_contract.fetch("capability_id"),
    "workflow_id" => operation_contract.fetch("workflow_id"),
    "contract_path" => operation_contract.fetch("contract_path"),
    "traverse_request" => request,
    "provenance" => {
      "runtime" => "traverse",
      "business_logic" => "wasm",
      "endpoint_configured" => false
    }
  }
end

def proxy_to_traverse(endpoint, workspace_id, request)
  uri = URI.join(endpoint.end_with?("/") ? endpoint : "#{endpoint}/", "v1/workspaces/#{workspace_id}/execute")
  response = Net::HTTP.post(uri, JSON.generate(request), "Content-Type" => "application/json", "Accept" => "application/json")
  [response.code.to_i, JSON.parse(response.body)]
rescue JSON::ParserError
  [502, { "code" => "TRAVERSE_RESPONSE_INVALID", "message" => "Traverse returned non-JSON response.", "recoverable" => true }]
rescue StandardError => error
  [503, { "code" => "TRAVERSE_UNAVAILABLE", "message" => error.message, "recoverable" => true }]
end

def write_json(response, status, payload)
  response.status = status
  response["Content-Type"] = "application/json"
  response.body = JSON.pretty_generate(payload) + "\n"
end

def routes_payload(config)
  {
    "status" => "ready",
    "runtime" => "youaskm3-local-runtime",
    "knowledge_root" => config["knowledge_root"],
    "routes" => ROUTES.map { |(method, path), (surface, operation)| { "method" => method, "path" => path, "surface" => surface, "operation" => operation } }
  }
end

def handle_runtime_request(method, path, input, config)
  route = ROUTES[[method, path]]
  return [404, { "code" => "ROUTE_NOT_FOUND", "message" => "No local runtime route for #{method} #{path}." }] unless route

  surface, operation = route
  traverse_request = build_traverse_request(surface, operation, input, config.fetch("workspace_id"))
  if config.fetch("traverse_endpoint").empty?
    [503, missing_traverse_response(surface, operation, traverse_request)]
  else
    proxy_to_traverse(config.fetch("traverse_endpoint"), config.fetch("workspace_id"), traverse_request)
  end
end

config = parse_args(ARGV)

if config.fetch("routes_json")
  puts JSON.pretty_generate(routes_payload(config).merge("traverse_endpoint_configured" => !config.fetch("traverse_endpoint").empty?))
  exit 0
end

if config.fetch("simulate")
  begin
    method, path = config.fetch("simulate")
    input = method == "GET" ? {} : parse_json_body(config.fetch("body"))
    status, payload = handle_runtime_request(method, path, input, config)
    puts JSON.pretty_generate(payload.merge("_http_status" => status))
    exit(status < 500 ? 0 : 1)
  rescue JSON::ParserError => error
    puts JSON.pretty_generate({ "code" => "INVALID_JSON", "message" => error.message, "_http_status" => 400 })
    exit 1
  end
end

server = WEBrick::HTTPServer.new(
  BindAddress: "127.0.0.1",
  Port: config.fetch("port").to_i,
  AccessLog: [],
  Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN)
)

server.mount_proc "/health" do |_request, response|
  write_json(response, 200, routes_payload(config).merge("traverse_endpoint_configured" => !config.fetch("traverse_endpoint").empty?))
end

ROUTES.each do |(method, path), (surface, operation)|
  server.mount_proc path do |request, response|
    unless request.request_method == method
      write_json(response, 405, { "code" => "METHOD_NOT_ALLOWED", "message" => "#{path} expects #{method}." })
      next
    end

    input = method == "GET" ? {} : read_json_request(request)
    status, payload = handle_runtime_request(method, path, input, config)
    write_json(response, status, payload)
  rescue WEBrick::HTTPStatus::BadRequest => error
    write_json(response, 400, { "code" => "INVALID_JSON", "message" => error.message })
  end
end

trap("INT") { server.shutdown }
trap("TERM") { server.shutdown }

puts "youaskm3 local runtime listening on http://127.0.0.1:#{config.fetch("port")}/"
server.start

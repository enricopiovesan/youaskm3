#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

ruby - "$@" <<'RUBY'
require "json"
require "open3"
require "pathname"
require "set"

ROOT = Pathname.new(Dir.pwd)
APP_MANIFEST = ROOT.join("traverse/youaskm3-app/manifest.json")
ZERO_DIGEST = "sha256:#{"0" * 64}"
MIN_TRAVERSE_TAG = ENV.fetch("MIN_TRAVERSE_TAG", "v0.5.0")

options = {
  json: false,
  validate_only: false,
  allow_skeleton: false,
  traverse_repo: ENV["TRAVERSE_REPO"] || ENV["TRAVERSE_CHECKOUT"],
  workspace_id: ENV["TRAVERSE_WORKSPACE_ID"]
}

until ARGV.empty?
  arg = ARGV.shift
  case arg
  when "--json"
    options[:json] = true
  when "--validate-only"
    options[:validate_only] = true
  when "--allow-skeleton"
    options[:allow_skeleton] = true
  when "--traverse-repo"
    options[:traverse_repo] = ARGV.shift
    abort "--traverse-repo requires a path" if options[:traverse_repo].nil? || options[:traverse_repo].empty?
  when "--workspace"
    options[:workspace_id] = ARGV.shift
    abort "--workspace requires a workspace id" if options[:workspace_id].nil? || options[:workspace_id].empty?
  when "--help", "-h"
    puts <<~HELP
      Usage: bash scripts/register-traverse-app.sh [--json] [--validate-only] [--allow-skeleton] [--traverse-repo PATH] [--workspace ID]

      Validates and registers the checked-in youaskm3 Traverse application manifest.

      --validate-only   Validate local manifest/component/workflow shape without requiring Traverse.
      --allow-skeleton  Treat missing WASM binaries as an expected MVP skeleton state.
      --traverse-repo   Local Traverse checkout. Defaults to TRAVERSE_REPO, TRAVERSE_CHECKOUT, or ../Traverse.
      --workspace       Workspace id for Traverse CLI registration. Defaults to TRAVERSE_WORKSPACE_ID or manifest workspace_defaults.workspace_id.
      --json            Emit machine-readable evidence.
    HELP
    exit 0
  else
    abort "Unknown argument: #{arg}"
  end
end

def read_json(path, errors, code)
  JSON.parse(path.read)
rescue Errno::ENOENT
  errors << { "code" => code, "message" => "Missing file: #{relative(path)}" }
  nil
rescue JSON::ParserError => error
  errors << { "code" => "INVALID_APPLICATION_BUNDLE", "message" => "Invalid JSON in #{relative(path)}: #{error.message}" }
  nil
end

def relative(path)
  Pathname.new(path).relative_path_from(ROOT).to_s
rescue ArgumentError
  path.to_s
end

def git(repo, *args)
  output = IO.popen(["git", "-C", repo.to_s, *args], err: [:child, :out], &:read)
  [$?.exitstatus, output.strip]
end

def run_traverse_cli(repo, *args)
  command = ["cargo", "run", "-p", "traverse-cli", "--", *args]
  stdout, stderr, status = Open3.capture3(*command, chdir: repo.to_s)
  parsed = JSON.parse(stdout)
  {
    "command" => ["traverse-cli", *args],
    "exit_status" => status.exitstatus,
    "stdout" => parsed,
    "stderr_excerpt" => stderr.lines.last(12).join.strip
  }
rescue Errno::ENOENT
  {
    "command" => ["traverse-cli", *args],
    "exit_status" => 127,
    "stdout" => nil,
    "stderr_excerpt" => "missing required command: cargo"
  }
rescue JSON::ParserError
  {
    "command" => ["traverse-cli", *args],
    "exit_status" => status && status.exitstatus,
    "stdout" => nil,
    "stderr_excerpt" => [stderr, stdout].join("\n").lines.last(20).join.strip
  }
end

def default_traverse_repo
  sibling = ROOT.join("../Traverse").cleanpath
  sibling.directory? ? sibling.to_s : nil
end

def finish(payload, options, exit_code)
  if options[:json]
    puts JSON.pretty_generate(payload)
  else
    puts "youaskm3 Traverse app registration: #{payload.fetch("status")}"
    puts "code: #{payload.fetch("code")}"
    puts "app: #{payload.dig("app", "app_id")} #{payload.dig("app", "version")}"
    puts "components: #{payload.dig("app", "component_count")}"
    puts "workflows: #{payload.dig("app", "workflow_count")}"
    payload.fetch("errors", []).each { |error| warn "#{error.fetch("code")}: #{error.fetch("message")}" }
  end
  exit exit_code
end

errors = []
warnings = []
app = read_json(APP_MANIFEST, errors, "INVALID_APPLICATION_BUNDLE")

component_count = 0
workflow_count = 0
model_dependency_count = 0
missing_wasm = []
zero_digest_components = []
capabilities = []
workflows = []

if app
  unless app["minimum_traverse_version"] == MIN_TRAVERSE_TAG
    errors << {
      "code" => "UNSUPPORTED_TRAVERSE_VERSION",
      "message" => "Application manifest requires #{app["minimum_traverse_version"].inspect}; expected #{MIN_TRAVERSE_TAG}."
    }
  end

  components = app["components"]
  if !components.is_a?(Array) || components.empty?
    errors << { "code" => "INVALID_APPLICATION_BUNDLE", "message" => "Application manifest must include components." }
  else
    component_count = components.length
    seen_components = Set.new

    components.each do |entry|
      component_id = entry["component_id"]
      unless component_id && seen_components.add?(component_id)
        errors << { "code" => "INVALID_APPLICATION_BUNDLE", "message" => "Duplicate or missing component_id in app manifest." }
      end

      manifest_path = ROOT.join("traverse/youaskm3-app", entry.fetch("manifest_path", "")).cleanpath
      component = read_json(manifest_path, errors, "INVALID_APPLICATION_BUNDLE")
      next unless component

      required = %w[
        component_id version capability_id capability_version contract_path
        wasm_binary_path wasm_digest implementation_status runtime_constraints permitted_targets
      ]
      missing_fields = required.reject { |field| component.key?(field) }
      unless missing_fields.empty?
        errors << {
          "code" => "INVALID_APPLICATION_BUNDLE",
          "message" => "#{relative(manifest_path)} missing fields: #{missing_fields.join(", ")}"
        }
        next
      end

      capabilities << component.fetch("capability_id")
      if component.fetch("component_id") != component_id
        errors << {
          "code" => "INVALID_APPLICATION_BUNDLE",
          "message" => "#{relative(manifest_path)} component_id does not match app manifest."
        }
      end

      contract_path = manifest_path.dirname.join(component.fetch("contract_path")).cleanpath
      contract = read_json(contract_path, errors, "INVALID_APPLICATION_BUNDLE")
      if contract && contract["id"] != component["capability_id"]
        errors << {
          "code" => "INVALID_APPLICATION_BUNDLE",
          "message" => "#{relative(contract_path)} id does not match #{relative(manifest_path)}."
        }
      end

      wasm_path = manifest_path.dirname.join(component.fetch("wasm_binary_path")).cleanpath
      missing_wasm << relative(wasm_path) unless wasm_path.file?
      zero_digest_components << component_id if component.fetch("wasm_digest") == ZERO_DIGEST || entry["digest"] == ZERO_DIGEST
    end
  end

  workflow_entries = app["workflows"]
  if !workflow_entries.is_a?(Array) || workflow_entries.empty?
    errors << { "code" => "INVALID_APPLICATION_BUNDLE", "message" => "Application manifest must include workflows." }
  else
    workflow_count = workflow_entries.length
    workflow_entries.each do |entry|
      workflow_path = ROOT.join("traverse/youaskm3-app", entry.fetch("path", "")).cleanpath
      workflow = read_json(workflow_path, errors, "INVALID_APPLICATION_BUNDLE")
      next unless workflow

      workflows << workflow.fetch("id", entry["workflow_id"])
      if workflow["id"] != entry["workflow_id"]
        errors << {
          "code" => "INVALID_APPLICATION_BUNDLE",
          "message" => "#{relative(workflow_path)} id does not match app manifest."
        }
      end
    end
  end

  model_dependencies = app["model_dependencies"]
  model_dependency_count = model_dependencies.is_a?(Array) ? model_dependencies.length : 0
  unless model_dependencies.is_a?(Array) && model_dependencies.any? { |dep| dep.fetch("required_capabilities", []).include?("text_generation") }
    errors << {
      "code" => "MISSING_MODEL_DEPENDENCY",
      "message" => "Application manifest must declare a Traverse-resolved text_generation model dependency."
    }
  end
end

payload = {
  "status" => "pending",
  "code" => "PENDING",
  "app" => {
    "manifest_path" => relative(APP_MANIFEST),
    "app_id" => app && app["app_id"],
    "version" => app && app["version"],
    "minimum_traverse_version" => app && app["minimum_traverse_version"],
    "integration_status" => app && app["integration_status"],
    "component_count" => component_count,
    "workflow_count" => workflow_count,
    "model_dependency_count" => model_dependency_count,
    "capabilities" => capabilities.sort,
    "workflows" => workflows.sort
  },
  "evidence" => {
    "checked_manifest" => true,
    "missing_wasm_count" => missing_wasm.length,
    "zero_digest_component_count" => zero_digest_components.length,
    "missing_wasm_paths" => missing_wasm,
    "zero_digest_components" => zero_digest_components
  },
  "traverse" => {},
  "cli" => {},
  "registration" => {},
  "warnings" => warnings,
  "errors" => errors
}

if errors.any?
  payload["status"] = "failed"
  payload["code"] = errors.first.fetch("code")
  finish(payload, options, 1)
end

if missing_wasm.any? && !options[:allow_skeleton]
  payload["status"] = "failed"
  payload["code"] = "MISSING_WASM_ARTIFACT"
  payload["errors"] << {
    "code" => "MISSING_WASM_ARTIFACT",
    "message" => "Real registration requires WASM binaries for every component. Use --allow-skeleton only for pending MVP skeleton evidence."
  }
  finish(payload, options, 4)
end

if options[:validate_only]
  payload["status"] = missing_wasm.any? ? "validated_skeleton" : "validated"
  payload["code"] = missing_wasm.any? ? "SKELETON_PENDING_WASM_COMPONENTS" : "VALIDATED"
  finish(payload, options, 0)
end

traverse_repo = options[:traverse_repo] || default_traverse_repo
unless traverse_repo && git(traverse_repo, "rev-parse", "--is-inside-work-tree").first.zero?
  payload["status"] = "failed"
  payload["code"] = "MISSING_TRAVERSE_CHECKOUT"
  payload["errors"] << {
    "code" => "MISSING_TRAVERSE_CHECKOUT",
    "message" => "Set TRAVERSE_REPO to a local Traverse checkout at #{MIN_TRAVERSE_TAG} or newer."
  }
  finish(payload, options, 2)
end

traverse_repo = Pathname.new(traverse_repo).realpath
payload["traverse"]["repo"] = traverse_repo.to_s

tag_status, = git(traverse_repo, "rev-parse", "--verify", "--quiet", "#{MIN_TRAVERSE_TAG}^{commit}")
unless tag_status.zero?
  payload["status"] = "failed"
  payload["code"] = "UNSUPPORTED_TRAVERSE_VERSION"
  payload["errors"] << {
    "code" => "UNSUPPORTED_TRAVERSE_VERSION",
    "message" => "Traverse checkout is missing required tag #{MIN_TRAVERSE_TAG}."
  }
  finish(payload, options, 3)
end

ancestor_status, = git(traverse_repo, "merge-base", "--is-ancestor", MIN_TRAVERSE_TAG, "HEAD")
unless ancestor_status.zero?
  _, commit = git(traverse_repo, "rev-parse", "--short", "HEAD")
  payload["traverse"]["commit"] = commit
  payload["status"] = "failed"
  payload["code"] = "UNSUPPORTED_TRAVERSE_VERSION"
  payload["errors"] << {
    "code" => "UNSUPPORTED_TRAVERSE_VERSION",
    "message" => "Traverse checkout #{commit} is older than #{MIN_TRAVERSE_TAG}."
  }
  finish(payload, options, 3)
end

_, commit = git(traverse_repo, "rev-parse", "--short", "HEAD")
_, tag = git(traverse_repo, "describe", "--tags", "--abbrev=12", "--always")
payload["traverse"]["commit"] = commit
payload["traverse"]["tag"] = tag

if missing_wasm.any? && options[:allow_skeleton]
  payload["status"] = "skipped_skeleton_pending_wasm"
  payload["code"] = "SKELETON_PENDING_WASM_COMPONENTS"
  payload["warnings"] << {
    "code" => "SKELETON_PENDING_WASM_COMPONENTS",
    "message" => "Traverse registration was not attempted because component WASM binaries are still placeholders."
  }
  finish(payload, options, 0)
end

validate = run_traverse_cli(
  traverse_repo,
  "app", "validate",
  "--manifest", APP_MANIFEST.realpath.to_s,
  "--json"
)
payload["cli"]["validate"] = validate

if validate.fetch("exit_status") != 0 || validate["stdout"].nil? || validate.dig("stdout", "status") != "validated"
  payload["status"] = "failed"
  payload["code"] = validate["exit_status"] == 127 ? "MISSING_TRAVERSE_CLI" : "TRAVERSE_CLI_VALIDATION_FAILED"
  payload["errors"] << {
    "code" => payload["code"],
    "message" => "Traverse CLI app validation failed.",
    "details" => validate["stdout"] || validate["stderr_excerpt"]
  }
  finish(payload, options, 5)
end

workspace_id = options[:workspace_id] || app.dig("workspace_defaults", "workspace_id")
if workspace_id.nil? || workspace_id.empty?
  payload["status"] = "failed"
  payload["code"] = "MISSING_WORKSPACE_ID"
  payload["errors"] << {
    "code" => "MISSING_WORKSPACE_ID",
    "message" => "Provide --workspace, TRAVERSE_WORKSPACE_ID, or workspace_defaults.workspace_id in the app manifest."
  }
  finish(payload, options, 5)
end

register = run_traverse_cli(
  traverse_repo,
  "app", "register",
  "--manifest", APP_MANIFEST.realpath.to_s,
  "--workspace", workspace_id,
  "--json"
)
payload["cli"]["register"] = register

if register.fetch("exit_status") != 0 || register["stdout"].nil?
  payload["status"] = "failed"
  payload["code"] = register["exit_status"] == 127 ? "MISSING_TRAVERSE_CLI" : "TRAVERSE_CLI_REGISTRATION_FAILED"
  payload["errors"] << {
    "code" => payload["code"],
    "message" => "Traverse CLI app registration failed.",
    "details" => register["stdout"] || register["stderr_excerpt"]
  }
  finish(payload, options, 5)
end

registration_status = register.dig("stdout", "status")
unless %w[registered already_registered].include?(registration_status)
  payload["status"] = "failed"
  payload["code"] = "TRAVERSE_CLI_REGISTRATION_FAILED"
  payload["errors"] << {
    "code" => "TRAVERSE_CLI_REGISTRATION_FAILED",
    "message" => "Traverse CLI app registration returned #{registration_status.inspect}.",
    "details" => register["stdout"]
  }
  finish(payload, options, 5)
end

payload["status"] = registration_status
payload["code"] = registration_status == "already_registered" ? "ALREADY_REGISTERED" : "REGISTERED"
payload["registration"] = {
  "workspace_id" => register.dig("stdout", "workspace_id"),
  "app_id" => register.dig("stdout", "app_id"),
  "app_version" => register.dig("stdout", "app_version"),
  "state_scope" => register.dig("stdout", "state_scope"),
  "state_path" => register.dig("stdout", "state_path"),
  "component_ids" => register.dig("stdout", "component_ids"),
  "workflow_ids" => register.dig("stdout", "workflow_ids"),
  "digest_verification" => register.dig("stdout", "digest_verification"),
  "model_readiness" => register.dig("stdout", "model_readiness"),
  "links" => register.dig("stdout", "links")
}
finish(payload, options, 0)
RUBY

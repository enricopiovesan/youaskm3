#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "pathname"
require "set"

ROOT = Pathname.new(__dir__).join("..").realpath
APP_MANIFEST_PATH = ROOT.join("traverse/youaskm3-app/manifest.json")
TRAVERSE_CONTRACTS_DIR = ROOT.join("traverse/youaskm3-app/contracts")
ZERO_DIGEST = "sha256:#{"0" * 64}"
REQUIRED_COMPONENT_FIELDS = %w[
  component_id
  version
  schema_version
  capability_id
  capability_version
  contract_path
  wasm_binary_path
  wasm_digest
  implementation_status
  runtime_constraints
  permitted_targets
].to_set

options = {
  check: false,
  skeleton: false
}

ARGV.each do |arg|
  case arg
  when "--check"
    options[:check] = true
  when "--skeleton"
    options[:skeleton] = true
  when "--help", "-h"
    puts "Usage: ruby scripts/traverse-component-manifests.rb [--check] [--skeleton]"
    puts
    puts "--check     Verify checked-in manifests are current without writing files."
    puts "--skeleton  Allow missing WASM binaries and keep zero digests for pending components."
    exit 0
  else
    abort "Unknown argument: #{arg}"
  end
end

def read_json(path)
  JSON.parse(path.read)
rescue JSON::ParserError => error
  abort "Invalid JSON in #{path.relative_path_from(ROOT)}: #{error.message}"
end

def pretty_json(data)
  JSON.pretty_generate(data)
      .gsub(/: \[\n\s*\]/, ": []")
      .gsub(/: \{\n\s*\}/, ": {}")
      .concat("\n")
end

def relative(path)
  path.relative_path_from(ROOT).to_s
end

def checked_write(path, data, check:)
  next_content = pretty_json(data)
  current_content = path.file? ? path.read : nil

  if check
    abort "#{relative(path)} is not current; run bash scripts/traverse-component-manifests.sh --skeleton" unless current_content == next_content
  else
    path.write(next_content)
  end
end

def traverse_component_targets(contract_targets)
  contract_targets.map do |target|
    case target
    when "server"
      "cloud"
    when "mcp"
      nil
    else
      target
    end
  end.compact.uniq
end

def traverse_contract_for(contract)
  capability_id = contract.fetch("id")
  namespace, name = capability_id.rpartition(".").values_at(0, 2)
  {
    "kind" => "capability_contract",
    "schema_version" => "1.0.0",
    "id" => capability_id,
    "namespace" => namespace,
    "name" => name,
    "version" => contract.fetch("version"),
    "lifecycle" => "active",
    "owner" => {
      "team" => "youaskm3",
      "contact" => "maintainers@youaskm3.com"
    },
    "summary" => contract.fetch("summary"),
    "description" => contract.fetch("description"),
    "inputs" => contract.fetch("inputs"),
    "outputs" => contract.fetch("outputs"),
    "preconditions" => [],
    "postconditions" => [],
    "side_effects" => [
      {
        "kind" => "none",
        "description" => "Pure governed WASM capability execution."
      }
    ],
    "emits" => [],
    "consumes" => [],
    "permissions" => [],
    "execution" => {
      "binary_format" => "wasm",
      "entrypoint" => {
        "kind" => "wasi-command",
        "command" => "run"
      },
      "preferred_targets" => ["local"],
      "constraints" => {
        "host_api_access" => "none",
        "network_access" => "forbidden",
        "filesystem_access" => "none"
      }
    },
    "policies" => [],
    "dependencies" => [],
    "provenance" => {
      "source" => "greenfield",
      "author" => "youaskm3",
      "created_at" => "2026-06-26T00:00:00Z",
      "spec_ref" => "openspec/specs/traverse-integration/spec.md",
      "adr_refs" => [],
      "exception_refs" => []
    },
    "evidence" => [],
    "service_type" => "stateless",
    "permitted_targets" => traverse_component_targets(contract.fetch("execution").fetch("permitted_targets")),
    "artifact_type" => "native"
  }
end

app_manifest = read_json(APP_MANIFEST_PATH)
components = app_manifest.fetch("components")
component_digest_by_id = components.to_h { |component| [component.fetch("component_id"), component.fetch("digest")] }
seen_component_ids = Set.new
missing_binaries = []
TRAVERSE_CONTRACTS_DIR.mkpath

components.each do |app_component|
  manifest_path = ROOT.join("traverse/youaskm3-app", app_component.fetch("manifest_path")).cleanpath
  abort "Missing component manifest: #{relative(manifest_path)}" unless manifest_path.file?

  component = read_json(manifest_path)
  missing_fields = REQUIRED_COMPONENT_FIELDS - component.keys.to_set
  abort "#{relative(manifest_path)} missing fields: #{missing_fields.to_a.sort.join(", ")}" unless missing_fields.empty?

  component_id = app_component.fetch("component_id")
  abort "Duplicate component_id in app manifest: #{component_id}" unless seen_component_ids.add?(component_id)
  abort "#{relative(manifest_path)} component_id does not match app manifest" unless component.fetch("component_id") == component_id

  contract_path = ROOT.join("contracts/capabilities/#{component.fetch("capability_id")}.json").cleanpath
  abort "Missing capability contract: #{relative(contract_path)}" unless contract_path.file?

  contract = read_json(contract_path)
  capability_id = contract.fetch("id")
  capability_version = contract.fetch("version")
  abort "#{relative(manifest_path)} capability_id does not match #{relative(contract_path)}" unless component.fetch("capability_id") == capability_id
  traverse_contract_path = TRAVERSE_CONTRACTS_DIR.join("#{capability_id}.contract.json")
  checked_write(traverse_contract_path, traverse_contract_for(contract), check: options[:check])

  wasm_binary_path = manifest_path.dirname.join(component.fetch("wasm_binary_path")).cleanpath
  if wasm_binary_path.file?
    digest = "sha256:#{Digest::SHA256.file(wasm_binary_path).hexdigest}"
    implementation_status = "wasm_binary_ready"
    validation_evidence = [
      {
        "evidence_type" => "wasm_binary_digest",
        "status" => "verified",
        "path" => component.fetch("wasm_binary_path"),
        "digest" => digest
      }
    ]
  elsif options[:skeleton]
    digest = ZERO_DIGEST
    implementation_status = component.fetch("implementation_status")
    validation_evidence = component.fetch("validation_evidence", [])
    missing_binaries << relative(wasm_binary_path)
  else
    abort "Missing WASM binary for #{capability_id}: #{relative(wasm_binary_path)}. Re-run with --skeleton only for pending components."
  end

  component["version"] = app_component.fetch("version")
  component["capability_version"] = capability_version
  component["contract_path"] = traverse_contract_path.relative_path_from(manifest_path.dirname).to_s
  component["wasm_digest"] = digest
  component["implementation_status"] = implementation_status
  component["permitted_targets"] = traverse_component_targets(contract.fetch("execution").fetch("permitted_targets"))
  component.fetch("dependencies", []).each do |dependency|
    dependency["digest"] = component_digest_by_id.fetch(dependency.fetch("component_id"))
  end
  component["validation_evidence"] = validation_evidence

  app_component["digest"] = digest
  app_component["implementation_status"] = implementation_status

  checked_write(manifest_path, component, check: options[:check])
end

if missing_binaries.empty?
  app_manifest["integration_status"] = "wasm_components_ready"
elsif options[:skeleton]
  app_manifest["integration_status"] = "skeleton_pending_wasm_components"
end

checked_write(APP_MANIFEST_PATH, app_manifest, check: options[:check])

mode = options[:check] ? "checked" : "updated"
puts "Traverse component manifests #{mode}."
puts "Components: #{components.length}"
puts "Missing WASM binaries allowed by skeleton mode: #{missing_binaries.length}"

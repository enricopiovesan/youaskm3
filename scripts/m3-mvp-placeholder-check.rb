#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "English"
require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path
APP_ROOT = ROOT.join("traverse", "youaskm3-app")
ZERO_DIGEST = "sha256:#{"0" * 64}"

def read_json(path)
  JSON.parse(path.read)
rescue Errno::ENOENT
  abort "MVP placeholder check failed: missing file #{path}"
rescue JSON::ParserError => error
  abort "MVP placeholder check failed: invalid JSON in #{path}: #{error.message}"
end

def relative(path)
  Pathname.new(path).relative_path_from(ROOT).to_s
end

def reject_zero_digest(path, value)
  return unless value == ZERO_DIGEST

  abort "MVP placeholder check failed: #{relative(path)} contains all-zero digest evidence."
end

app = read_json(APP_ROOT.join("manifest.json"))
unless app.fetch("integration_status") == "wasm_components_ready"
  abort "MVP placeholder check failed: app integration_status must be wasm_components_ready."
end

app.fetch("components").each do |entry|
  manifest_path = APP_ROOT.join(entry.fetch("manifest_path")).cleanpath
  manifest = read_json(manifest_path)

  reject_zero_digest(manifest_path, manifest["wasm_digest"])
  manifest.fetch("artifacts", []).each do |artifact|
    reject_zero_digest(manifest_path, artifact["digest"])
  end

  if manifest.fetch("implementation", "").match?(/placeholder|skeleton|fake/i)
    abort "MVP placeholder check failed: #{relative(manifest_path)} has placeholder implementation marker."
  end
end

app.fetch("workflows").each do |entry|
  workflow_path = APP_ROOT.join(entry.fetch("path")).cleanpath
  workflow = read_json(workflow_path)
  workflow_text = JSON.generate(workflow)
  if workflow_text.match?(/browser-demo|temporary harness|fake workflow|placeholder digest|skeleton manifest/i)
    abort "MVP placeholder check failed: #{relative(workflow_path)} contains non-acceptance workflow markers."
  end
end

registration = IO.popen(
  ["bash", "scripts/register-traverse-app.sh", "--validate-only", "--json"],
  chdir: ROOT.to_s,
  err: [:child, :out],
  &:read
)
unless $CHILD_STATUS.success?
  abort "MVP placeholder check failed: Traverse app validation failed.\n#{registration}"
end

payload = JSON.parse(registration)
evidence = payload.fetch("evidence")
unless evidence.fetch("missing_wasm_count").zero? && evidence.fetch("zero_digest_component_count").zero?
  abort "MVP placeholder check failed: Traverse app validation reported missing WASM or zero digest evidence."
end

puts "MVP placeholder check passed."

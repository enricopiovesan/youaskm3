#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

cargo build --locked --workspace --target wasm32-wasip1 --release
bash scripts/traverse-component-manifests.sh --check

ruby <<'RUBY'
require "json"

zero_digest = "sha256:#{"0" * 64}"
app_manifest = JSON.parse(File.read("traverse/youaskm3-app/manifest.json"))
components = app_manifest.fetch("components")
abort "Expected 7 Traverse components, found #{components.length}" unless components.length == 7
abort "app manifest must mark real WASM components ready" unless app_manifest.fetch("integration_status") == "wasm_components_ready"

components.each do |component|
  manifest_path = File.join("traverse/youaskm3-app", component.fetch("manifest_path"))
  manifest = JSON.parse(File.read(manifest_path))

  %w[
    component_id
    version
    capability_id
    capability_version
    contract_path
    wasm_binary_path
    wasm_digest
    runtime_constraints
    permitted_targets
  ].each do |field|
    abort "#{manifest_path} missing #{field}" unless manifest.key?(field)
  end

  abort "#{manifest_path} digest mismatch with app manifest" unless manifest.fetch("wasm_digest") == component.fetch("digest")
  abort "#{manifest_path} must not keep a zero digest" if manifest.fetch("wasm_digest") == zero_digest
  abort "#{manifest_path} must be wasm_binary_ready" unless manifest.fetch("implementation_status") == "wasm_binary_ready"
  abort "#{manifest_path} must reference a WASM binary" unless manifest.fetch("wasm_binary_path").end_with?(".wasm")
  abort "#{manifest_path} must include permitted targets" if manifest.fetch("permitted_targets").empty?
end
RUBY

echo "Traverse component manifest smoke passed."

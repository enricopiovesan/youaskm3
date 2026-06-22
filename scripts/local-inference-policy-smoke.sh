#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

require_pattern() {
  local pattern="$1"
  local path="$2"
  local message="$3"

  if ! grep -Eq "$pattern" "$path"; then
    echo "Local inference policy smoke failed: $message" >&2
    exit 1
  fi
}

POLICY_DOC="docs/mvp-local-inference-policy.md"
INFER_CONTRACT="contracts/capabilities/knowledge.infer.json"
APP_MANIFEST="traverse/youaskm3-app/manifest.json"
READINESS_SCRIPT="scripts/traverse-readiness.sh"

require_pattern "Default CI and .*scripts/smoke\\.sh.*MUST NOT require a live local LLM" "$POLICY_DOC" "policy must keep default smoke independent of a live local LLM."
require_pattern "TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1 bash scripts/traverse-readiness\\.sh" "$POLICY_DOC" "policy must document the opt-in local model conformance command."
require_pattern "MISSING_MODEL_DEPENDENCY" "$POLICY_DOC" "policy must define the missing model dependency failure category."
require_pattern "WASM-native" "$POLICY_DOC" "policy must keep the WASM-native model caveat visible."
require_pattern "selected candidate id|rejected candidate ids|placement target" "$POLICY_DOC" "policy must describe trace evidence for inference resolution."
require_pattern "knowledge\\.infer" "$INFER_CONTRACT" "knowledge.infer contract must exist."
require_pattern "model_dependencies" "$APP_MANIFEST" "app manifest must declare model dependencies."
require_pattern "live local model conformance" "$READINESS_SCRIPT" "readiness script must report local model status separately."

echo "Local inference policy smoke passed."

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-}"
KNOWLEDGE_ROOT=""
WORKSPACE_DIR=""

usage() {
  cat >&2 <<'EOF'
Usage: ./scripts/m3.sh mvp-check --knowledge-root PATH [--traverse-repo PATH]

Runs the expanded first-MVP acceptance gate without Browser demo, skeleton, or
placeholder acceptance evidence.

Required:
  --knowledge-root PATH   Knowledge root used for first-run setup validation.

Optional:
  --traverse-repo PATH    Local Traverse checkout for live readiness validation.
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "m3 mvp-check failed: missing required command: $1" >&2
    exit 1
  fi
}

run_gate() {
  local label="$1"
  shift

  echo "==> ${label}"
  "$@"
  echo "ok: ${label}"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --knowledge-root)
      KNOWLEDGE_ROOT="${2:-}"
      [[ -n "$KNOWLEDGE_ROOT" ]] || { usage; exit 1; }
      shift 2
      ;;
    --traverse-repo)
      TRAVERSE_REPO="${2:-}"
      [[ -n "$TRAVERSE_REPO" ]] || { usage; exit 1; }
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown mvp-check argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$KNOWLEDGE_ROOT" ]]; then
  usage
  exit 1
fi

require_cmd bash
require_cmd ruby
require_cmd node
require_cmd npm
require_cmd cargo

mkdir -p "$KNOWLEDGE_ROOT"
WORKSPACE_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORKSPACE_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"

echo "m3 expanded first-MVP acceptance gate"
echo "knowledge_root: $KNOWLEDGE_ROOT"
if [[ -n "$TRAVERSE_REPO" ]]; then
  echo "traverse_repo: $TRAVERSE_REPO"
else
  echo "traverse_repo: not supplied; live Traverse readiness will be recorded as a caveat"
fi

init_args=(
  "$WORKSPACE_DIR"
  --name "youaskm3 Expanded MVP Check"
  --shell-url "https://example.com/youaskm3-mvp-check/"
  --instance-id "youaskm3-mvp-check"
  --knowledge-root "$KNOWLEDGE_ROOT"
  --yes
)
if [[ -n "$TRAVERSE_REPO" ]]; then
  init_args+=(--traverse-repo "$TRAVERSE_REPO")
else
  init_args+=(--offline)
fi

run_gate "first-run setup with external knowledge root" \
  bash ./scripts/m3-init.sh "${init_args[@]}"

run_gate "real Traverse app bundle validation without skeleton mode" \
  bash ./scripts/register-traverse-app.sh --validate-only --json

run_gate "no placeholder runtime acceptance evidence" \
  ruby ./scripts/m3-mvp-placeholder-check.rb

run_gate "reasoning assistant skill adapter drift" \
  bash ./scripts/reasoning-skill-adapters-smoke.sh

run_gate "decision-log package contract" \
  bash ./scripts/decision-log-package-smoke.sh

run_gate "decision-log package ingestion" \
  bash ./scripts/m3-decision-log-ingest-smoke.sh

run_gate "reasoning graph extraction" \
  bash ./scripts/reasoning-graph-extraction-smoke.sh

run_gate "knowledge gaps and conflicts lifecycle" \
  bash ./scripts/knowledge-gap-lifecycle-smoke.sh

run_gate "sync preflight and conflict checks" \
  bash ./scripts/sync-preflight-smoke.sh

run_gate "local runtime serve orchestration" \
  bash ./scripts/m3-serve-runtime-smoke.sh

run_gate "PWA shell and chat rendering contract" \
  npm test -- app/components/index.test.ts app/components/browser-runtime.test.ts

run_gate "HTTP JSON and MCP parity surfaces" \
  bash ./scripts/local-runtime-mcp-parity-smoke.sh

run_gate "Traverse MCP workflow contract parity" \
  bash ./scripts/traverse-mcp-answer-workflow-smoke.sh

run_gate "direct fact resolution through package pipeline" \
  bash ./scripts/direct-fact-resolution-smoke.sh

if [[ -n "$TRAVERSE_REPO" ]]; then
  run_gate "live Traverse readiness" \
    env TRAVERSE_REPO="$TRAVERSE_REPO" bash ./scripts/traverse-readiness.sh
fi

cat <<'EOF'
Remaining caveats:
- semantic validation availability: deterministic validation and contracts pass; live model semantics depend on the configured Traverse/provider environment.
- WASM-native model engine: model dependency routing is Traverse-governed; native model execution remains a Traverse/provider capability.

m3 expanded first-MVP acceptance gate passed.
EOF

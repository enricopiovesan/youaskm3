#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIN_TRAVERSE_TAG="${MIN_TRAVERSE_TAG:-v0.5.0}"
TRAVERSE_REPO="${TRAVERSE_REPO:-${TRAVERSE_CHECKOUT:-}}"

if [[ -z "$TRAVERSE_REPO" ]]; then
  if [[ -d "$ROOT_DIR/../Traverse/.git" ]]; then
    TRAVERSE_REPO="$ROOT_DIR/../Traverse"
  else
    echo "Traverse readiness failed: set TRAVERSE_REPO to a local Traverse checkout." >&2
    echo "Expected default sibling checkout at: $ROOT_DIR/../Traverse" >&2
    exit 1
  fi
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Traverse readiness failed: missing required command: $1" >&2
    exit 1
  fi
}

require_file() {
  local path="$1"

  if [[ ! -f "$path" ]]; then
    echo "Traverse readiness failed: missing required Traverse file: $path" >&2
    exit 1
  fi
}

print_area_summary() {
  local log_file="$1"
  local status="$2"
  local live_model_status

  if grep -q "Skipping local Ollama conformance" "$log_file"; then
    live_model_status="optional skipped"
  elif [[ "${TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE:-0}" == "1" ]]; then
    live_model_status="required by TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1"
  else
    live_model_status="not required"
  fi

  echo "Traverse readiness ${status}."
  echo "Capability areas:"
  summarize_area "$log_file" "application bundle registration" "downstream app bundle registration smoke passed."
  summarize_area "$log_file" "WASM workflow execution" "downstream WASM workflow smoke passed."
  summarize_area "$log_file" "model dependency resolution" "downstream model dependency smoke passed."
  summarize_area "$log_file" "HTTP/JSON app path" "downstream HTTP/JSON smoke passed."
  summarize_area "$log_file" "MCP parity path" "downstream MCP smoke passed."
  echo "- live local model conformance: ${live_model_status}"
}

summarize_area() {
  local log_file="$1"
  local label="$2"
  local success_line="$3"

  if grep -qF "$success_line" "$log_file"; then
    echo "- ${label}: passed"
  else
    echo "- ${label}: not confirmed"
  fi
}

require_cmd bash
require_cmd git
require_cmd cargo

if ! git -C "$TRAVERSE_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Traverse readiness failed: TRAVERSE_REPO is not a git checkout: $TRAVERSE_REPO" >&2
  exit 1
fi

TRAVERSE_REPO="$(cd "$TRAVERSE_REPO" && pwd)"
CONFORMANCE_SCRIPT="$TRAVERSE_REPO/scripts/ci/downstream_app_mvp_conformance.sh"
require_file "$CONFORMANCE_SCRIPT"

if ! git -C "$TRAVERSE_REPO" rev-parse --verify --quiet "$MIN_TRAVERSE_TAG^{commit}" >/dev/null; then
  echo "Traverse readiness failed: Traverse checkout is missing required tag $MIN_TRAVERSE_TAG." >&2
  echo "Fetch tags in the Traverse checkout, then retry." >&2
  exit 1
fi

if ! git -C "$TRAVERSE_REPO" merge-base --is-ancestor "$MIN_TRAVERSE_TAG" HEAD; then
  traverse_commit="$(git -C "$TRAVERSE_REPO" rev-parse --short HEAD)"
  echo "Traverse readiness failed: Traverse checkout $traverse_commit is older than $MIN_TRAVERSE_TAG." >&2
  exit 1
fi

traverse_commit="$(git -C "$TRAVERSE_REPO" rev-parse --short HEAD)"
traverse_tag="$(git -C "$TRAVERSE_REPO" describe --tags --exact-match 2>/dev/null || true)"
if [[ -z "$traverse_tag" ]]; then
  traverse_tag="$(git -C "$TRAVERSE_REPO" describe --tags --abbrev=12 --always)"
fi

log_file="$(mktemp "${TMPDIR:-/tmp}/youaskm3-traverse-readiness.XXXXXX")"
trap 'rm -f "$log_file"' EXIT

echo "Checking Traverse readiness..."
echo "Traverse repo: $TRAVERSE_REPO"
echo "Traverse commit: $traverse_commit"
echo "Traverse tag: $traverse_tag"
echo "Minimum baseline: $MIN_TRAVERSE_TAG"
echo "Conformance: scripts/ci/downstream_app_mvp_conformance.sh"

set +e
(
  cd "$TRAVERSE_REPO"
  TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE="${TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE:-0}" \
    bash scripts/ci/downstream_app_mvp_conformance.sh
) >"$log_file" 2>&1
conformance_status=$?
set -e

if [[ "$conformance_status" -eq 0 ]]; then
  print_area_summary "$log_file" "passed"
  exit 0
fi

print_area_summary "$log_file" "failed"
echo "Actionable failure excerpt:"
tail -n 60 "$log_file"
exit "$conformance_status"

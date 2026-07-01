#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/.youaskm3" "$TEMP_DIR/scripts" "$TEMP_DIR/app/site" "$TEMP_DIR/traverse"

cp "$ROOT_DIR/scripts/m3.sh" "$TEMP_DIR/scripts/m3.sh"
cp "$ROOT_DIR/scripts/m3-serve.sh" "$TEMP_DIR/scripts/m3-serve.sh"
cp "$ROOT_DIR/scripts/m3-local-runtime.rb" "$TEMP_DIR/scripts/m3-local-runtime.rb"
cp "$ROOT_DIR/scripts/register-traverse-app.sh" "$TEMP_DIR/scripts/register-traverse-app.sh"
cp -R "$ROOT_DIR/traverse/youaskm3-app" "$TEMP_DIR/traverse/youaskm3-app"
cp -R "$ROOT_DIR/contracts" "$TEMP_DIR/contracts"

cat >"$TEMP_DIR/.youaskm3/config.json" <<'JSON'
{
  "schema_version": "1.0.0",
  "knowledge_root": "/tmp/youaskm3-runtime-smoke-knowledge",
  "traverse": {
    "endpoint": "test://ready"
  }
}
JSON

ready_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh serve --runtime 48746 --check-only
)"

grep -q 'youaskm3 runtime ready' <<<"$ready_output"
grep -q 'runtime_url: http://127.0.0.1:48746/' <<<"$ready_output"
grep -q 'mcp_endpoint: http://127.0.0.1:48746/mcp' <<<"$ready_output"
grep -q 'workspace_id: local-default' <<<"$ready_output"
grep -q 'trace_evidence_mode: public' <<<"$ready_output"

override_output="$(
  cd "$TEMP_DIR"
  TRAVERSE_ENDPOINT= bash ./scripts/m3.sh serve --runtime 48747 --config "$TEMP_DIR/.youaskm3/config.json" --traverse-endpoint test://ready --workspace-id smoke-workspace --check-only
)"

grep -q 'workspace_id: smoke-workspace' <<<"$override_output"

if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh serve --runtime --config "$TEMP_DIR/missing-config.json" --check-only >/tmp/m3-serve-missing-runtime.out 2>/tmp/m3-serve-missing-runtime.err
); then
  echo "Expected missing Traverse runtime config to fail." >&2
  exit 1
fi
grep -q 'MISSING_TRAVERSE_RUNTIME' /tmp/m3-serve-missing-runtime.err

if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh serve --runtime --config "$TEMP_DIR/.youaskm3/config.json" --traverse-endpoint http://127.0.0.1:9 --check-only >/tmp/m3-serve-unavailable.out 2>/tmp/m3-serve-unavailable.err
); then
  echo "Expected unreachable Traverse runtime to fail." >&2
  exit 1
fi
grep -q 'TRAVERSE_RUNTIME_UNAVAILABLE' /tmp/m3-serve-unavailable.err

echo "m3 serve runtime smoke passed."

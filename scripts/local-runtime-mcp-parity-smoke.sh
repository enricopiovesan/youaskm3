#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR=""
trap 'rm -f /tmp/m3-runtime-*.json; if [[ -n "$CONFIG_DIR" ]]; then rm -rf "$CONFIG_DIR"; fi' EXIT

cd "$ROOT_DIR"

CONFIG_DIR="$(mktemp -d)"
cat >"$CONFIG_DIR/config.json" <<'JSON'
{
  "schema_version": "1.0.0",
  "knowledge_root": "/tmp/youaskm3-configured-knowledge",
  "traverse": {
    "endpoint": "http://127.0.0.1:8787"
  }
}
JSON

ruby ./scripts/m3-local-runtime.rb --routes-json >/tmp/m3-runtime-health.json
ruby -rjson -e 'data=JSON.parse(File.read(ARGV[0])); abort "runtime not ready" unless data.fetch("status") == "ready"; routes=data.fetch("routes").map { |route| [route.fetch("method"), route.fetch("path")] }; [%w[POST /api/answer], %w[GET /api/gaps], %w[POST /api/gaps/resolve-fact], %w[POST /mcp/tools/knowledge.query.answer], %w[POST /mcp/tools/knowledge.gaps.list], %w[POST /mcp/tools/knowledge.gaps.resolve_fact]].each { |route| abort "missing route #{route.inspect}" unless routes.include?(route) }' /tmp/m3-runtime-health.json

ruby ./scripts/m3-local-runtime.rb --config "$CONFIG_DIR/config.json" --routes-json >/tmp/m3-runtime-configured-health.json
ruby -rjson -e 'data=JSON.parse(File.read(ARGV[0])); abort "config endpoint not loaded" unless data.fetch("traverse_endpoint_configured") == true; abort "config knowledge root not loaded" unless data.fetch("knowledge_root") == "/tmp/youaskm3-configured-knowledge"' /tmp/m3-runtime-configured-health.json

ruby ./scripts/m3-local-runtime.rb --simulate POST /api/answer --body '{"query":"What is portable knowledge?","request_id":"parity-answer"}' >/tmp/m3-runtime-http-answer.json || true
ruby ./scripts/m3-local-runtime.rb --simulate POST /mcp/tools/knowledge.query.answer --body '{"query":"What is portable knowledge?","request_id":"parity-answer"}' >/tmp/m3-runtime-mcp-answer.json || true

ruby -rjson -e 'http=JSON.parse(File.read(ARGV[0])); mcp=JSON.parse(File.read(ARGV[1])); abort "expected missing runtime" unless http.fetch("code") == "MISSING_TRAVERSE_RUNTIME" && mcp.fetch("code") == "MISSING_TRAVERSE_RUNTIME"; abort "answer capability mismatch" unless http.fetch("capability_id") == mcp.fetch("capability_id") && http.fetch("workflow_id") == mcp.fetch("workflow_id"); abort "answer input mismatch" unless http.fetch("traverse_request").fetch("input") == mcp.fetch("traverse_request").fetch("input"); abort "expected surface split" unless http.fetch("surface") == "http" && mcp.fetch("surface") == "mcp"' /tmp/m3-runtime-http-answer.json /tmp/m3-runtime-mcp-answer.json

ruby ./scripts/m3-local-runtime.rb --simulate GET /api/gaps >/tmp/m3-runtime-http-gaps.json || true
ruby ./scripts/m3-local-runtime.rb --simulate POST /mcp/tools/knowledge.gaps.list --body '{}' >/tmp/m3-runtime-mcp-gaps.json || true

ruby -rjson -e 'http=JSON.parse(File.read(ARGV[0])); mcp=JSON.parse(File.read(ARGV[1])); abort "gaps capability mismatch" unless http.fetch("capability_id") == "knowledge.gaps.list" && http.fetch("capability_id") == mcp.fetch("capability_id"); abort "gaps workflow mismatch" unless http.fetch("workflow_id") == mcp.fetch("workflow_id")' /tmp/m3-runtime-http-gaps.json /tmp/m3-runtime-mcp-gaps.json

ruby ./scripts/m3-local-runtime.rb --simulate POST /api/gaps/resolve-fact --body '{"gap_id":"gap-author-name","answer":"The author is Enrico Piovesan.","request_id":"parity-resolve"}' >/tmp/m3-runtime-http-resolve.json || true
ruby ./scripts/m3-local-runtime.rb --simulate POST /mcp/tools/knowledge.gaps.resolve_fact --body '{"gap_id":"gap-author-name","answer":"The author is Enrico Piovesan.","request_id":"parity-resolve"}' >/tmp/m3-runtime-mcp-resolve.json || true

ruby -rjson -e 'http=JSON.parse(File.read(ARGV[0])); mcp=JSON.parse(File.read(ARGV[1])); abort "resolve capability mismatch" unless http.fetch("capability_id") == "knowledge.gaps.resolve_fact" && http.fetch("capability_id") == mcp.fetch("capability_id"); abort "resolve input mismatch" unless http.fetch("traverse_request").fetch("input") == mcp.fetch("traverse_request").fetch("input")' /tmp/m3-runtime-http-resolve.json /tmp/m3-runtime-mcp-resolve.json

if ruby ./scripts/m3-local-runtime.rb --simulate POST /api/answer --body '{invalid json' >/tmp/m3-runtime-invalid.json; then
  echo "Expected invalid JSON request to fail." >&2
  exit 1
fi

echo "Local runtime MCP parity smoke passed."

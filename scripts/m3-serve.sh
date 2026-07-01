#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-4173}"
SITE_DIR="$ROOT_DIR/app/site"

runtime_usage() {
  cat >&2 <<'EOF'
Usage: ./scripts/m3.sh serve --runtime [port] [--config PATH] [--traverse-endpoint URL] [--workspace-id ID] [--check-only]
EOF
}

resolve_config_value() {
  ruby -rjson -e '
path, explicit_endpoint, workspace_id = ARGV
config = File.file?(path) ? JSON.parse(File.read(path)) : {}
endpoint = explicit_endpoint.empty? ? config.dig("traverse", "endpoint").to_s : explicit_endpoint
workspace = workspace_id.empty? ? "local-default" : workspace_id
puts JSON.generate({ "endpoint" => endpoint, "workspace_id" => workspace })
' "$1" "$2" "$3"
}

validate_runtime_ready() {
  local endpoint="$1"
  if [[ -z "$endpoint" ]]; then
    echo "MISSING_TRAVERSE_RUNTIME: Set TRAVERSE_ENDPOINT, pass --traverse-endpoint, or run m3 init --traverse-repo <path>." >&2
    exit 1
  fi

  bash "$ROOT_DIR/scripts/register-traverse-app.sh" --validate-only --allow-skeleton --json >/dev/null

  if [[ "$endpoint" == "test://ready" ]]; then
    return
  fi

  ruby -rnet/http -ruri -e '
endpoint = ARGV.fetch(0)
uri = URI.join(endpoint.end_with?("/") ? endpoint : "#{endpoint}/", "health")
response = Net::HTTP.get_response(uri)
exit(response.is_a?(Net::HTTPSuccess) ? 0 : 1)
' "$endpoint" >/dev/null 2>&1 || {
    echo "TRAVERSE_RUNTIME_UNAVAILABLE: Traverse runtime is not reachable at ${endpoint}." >&2
    exit 1
  }
}

if [[ "$PORT" == "--help" || "$PORT" == "-h" ]]; then
  echo "Usage: ./scripts/m3.sh serve [port]"
  echo "       ./scripts/m3.sh serve --runtime [port] [--config PATH] [--traverse-endpoint URL] [--workspace-id ID] [--check-only]"
  exit 0
fi

if [[ "$PORT" == "--runtime" ]]; then
  shift
  runtime_port="${1:-8787}"
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    shift
  fi

  config_path="$ROOT_DIR/.youaskm3/config.json"
  traverse_endpoint="${TRAVERSE_ENDPOINT:-}"
  workspace_id="${TRAVERSE_WORKSPACE_ID:-}"
  check_only=false
  passthrough=()

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --config)
        config_path="${2:-}"
        [[ -n "$config_path" ]] || runtime_usage
        passthrough+=("--config" "$config_path")
        shift 2
        ;;
      --traverse-endpoint)
        traverse_endpoint="${2:-}"
        [[ -n "$traverse_endpoint" ]] || runtime_usage
        passthrough+=("--traverse-endpoint" "$traverse_endpoint")
        shift 2
        ;;
      --workspace-id)
        workspace_id="${2:-}"
        [[ -n "$workspace_id" ]] || runtime_usage
        passthrough+=("--workspace-id" "$workspace_id")
        shift 2
        ;;
      --check-only)
        check_only=true
        shift
        ;;
      --help|-h)
        runtime_usage
        exit 0
        ;;
      *)
        runtime_usage
        exit 1
        ;;
    esac
  done

  resolved="$(resolve_config_value "$config_path" "$traverse_endpoint" "$workspace_id")"
  effective_endpoint="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("endpoint")' <<<"$resolved")"
  effective_workspace="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("workspace_id")' <<<"$resolved")"
  validate_runtime_ready "$effective_endpoint"

  echo "youaskm3 runtime ready."
  echo "- runtime_url: http://127.0.0.1:${runtime_port}/"
  echo "- mcp_endpoint: http://127.0.0.1:${runtime_port}/mcp"
  echo "- workspace_id: ${effective_workspace}"
  echo "- trace_evidence_mode: public"

  if [[ "$check_only" == true ]]; then
    exit 0
  fi

  exec ruby "$ROOT_DIR/scripts/m3-local-runtime.rb" --port "$runtime_port" "${passthrough[@]}"
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
  echo "m3 serve expects a numeric port." >&2
  exit 1
fi

if [[ ! -f "$SITE_DIR/index.html" ]]; then
  echo "PWA site assets are missing. Run ./scripts/m3.sh build first." >&2
  exit 1
fi

echo "Serving youaskm3 from http://127.0.0.1:${PORT}/"
cd "$SITE_DIR"
exec ruby -run -e httpd . -p "$PORT" -b 127.0.0.1

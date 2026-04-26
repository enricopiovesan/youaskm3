#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: ./scripts/m3-init.sh [target-dir] [--name NAME] [--shell-url URL] [--instance-id ID] [--active-provider PROFILE] [--yes]

Bootstraps the minimum local instance metadata and directory layout needed for M4.
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's#[^a-z0-9]+#-#g; s#^-+##; s#-+$##'
}

ensure_trailing_slash() {
  case "$1" in
    */) printf '%s' "$1" ;;
    *) printf '%s/\n' "$1" ;;
  esac
}

validate_shell_url() {
  case "$1" in
    http://*|https://*) ;;
    *)
      echo "Invalid shell URL: use an http:// or https:// URL." >&2
      exit 1
      ;;
  esac
}

validate_active_provider() {
  case "$1" in
    browser-demo|claude-api|openai-api) ;;
    *)
      echo "Invalid active provider: choose browser-demo, claude-api, or openai-api." >&2
      exit 1
      ;;
  esac
}

prompt_if_missing() {
  local label="$1"
  local current_value="$2"
  if [[ -n "$current_value" ]]; then
    printf '%s' "$current_value"
    return
  fi

  if [[ ! -t 0 ]]; then
    echo "Missing required value for ${label}. Re-run with flags or use an interactive terminal." >&2
    exit 1
  fi

  local response
  printf '%s: ' "$label" >&2
  IFS= read -r response
  if [[ -z "$response" ]]; then
    echo "A value is required for ${label}." >&2
    exit 1
  fi

  printf '%s' "$response"
}

TARGET_DIR="."
INSTANCE_NAME=""
SHELL_URL=""
INSTANCE_ID=""
ACTIVE_PROVIDER="browser-demo"
ASSUME_YES=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --name)
      INSTANCE_NAME="${2:-}"
      shift 2
      ;;
    --shell-url)
      SHELL_URL="${2:-}"
      shift 2
      ;;
    --instance-id)
      INSTANCE_ID="${2:-}"
      shift 2
      ;;
    --active-provider)
      ACTIVE_PROVIDER="${2:-}"
      shift 2
      ;;
    --yes)
      ASSUME_YES=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      echo "Unknown flag: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ "$TARGET_DIR" != "." ]]; then
        echo "Only one target directory may be provided." >&2
        usage
        exit 1
      fi
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

require_cmd ruby

if [[ "$ASSUME_YES" == true ]]; then
  if [[ -z "$INSTANCE_NAME" || -z "$SHELL_URL" ]]; then
    echo "--yes requires both --name and --shell-url." >&2
    exit 1
  fi
else
  INSTANCE_NAME="$(prompt_if_missing "Instance name" "$INSTANCE_NAME")"
  SHELL_URL="$(prompt_if_missing "Shell URL" "$SHELL_URL")"
fi

SHELL_URL="$(ensure_trailing_slash "$SHELL_URL")"
validate_shell_url "$SHELL_URL"
validate_active_provider "$ACTIVE_PROVIDER"

if [[ -z "$INSTANCE_ID" ]]; then
  INSTANCE_ID="$(slugify "$INSTANCE_NAME")"
fi

if [[ -z "$INSTANCE_ID" ]]; then
  echo "Instance ID resolved to an empty value. Provide --instance-id explicitly." >&2
  exit 1
fi

mkdir -p \
  "$TARGET_DIR/app/site" \
  "$TARGET_DIR/knowledge/blog" \
  "$TARGET_DIR/knowledge/books" \
  "$TARGET_DIR/knowledge/papers" \
  "$TARGET_DIR/knowledge/inputs/articles" \
  "$TARGET_DIR/knowledge/inputs/notes" \
  "$TARGET_DIR/knowledge/inputs/transcripts"

if [[ ! -f "$TARGET_DIR/knowledge/index.md" ]]; then
  cat >"$TARGET_DIR/knowledge/index.md" <<'EOF'
# Knowledge Index

This directory is the source-controlled knowledge store for this youaskm3 instance.

## Categories

| Category | Purpose |
|---|---|
| `books/` | Long-form book-derived knowledge, chapter maps, and diagrams |
| `papers/` | White papers and sectioned research notes |
| `blog/` | Blog posts and shorter written artifacts |
| `inputs/` | Raw captures such as transcripts, saved articles, and notes waiting for processing |

## Ingest path

`m3 add` and later `m3 sync` populate this structure as knowledge is captured and processed.
EOF
fi

export INSTANCE_ID INSTANCE_NAME SHELL_URL ACTIVE_PROVIDER TARGET_DIR
ruby <<'RUBY'
require "json"

target_dir = ENV.fetch("TARGET_DIR")
instance = {
  "instanceId" => ENV.fetch("INSTANCE_ID"),
  "title" => ENV.fetch("INSTANCE_NAME"),
  "shellUrl" => ENV.fetch("SHELL_URL"),
  "providerProfiles" => ["browser-demo", "claude-api", "openai-api"],
  "knowledgeBase" => "knowledge/"
}

provider_config = {
  "activeProviderId" => ENV.fetch("ACTIVE_PROVIDER"),
  "profiles" => [
    {
      "id" => "browser-demo",
      "label" => "Browser demo",
      "endpoint" => "local://browser-runtime",
      "auth" => "none",
      "modelHint" => "contract-shaped local adapter",
      "publishable" => true
    },
    {
      "id" => "claude-api",
      "label" => "Claude API",
      "endpoint" => "https://api.anthropic.com/v1/messages",
      "auth" => "api-key",
      "modelHint" => "claude-sonnet or later",
      "publishable" => false
    },
    {
      "id" => "openai-api",
      "label" => "OpenAI API",
      "endpoint" => "https://api.openai.com/v1/responses",
      "auth" => "api-key",
      "modelHint" => "gpt-5 or later",
      "publishable" => false
    }
  ]
}

File.write(File.join(target_dir, "app/site/author-instance.json"), JSON.pretty_generate(instance) + "\n")
File.write(File.join(target_dir, "app/site/provider-config.json"), JSON.pretty_generate(provider_config) + "\n")
RUBY

echo "Initialized youaskm3 instance metadata in ${TARGET_DIR}"
echo "- app/site/author-instance.json"
echo "- app/site/provider-config.json"
echo "- knowledge/ directory scaffold"

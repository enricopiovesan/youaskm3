#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: ./scripts/m3-init.sh [target-dir] [--name NAME] [--shell-url URL] [--instance-id ID] [--active-provider PROFILE] [--yes]
                         [--knowledge-root PATH] [--traverse-repo PATH] [--offline]

Bootstraps local instance metadata, project config, and knowledge-root setup.
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
    browser-demo|traverse-local|claude-api|openai-api) ;;
    *)
      echo "Invalid active provider: choose browser-demo, traverse-local, claude-api, or openai-api." >&2
      exit 1
      ;;
  esac
}

validate_traverse_repo() {
  local repo="$1"
  if [[ ! -d "$repo" ]]; then
    echo "TRAVERSE_REPO_UNAVAILABLE: Traverse checkout not found: $repo" >&2
    exit 1
  fi

  if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "TRAVERSE_REPO_INVALID: Traverse path is not a git checkout: $repo" >&2
    exit 1
  fi

  if ! git -C "$repo" rev-parse -q --verify "refs/tags/v0.5.0" >/dev/null; then
    echo "TRAVERSE_BASELINE_MISSING: Traverse checkout is missing required tag v0.5.0." >&2
    exit 1
  fi

  if ! git -C "$repo" merge-base --is-ancestor "v0.5.0" HEAD >/dev/null 2>&1; then
    echo "TRAVERSE_BASELINE_TOO_OLD: Traverse checkout must be at v0.5.0 or newer." >&2
    exit 1
  fi
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
ACTIVE_PROVIDER="traverse-local"
ASSUME_YES=false
KNOWLEDGE_ROOT=""
TRAVERSE_REPO=""
OFFLINE=false

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
    --knowledge-root)
      KNOWLEDGE_ROOT="${2:-}"
      shift 2
      ;;
    --traverse-repo)
      TRAVERSE_REPO="${2:-}"
      shift 2
      ;;
    --offline)
      OFFLINE=true
      shift
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
require_cmd git

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

if [[ "$OFFLINE" == true && -n "$TRAVERSE_REPO" ]]; then
  echo "INVALID_INIT_MODE: use either --offline or --traverse-repo, not both." >&2
  exit 1
fi

if [[ -n "$TRAVERSE_REPO" ]]; then
  validate_traverse_repo "$TRAVERSE_REPO"
fi

if [[ -z "$INSTANCE_ID" ]]; then
  INSTANCE_ID="$(slugify "$INSTANCE_NAME")"
fi

if [[ -z "$INSTANCE_ID" ]]; then
  echo "Instance ID resolved to an empty value. Provide --instance-id explicitly." >&2
  exit 1
fi

if [[ -z "$KNOWLEDGE_ROOT" ]]; then
  KNOWLEDGE_ROOT="$TARGET_DIR/knowledge"
fi

mkdir -p \
  "$TARGET_DIR/app/site" \
  "$TARGET_DIR/.youaskm3" \
  "$KNOWLEDGE_ROOT/blog" \
  "$KNOWLEDGE_ROOT/books" \
  "$KNOWLEDGE_ROOT/papers" \
  "$KNOWLEDGE_ROOT/inputs/articles" \
  "$KNOWLEDGE_ROOT/inputs/notes" \
  "$KNOWLEDGE_ROOT/inputs/transcripts" \
  "$KNOWLEDGE_ROOT/gaps/open" \
  "$KNOWLEDGE_ROOT/gaps/resolved" \
  "$KNOWLEDGE_ROOT/conflicts/open" \
  "$KNOWLEDGE_ROOT/sources/decision-logs" \
  "$KNOWLEDGE_ROOT/notes/decision-logs"

if [[ ! -f "$KNOWLEDGE_ROOT/index.md" ]]; then
  cat >"$KNOWLEDGE_ROOT/index.md" <<'EOF'
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

export INSTANCE_ID INSTANCE_NAME SHELL_URL ACTIVE_PROVIDER TARGET_DIR KNOWLEDGE_ROOT TRAVERSE_REPO OFFLINE
ruby <<'RUBY'
require "json"
require "pathname"
require "time"

target_dir = ENV.fetch("TARGET_DIR")
knowledge_root = Pathname.new(ENV.fetch("KNOWLEDGE_ROOT")).expand_path
target_path = Pathname.new(target_dir).expand_path
offline = ENV.fetch("OFFLINE") == "true"
traverse_repo = ENV.fetch("TRAVERSE_REPO")
knowledge_base = begin
  "#{knowledge_root.relative_path_from(target_path)}/"
rescue ArgumentError
  knowledge_root.to_s
end

instance = {
  "instanceId" => ENV.fetch("INSTANCE_ID"),
  "title" => ENV.fetch("INSTANCE_NAME"),
  "shellUrl" => ENV.fetch("SHELL_URL"),
  "providerProfiles" => ["browser-demo", "traverse-local", "claude-api", "openai-api"],
  "knowledgeBase" => knowledge_base
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
      "publishable" => true,
      "runtime" => "browser-harness"
    },
    {
      "id" => "traverse-local",
      "label" => "Traverse local",
      "endpoint" => "http://127.0.0.1:8787",
      "auth" => "none",
      "modelHint" => "knowledge.query.answer through Traverse HTTP/JSON",
      "publishable" => false,
      "runtime" => "traverse-http",
      "workspaceId" => "youaskm3-local"
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

marker = {
  "schema_version" => "1.0.0",
  "kind" => "youaskm3_knowledge_root",
  "instance_id" => ENV.fetch("INSTANCE_ID"),
  "offline" => offline,
  "created_at" => Time.now.utc.iso8601
}

config = {
  "schema_version" => "1.0.0",
  "instance_id" => ENV.fetch("INSTANCE_ID"),
  "knowledge_root" => knowledge_root.to_s,
  "offline" => offline,
  "runtime_readiness" => if offline
                           {
                             "status" => "unavailable",
                             "reason" => "offline_init",
                             "next_action" => "Re-run m3 init with --traverse-repo <path> when Traverse is available."
                           }
                         elsif traverse_repo.empty?
                           {
                             "status" => "unconfigured",
                             "reason" => "traverse_repo_not_provided",
                             "next_action" => "Run m3 init --traverse-repo <path> or pass runtime CLI overrides."
                           }
                         else
                           {
                             "status" => "configured",
                             "reason" => "traverse_baseline_validated",
                             "next_action" => "Run ./scripts/m3.sh serve --runtime when ready."
                           }
                         end,
  "traverse" => {
    "repo" => traverse_repo.empty? ? nil : Pathname.new(traverse_repo).expand_path.to_s,
    "minimum_tag" => "v0.5.0",
    "endpoint" => "http://127.0.0.1:8787"
  }
}

File.write(knowledge_root.join(".youaskm3-knowledge-root.json"), JSON.pretty_generate(marker) + "\n")
File.write(File.join(target_dir, ".youaskm3/config.json"), JSON.pretty_generate(config) + "\n")
File.write(File.join(target_dir, "app/site/author-instance.json"), JSON.pretty_generate(instance) + "\n")
File.write(File.join(target_dir, "app/site/provider-config.json"), JSON.pretty_generate(provider_config) + "\n")
RUBY

echo "Initialized youaskm3 instance metadata in ${TARGET_DIR}"
echo "- app/site/author-instance.json"
echo "- app/site/provider-config.json"
echo "- .youaskm3/config.json"
echo "- ${KNOWLEDGE_ROOT}/ directory scaffold"

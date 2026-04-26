#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMAND="${1:-}"

cd "$ROOT_DIR"

usage() {
  echo "Usage: ./scripts/m3.sh {init|add|build|test|lint|smoke|status}" >&2
}

slugify_url() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's#^https?://##; s#[^a-z0-9]+#-#g; s#^-+##; s#-+$##'
}

run_add() {
  if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
    echo "Usage: ./scripts/m3.sh add <file.pdf|url> [title]" >&2
    exit 1
  fi

  local source_path="$1"
  local source_name="${source_path##*/}"
  local source_stem
  local title="${2:-}"

  case "$source_path" in
    http://*|https://*)
      source_stem="$(slugify_url "$source_path")"
      if [[ -n "$title" ]]; then
        bash "$ROOT_DIR/tools/url2m3/url2m3.sh" \
          "$source_path" \
          "knowledge/inputs/articles/${source_stem}.md" \
          "$title"
      else
        bash "$ROOT_DIR/tools/url2m3/url2m3.sh" \
          "$source_path" \
          "knowledge/inputs/articles/${source_stem}.md"
      fi
      ;;
    *)
      case "$source_name" in
        *.pdf|*.PDF)
          source_stem="${source_name%.*}"
          ;;
        *)
          echo "m3 add currently routes PDF files and HTTP(S) URLs." >&2
          echo "Use a .pdf input or URL for this M1 slice." >&2
          exit 1
          ;;
      esac

      bash "$ROOT_DIR/tools/pdf2m3/pdf2m3.sh" \
        "$source_path" \
        "knowledge/papers/${source_stem}/index.md" \
        "$source_path"
      ;;
  esac
}

case "$COMMAND" in
  init)
    shift
    bash ./scripts/m3-init.sh "$@"
    ;;
  add)
    shift
    run_add "$@"
    ;;
  build)
    bash ./scripts/build.sh
    ;;
  test)
    bash ./scripts/test.sh
    ;;
  lint)
    bash ./scripts/lint.sh
    ;;
  smoke)
    bash ./scripts/smoke.sh
    ;;
  status)
    echo "M0 foundation repo scaffold is present."
    ;;
  *)
    usage
    echo "Additional m3 commands arrive in later milestones." >&2
    exit 1
    ;;
esac

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMAND="${1:-}"

cd "$ROOT_DIR"

usage() {
  echo "Usage: ./scripts/m3.sh {init|add|ingest-decision-log|import-decision-log|semantic-quality|federated-answer|build|sync|search|serve|mvp-check|test|lint|smoke|status}" >&2
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
          bash "$ROOT_DIR/tools/pdf2m3/pdf2m3.sh" \
            "$source_path" \
            "knowledge/papers/${source_stem}/index.md" \
            "$source_path"
          ;;
        *.html|*.HTML|*.htm|*.HTM|*.docx|*.DOCX|*.pptx|*.PPTX|*.xlsx|*.XLSX|*.xls|*.XLS|*.csv|*.CSV|*.json|*.JSON|*.xml|*.XML|*.epub|*.EPUB|*.zip|*.ZIP)
          source_stem="${source_name%.*}"
          if [[ -n "$title" ]]; then
            bash "$ROOT_DIR/tools/markitdown2m3/markitdown2m3.sh" \
              "$source_path" \
              "knowledge/inputs/notes/${source_stem}.md" \
              "$title"
          else
            bash "$ROOT_DIR/tools/markitdown2m3/markitdown2m3.sh" \
              "$source_path" \
              "knowledge/inputs/notes/${source_stem}.md"
          fi
          ;;
        *)
          echo "m3 add currently routes PDF files, selected local document formats, and HTTP(S) URLs." >&2
          echo "Use a supported file extension or URL for this M1 slice." >&2
          exit 1
          ;;
      esac
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
  ingest-decision-log)
    shift
    ruby ./scripts/ingest-decision-log.rb "$@"
    ;;
  import-decision-log)
    shift
    ruby ./scripts/import-decision-log-package.rb "$@"
    ;;
  semantic-quality)
    shift
    ruby ./scripts/semantic-quality-evaluation.rb "$@"
    ;;
  federated-answer)
    shift
    ruby ./scripts/federated-answer.rb "$@"
    ;;
  build)
    bash ./scripts/build.sh
    ;;
  sync)
    shift
    if [[ "${1:-}" == "check" ]]; then
      shift
      ruby ./scripts/sync-preflight.rb "$@"
    else
      bash ./scripts/m3-sync.sh "$@"
    fi
    ;;
  search)
    shift
    ruby ./scripts/m3-search.rb "$@"
    ;;
  gaps)
    shift
    case "${1:-}" in
      list)
        shift
        ruby ./scripts/knowledge-gap-lifecycle.rb list-gaps "$@"
        ;;
      resolve-fact)
        shift
        ruby ./scripts/resolve-direct-fact-gap.rb "$@"
        ;;
      *)
        echo "Usage: ./scripts/m3.sh gaps {list|resolve-fact} ..." >&2
        exit 1
        ;;
    esac
    ;;
  serve)
    shift
    bash ./scripts/m3-serve.sh "$@"
    ;;
  mvp-check)
    shift
    bash ./scripts/m3-mvp-check.sh "$@"
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
    echo "Use one of the stable commands above." >&2
    exit 1
    ;;
esac

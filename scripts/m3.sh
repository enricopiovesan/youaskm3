#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMAND="${1:-}"

cd "$ROOT_DIR"

usage() {
  echo "Usage: ./scripts/m3.sh {add|build|test|lint|smoke|status}" >&2
}

run_add() {
  if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./scripts/m3.sh add <file.pdf>" >&2
    exit 1
  fi

  local source_path="$1"
  local source_name="${source_path##*/}"
  local source_stem

  case "$source_name" in
    *.pdf|*.PDF)
      source_stem="${source_name%.*}"
      ;;
    *)
      echo "m3 add currently routes PDF files through tools/pdf2m3/pdf2m3.sh." >&2
      echo "Use a .pdf input for this M1 slice." >&2
      exit 1
      ;;
  esac

  bash "$ROOT_DIR/tools/pdf2m3/pdf2m3.sh" \
    "$source_path" \
    "knowledge/papers/${source_stem}/index.md" \
    "$source_path"
}

case "$COMMAND" in
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

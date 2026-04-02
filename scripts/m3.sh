#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMAND="${1:-}"

cd "$ROOT_DIR"

case "$COMMAND" in
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
    echo "Usage: ./scripts/m3.sh {build|test|lint|smoke|status}" >&2
    echo "Additional m3 commands arrive in later milestones." >&2
    exit 1
    ;;
esac

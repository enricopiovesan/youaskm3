#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$ROOT_DIR/.cache/markitdown-venv"
PYTHON_BIN="${PYTHON:-python3}"
MARKITDOWN_VERSION="0.1.6"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd "$PYTHON_BIN"

if ! "$PYTHON_BIN" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)'; then
  echo "MarkItDown requires Python 3.10 or higher." >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/.cache"

if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

INSTALLED_VERSION="$("$VENV_DIR/bin/python" -c 'import importlib.metadata as metadata; import sys
try:
    print(metadata.version("markitdown"))
except metadata.PackageNotFoundError:
    sys.exit(1)' 2>/dev/null || true)"

if [[ "$INSTALLED_VERSION" != "$MARKITDOWN_VERSION" ]]; then
  echo "Installing markitdown==${MARKITDOWN_VERSION} into ${VENV_DIR}..." >&2
  "$VENV_DIR/bin/python" -m pip install --upgrade pip >/dev/null
  "$VENV_DIR/bin/python" -m pip install "markitdown==${MARKITDOWN_VERSION}" >/dev/null
fi

echo "$VENV_DIR/bin/markitdown"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-4173}"
SITE_DIR="$ROOT_DIR/app/site"

if [[ "$PORT" == "--help" || "$PORT" == "-h" ]]; then
  echo "Usage: ./scripts/m3.sh serve [port]"
  exit 0
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

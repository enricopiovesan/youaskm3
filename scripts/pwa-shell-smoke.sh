#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$ROOT_DIR/app/site"
HTML_FILE="$SITE_DIR/index.html"
MANIFEST_FILE="$SITE_DIR/manifest.webmanifest"
SERVICE_WORKER_FILE="$SITE_DIR/sw.js"
ICON_FILE="$SITE_DIR/icon.svg"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "PWA shell smoke failed: missing file $path" >&2
    exit 1
  fi
}

require_pattern() {
  local pattern="$1"
  local path="$2"
  local message="$3"

  if ! grep -Eq "$pattern" "$path"; then
    echo "PWA shell smoke failed: $message" >&2
    exit 1
  fi
}

require_file "$HTML_FILE"
require_file "$MANIFEST_FILE"
require_file "$SERVICE_WORKER_FILE"
require_file "$ICON_FILE"

require_pattern '<link rel="manifest" href="\./manifest\.webmanifest"' "$HTML_FILE" "index.html is not linked to the served manifest."
require_pattern 'navigator\.serviceWorker\.register\("\./sw\.js"\)' "$HTML_FILE" "index.html does not register the service worker."
require_pattern '"display":[[:space:]]*"standalone"' "$MANIFEST_FILE" "manifest is not installable."
require_pattern '"icons":[[:space:]]*\[' "$MANIFEST_FILE" "manifest is missing icons."
require_pattern 'CACHE_NAME = "youaskm3-pwa-shell-v1"' "$SERVICE_WORKER_FILE" "service worker cache name is missing."
require_pattern 'caches\.match\("\./index\.html"\)' "$SERVICE_WORKER_FILE" "service worker is missing the offline document fallback."

echo "PWA shell smoke passed."

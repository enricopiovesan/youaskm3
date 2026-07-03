#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

ruby ./scripts/generate-assistant-distribution-packages.rb --check

echo "Assistant distribution smoke passed."

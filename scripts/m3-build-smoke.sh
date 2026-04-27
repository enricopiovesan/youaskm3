#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

bash ./scripts/m3.sh build

[[ -f app/site/search-index.json ]]
[[ -f app/site/build-manifest.json ]]

grep -q '"documents"' app/site/search-index.json
grep -q '"artifacts"' app/site/build-manifest.json
grep -q '"app/site/search-index.json"' app/site/build-manifest.json

echo "m3 build smoke passed."

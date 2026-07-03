#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

DOC="docs/hosted-service-architecture.md"
SPEC="openspec/specs/hosted-service/spec.md"

[[ -f "$DOC" ]]
grep -q '^## Local-First Boundary$' "$DOC"
grep -q '^## Identity Model$' "$DOC"
grep -q '^## Teams And Permissions$' "$DOC"
grep -q '^## Hosted Sync$' "$DOC"
grep -q '^## Security And Privacy Risks$' "$DOC"
grep -q 'Hosted account id' "$DOC"
grep -q 'Local persona id' "$DOC"
grep -q 'Semantic conflicts become conflict records' "$DOC"
grep -q 'local-first operation remains possible with no hosted config' "$DOC"

grep -q 'hosted accounts, teams, and permissions separately from local persona metadata' "$SPEC"
grep -q 'semantic conflicts become conflict records instead of silent overwrite' "$SPEC"

echo "Hosted service smoke passed."

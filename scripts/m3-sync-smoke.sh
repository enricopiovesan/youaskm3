#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p \
  "$TEMP_DIR/app/site" \
  "$TEMP_DIR/knowledge/blog" \
  "$TEMP_DIR/knowledge/books" \
  "$TEMP_DIR/knowledge/papers" \
  "$TEMP_DIR/knowledge/inputs/articles" \
  "$TEMP_DIR/scripts"

cp "$ROOT_DIR/app/site/author-instance.json" "$TEMP_DIR/app/site/author-instance.json"
cp "$ROOT_DIR/app/site/provider-config.json" "$TEMP_DIR/app/site/provider-config.json"
cp "$ROOT_DIR/scripts/m3.sh" "$TEMP_DIR/scripts/m3.sh"
cp "$ROOT_DIR/scripts/m3-sync.sh" "$TEMP_DIR/scripts/m3-sync.sh"
cp "$ROOT_DIR/scripts/generate-site-artifacts.rb" "$TEMP_DIR/scripts/generate-site-artifacts.rb"

cat <<'EOF' > "$TEMP_DIR/knowledge/blog/first-note.md"
# First Note

Portable knowledge should stay queryable.
EOF

(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync
)

[[ -f "$TEMP_DIR/app/site/search-index.json" ]]
[[ -f "$TEMP_DIR/app/site/build-manifest.json" ]]
[[ -f "$TEMP_DIR/app/site/sync-state.json" ]]

cp "$TEMP_DIR/app/site/search-index.json" "$TEMP_DIR/app/site/search-index.initial.json"
cp "$TEMP_DIR/app/site/build-manifest.json" "$TEMP_DIR/app/site/build-manifest.initial.json"
cp "$TEMP_DIR/app/site/sync-state.json" "$TEMP_DIR/app/site/sync-state.initial.json"

second_sync_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync
)"

grep -q "already up to date" <<<"$second_sync_output"
cmp -s "$TEMP_DIR/app/site/search-index.initial.json" "$TEMP_DIR/app/site/search-index.json"
cmp -s "$TEMP_DIR/app/site/build-manifest.initial.json" "$TEMP_DIR/app/site/build-manifest.json"
cmp -s "$TEMP_DIR/app/site/sync-state.initial.json" "$TEMP_DIR/app/site/sync-state.json"

cat <<'EOF' > "$TEMP_DIR/knowledge/blog/second-note.md"
# Second Note

Incremental sync should only rebuild generated metadata.
EOF

third_sync_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync
)"

grep -q "Detected source changes" <<<"$third_sync_output"
grep -q '"knowledge/blog/second-note.md"' "$TEMP_DIR/app/site/search-index.json"
grep -q '"sourceFingerprint"' "$TEMP_DIR/app/site/build-manifest.json"
grep -q '"trackedSourcePaths"' "$TEMP_DIR/app/site/sync-state.json"

echo "m3 sync smoke passed."

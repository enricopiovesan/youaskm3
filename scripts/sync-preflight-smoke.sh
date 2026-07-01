#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$TEMP_DIR/app/site" "$TEMP_DIR/knowledge/inputs/notes" "$TEMP_DIR/knowledge/conflicts/open" "$TEMP_DIR/scripts"

cp "$ROOT_DIR/app/site/author-instance.json" "$TEMP_DIR/app/site/author-instance.json"
cp "$ROOT_DIR/app/site/provider-config.json" "$TEMP_DIR/app/site/provider-config.json"
cp "$ROOT_DIR/scripts/m3.sh" "$TEMP_DIR/scripts/m3.sh"
cp "$ROOT_DIR/scripts/m3-sync.sh" "$TEMP_DIR/scripts/m3-sync.sh"
cp "$ROOT_DIR/scripts/sync-preflight.rb" "$TEMP_DIR/scripts/sync-preflight.rb"
cp "$ROOT_DIR/scripts/generate-site-artifacts.rb" "$TEMP_DIR/scripts/generate-site-artifacts.rb"
cp "$ROOT_DIR/scripts/reasoning-graph-extractor.rb" "$TEMP_DIR/scripts/reasoning-graph-extractor.rb"
cp "$ROOT_DIR/scripts/knowledge-gap-lifecycle.rb" "$TEMP_DIR/scripts/knowledge-gap-lifecycle.rb"

(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync >/dev/null
)

clean_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync check --json
)"
ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected clean" unless data.fetch("status") == "clean" && data.fetch("code") == "SYNC_CLEAN"' <<<"$clean_output"

cat >"$TEMP_DIR/knowledge/inputs/notes/daily.append.md" <<'EOF'
# Daily Append

Safe append-only note.
EOF

merge_output="$(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync check --json
)"
ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected auto merge" unless data.fetch("status") == "auto_merged" && data.fetch("auto_merged").length == 1' <<<"$merge_output"
[[ -f "$TEMP_DIR/knowledge/inputs/notes/daily.md" ]]
[[ ! -e "$TEMP_DIR/knowledge/inputs/notes/daily.append.md" ]]

(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync >/dev/null
)

cat >"$TEMP_DIR/knowledge/inputs/notes/conflicted.md" <<'EOF'
<<<<<<< local
one
=======
two
>>>>>>> remote
EOF

if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync check --write-conflicts --json >/tmp/sync-conflict.json
); then
  echo "Expected conflict marker preflight to fail." >&2
  exit 1
fi
ruby -rjson -e 'data=JSON.parse(File.read("/tmp/sync-conflict.json")); abort "expected open conflict" unless data.fetch("status") == "open_conflict" && data.fetch("code") == "SYNC_CONFLICT_OPEN"; abort "missing written conflict" if data.fetch("written_conflict_paths").empty?' 

rm "$TEMP_DIR/knowledge/inputs/notes/conflicted.md"
rm "$TEMP_DIR"/knowledge/conflicts/open/*.md

echo '{}' >"$TEMP_DIR/app/site/sync-state.json"
if (
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync check --json >/tmp/sync-blocked.json
); then
  echo "Expected dirty metadata preflight to fail." >&2
  exit 1
fi
ruby -rjson -e 'data=JSON.parse(File.read("/tmp/sync-blocked.json")); abort "expected blocked dirty metadata" unless data.fetch("status") == "blocked" && data.fetch("code") == "SYNC_METADATA_DIRTY"'

echo "Sync preflight smoke passed."

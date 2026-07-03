#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT_DIR"

disabled_output="$(
  ruby ./scripts/federated-answer.rb answer \
    --query "WASM component evidence" \
    --federation-index fixtures/federated-answer/federation-search-index.json \
    --policy fixtures/federated-answer/policy-disabled.json \
    --knowledge-root "$TEMP_DIR/knowledge"
)"
ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected local only disabled mode" unless data.fetch("status") == "local_only" && data.fetch("remote_query_performed") == false && data.fetch("evidence").empty?' <<<"$disabled_output"

enabled_file="$TEMP_DIR/enabled-answer.json"
ruby ./scripts/federated-answer.rb answer \
  --query "WASM component evidence" \
  --federation-index fixtures/federated-answer/federation-search-index.json \
  --policy fixtures/federated-answer/policy-enabled.json \
  --knowledge-root "$TEMP_DIR/knowledge" >"$enabled_file"
ruby -rjson -e 'data=JSON.parse(File.read(ARGV[0])); evidence=data.fetch("evidence").first; abort "expected remote evidence" unless data.fetch("status") == "remote_evidence" && evidence.fetch("evidence_kind") == "remote" && evidence.fetch("remote_instance").fetch("id") == "remote-systems" && evidence.fetch("source_artifact").fetch("id") == "remote-wasm-notes" && evidence.fetch("retrieval").fetch("path") == "federation-search-index" && evidence.key?("confidence")' "$enabled_file"

import_output="$(
  ruby ./scripts/federated-answer.rb import \
    --evidence "$enabled_file" \
    --knowledge-root "$TEMP_DIR/knowledge"
)"
ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected import without personal knowledge promotion" unless data.fetch("status") == "imported" && data.fetch("personal_knowledge") == false' <<<"$import_output"
[[ -f "$TEMP_DIR/knowledge/sources/federated/remote-systems/remote-wasm-notes.json" ]]
grep -q '"personal_knowledge": false' "$TEMP_DIR/knowledge/sources/federated/remote-systems/remote-wasm-notes.json"
grep -q '"remote_instance"' "$TEMP_DIR/knowledge/sources/federated/remote-systems/remote-wasm-notes.json"

echo "Federated answer smoke passed."

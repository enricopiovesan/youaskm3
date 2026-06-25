#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

cd "$ROOT_DIR"

bash ./scripts/m3-init.sh "$TEMP_DIR" \
  --name "MVP Local Loop Smoke" \
  --shell-url "https://example.com/mvp-local-loop/" \
  --instance-id "mvp-local-loop" \
  --active-provider "browser-demo" \
  --yes >/dev/null

mkdir -p \
  "$TEMP_DIR/knowledge/blog" \
  "$TEMP_DIR/scripts"

cp "$ROOT_DIR/scripts/m3.sh" "$TEMP_DIR/scripts/m3.sh"
cp "$ROOT_DIR/scripts/m3-sync.sh" "$TEMP_DIR/scripts/m3-sync.sh"
cp "$ROOT_DIR/scripts/generate-site-artifacts.rb" "$TEMP_DIR/scripts/generate-site-artifacts.rb"

cat >"$TEMP_DIR/knowledge/blog/source-grounding.md" <<'EOF'
# Source Grounding

Source grounding keeps local knowledge answers traceable to markdown files,
stable chunk identifiers, and graph evidence that the product can render.
EOF

(
  cd "$TEMP_DIR"
  bash ./scripts/m3.sh sync >/dev/null
)

[[ -f "$TEMP_DIR/app/site/search-index.json" ]]
[[ -f "$TEMP_DIR/app/site/knowledge-graph.json" ]]

node --input-type=module - "$ROOT_DIR" "$TEMP_DIR" <<'NODE'
import { readFileSync } from "node:fs";
import path from "node:path";

const [rootDir, tempDir] = process.argv.slice(2);
const runtime = await import(path.join(rootDir, "app/site/runtime.js"));

function readJson(relativePath) {
  return JSON.parse(readFileSync(path.join(tempDir, relativePath), "utf8"));
}

const searchIndex = readJson("app/site/search-index.json");
const graph = readJson("app/site/knowledge-graph.json");

if (!Array.isArray(searchIndex.documents) || searchIndex.documents.length === 0) {
  throw new Error("MVP local loop smoke requires a non-empty search index.");
}

if (!Array.isArray(graph.edges) || graph.edges.length === 0) {
  throw new Error("MVP local loop smoke requires a graph artifact with edges.");
}

const documents = runtime.documentsFromSearchIndex(searchIndex);
const answer = runtime.temporaryTraverseChatHarness(
  { query: "source grounding", max_sources: 3 },
  documents,
  graph
);

if (!Array.isArray(answer.citations) || answer.citations.length === 0) {
  throw new Error("MVP local loop smoke requires an answer with citations.");
}

if (!Array.isArray(answer.graph_evidence) || answer.graph_evidence.length === 0) {
  throw new Error("MVP local loop smoke requires graph evidence for cited chunks.");
}

if (answer.validation?.status !== "valid") {
  throw new Error(`MVP local loop smoke expected valid answer, got ${answer.validation?.status}`);
}
NODE

echo "MVP local loop smoke passed."

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

ruby ./scripts/wasm-native-model-evidence.rb validate \
  --evidence fixtures/wasm-native-model-evidence/governed-only.json \
  --claim-wasm-native false \
  | ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected caveated governed inference" unless data.fetch("status") == "traverse_governed_with_wasm_native_caveat" && data.fetch("model_engine_wasm_native") == false'

if ruby ./scripts/wasm-native-model-evidence.rb validate \
  --evidence fixtures/wasm-native-model-evidence/governed-only.json \
  --claim-wasm-native true >/tmp/wasm-native-unsupported.json; then
  echo "Expected unsupported WASM-native model claim to fail." >&2
  exit 1
fi
ruby -rjson -e 'data=JSON.parse(File.read("/tmp/wasm-native-unsupported.json")); abort "expected unsupported claim code" unless data.fetch("code") == "UNSUPPORTED_WASM_NATIVE_MODEL_CLAIM"'

ruby ./scripts/wasm-native-model-evidence.rb validate \
  --evidence fixtures/wasm-native-model-evidence/wasm-native.json \
  --claim-wasm-native true \
  | ruby -rjson -e 'data=JSON.parse(STDIN.read); abort "expected positive WASM-native proof" unless data.fetch("status") == "wasm_native_model_engine_proven" && data.fetch("model_engine_wasm_native") == true'

grep -q 'model engine itself runs as WASM' docs/wasm-native-model-evidence.md
grep -q 'Docs preserve the WASM-native model caveat until Traverse proves that path.' docs/mvp-local-inference-policy.md

echo "WASM-native model evidence smoke passed."

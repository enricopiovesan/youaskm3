# youaskm3 Traverse Application Bundle

This directory contains the first youaskm3 application bundle skeleton for
Traverse `v0.4.0`.

It is the checked-in target shape for registering the first MVP chat workflow
through Traverse public application-bundle surfaces. It is intentionally not a
complete, registerable production bundle yet because the real WASM capability
binaries and binary digests are created by later MVP tickets.

## Baseline

- Minimum Traverse release: `v0.4.0`
- Traverse release date: 2026-06-22
- Traverse release: <https://github.com/enricopiovesan/Traverse/releases/tag/v0.4.0>
- Governing Traverse specs:
  - `044-application-bundle-manifest`
  - `045-governed-model-dependency-resolution`
- youaskm3 governing spec:
  - `openspec/specs/traverse-integration/spec.md`

Traverse `v0.4.0` provides the public surfaces this skeleton targets:

- application manifests
- WASM component manifests
- atomic app bundle registration
- governed model dependency resolution
- HTTP/JSON execution and trace paths
- MCP reporting
- downstream app MVP conformance through
  `bash scripts/ci/downstream_app_mvp_conformance.sh`

## Files

| Path | Purpose |
|---|---|
| `manifest.json` | Application-level manifest for the youaskm3 knowledge app. |
| `components/*/component.manifest.json` | Component manifest placeholders for each MVP capability contract. |
| `workflows/knowledge-query-answer.workflow.json` | First chat workflow composed from MVP capability contracts. |

## Capability Contracts

The bundle references these checked-in capability contracts:

- `knowledge.query.answer`
- `knowledge.retrieve`
- `knowledge.graph.expand`
- `knowledge.context.pack`
- `knowledge.infer`
- `knowledge.answer.validate`
- `knowledge.answer.format`

The first workflow composes them in this order:

1. retrieve candidate sources
2. expand graph context
3. pack model context
4. delegate inference through governed `knowledge.infer`
5. validate grounding
6. format the final answer envelope

## Pending Implementation Fields

The component manifests use Traverse v0.4.0 field names now, but the following
fields are placeholders until the corresponding WASM or agent artifacts exist:

- `wasm_binary_path`
- `wasm_digest`
- component `digest` entries in `manifest.json`
- `implementation_status`
- `validation_evidence`

Placeholder digests are all-zero SHA-256 values and must not be treated as
real registration evidence. The manifest generator keeps these placeholders
only when explicitly run in skeleton mode:

```bash
bash scripts/traverse-component-manifests.sh --skeleton
bash scripts/traverse-component-manifests.sh --skeleton --check
```

When real capability WASM binaries are expected, omit `--skeleton`. The command
then fails on any missing `wasm_binary_path` and writes SHA-256 digests from the
actual `.wasm` files into each component manifest and the app manifest component
entries.

## Model Dependency

The app manifest declares inference through Traverse v0.4.0
`model_dependencies` using the `traverse.inference.generate` interface.

The local Ollama candidate is a Traverse-resolved provider candidate, not
hardcoded downstream business logic. The default readiness path must not require
a live local model. Live local model conformance remains separately gated by:

```bash
TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1 bash scripts/ci/downstream_app_mvp_conformance.sh
```

The current baseline proves governed model dependency resolution. It does not
prove that the model engine itself is WASM-native.

## Registration Status

This skeleton should fail real Traverse registration until later tickets provide
real component artifacts and digests. That is expected.

Follow-up tickets:

- MVP-013: first `knowledge.retrieve` WASM capability
- MVP-014: `knowledge.answer.validate`
- MVP-023: `knowledge.graph.expand`
- MVP-024: `knowledge.context.pack`
- MVP-025: `knowledge.answer.format`
- MVP-026: `knowledge.query.answer` workflow entrypoint
- MVP-027: generated component manifests and binary digests
- MVP-018: real bundle registration with Traverse v0.4.0

## Local Validation

For this skeleton slice:

```bash
rg -n "v0.4.0|model_dependencies|knowledge.query.answer|knowledge.retrieve|knowledge.infer" traverse/youaskm3-app
bash scripts/traverse-component-manifests.sh --skeleton --check
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

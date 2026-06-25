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

The downstream first-MVP policy for this boundary lives in
[`docs/mvp-local-inference-policy.md`](../../docs/mvp-local-inference-policy.md).
Missing local inference must fail as `MISSING_MODEL_DEPENDENCY` or a more
specific inference dependency error, not as a hidden fallback to downstream
provider logic.

## Registration Status

This skeleton should fail real Traverse registration until later tickets provide
real component artifacts and digests. That is expected.

The youaskm3-side registration entrypoint is:

```bash
bash scripts/register-traverse-app.sh --validate-only --allow-skeleton --json
TRAVERSE_REPO=/path/to/Traverse bash scripts/register-traverse-app.sh --allow-skeleton --json
```

`--validate-only` is CI-safe and does not require a Traverse checkout. Real
registration requires Traverse `v0.4.0` or newer and real WASM component
artifacts. While the checked-in bundle remains a skeleton, the command emits
machine-readable `SKELETON_PENDING_WASM_COMPONENTS` evidence instead of
pretending the bundle registered.

If real component artifacts are present but Traverse does not yet expose a
public external app-register CLI for this application manifest shape, the
command fails with `MISSING_PUBLIC_APP_REGISTRATION_SURFACE`. That is a
Traverse integration requirement, not a downstream hidden fallback.

The end-to-end answer workflow integration gate is:

```bash
bash scripts/traverse-answer-workflow-smoke.sh
TRAVERSE_REPO=/path/to/Traverse bash scripts/traverse-answer-workflow-smoke.sh
```

The gate validates prepared search artifacts, graph source evidence, public
trace requirements, model dependency policy, Traverse `v0.4.0` readiness, and
the app registration boundary. Without `TRAVERSE_REPO`, it validates local
youaskm3 artifacts and skips the live Traverse step so default smoke remains
CI-safe. In the current skeleton state, the live Traverse step passes only when
execution is blocked by `SKELETON_PENDING_WASM_COMPONENTS`; once real component
WASM artifacts are available, the same gate should be tightened to expect live
`knowledge.query.answer` execution evidence.

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

# youaskm3 Traverse Application Bundle

This directory contains the first youaskm3 application bundle for Traverse
`v0.5.0`.

It is the checked-in target shape for registering the first MVP chat workflow
through Traverse public application-bundle surfaces. The checked-in component
manifests now carry real release WASM binary digests for the MVP capability
artifacts; live app registration now targets the public Traverse CLI app
validation and local workspace registration surfaces added in Traverse v0.5.0.

## Baseline

- Minimum Traverse release: `v0.5.0`
- Traverse release date: 2026-06-26
- Traverse release: <https://github.com/traverse-framework/Traverse/releases/tag/v0.5.0>
- Governing Traverse specs:
  - `044-application-bundle-manifest`
  - `045-governed-model-dependency-resolution`
  - `046-public-cli-app-registration`
- youaskm3 governing spec:
  - `openspec/specs/traverse-integration/spec.md`

Traverse `v0.5.0` provides the public surfaces this bundle targets:

- application manifests
- WASM component manifests
- atomic app bundle registration
- governed model dependency resolution
- HTTP/JSON execution and trace paths
- MCP reporting
- downstream app MVP conformance through
  `bash scripts/ci/downstream_app_mvp_conformance.sh`
- public CLI app validation through
  `traverse-cli app validate --manifest <path> --json`
- public CLI local workspace registration through
  `traverse-cli app register --manifest <path> --workspace <workspace-id> --json`

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

## Component Artifact Evidence

The component manifests use Traverse v0.5.0-compatible field names and reference release
WASM artifacts under `target/wasm32-wasip1/release`. Generate or verify real
component evidence with:

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
cargo build --locked --workspace --target wasm32-wasip1 --release

bash scripts/traverse-component-manifests.sh
bash scripts/traverse-component-manifests.sh --check
```

The generator fails when a referenced WASM binary is missing unless it is
explicitly run with `--skeleton` for future placeholder-only development. MVP
runtime acceptance must not use skeleton mode, all-zero digests, pending
implementation markers, or placeholder validation evidence.

## Model Dependency

The app manifest declares inference through Traverse v0.5.0
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

The bundle has real component artifact digests and passes local validation.
Real Traverse registration must now use the public v0.5.0 CLI app validation
and local workspace registration surfaces.

The youaskm3-side registration entrypoint is:

```bash
bash scripts/register-traverse-app.sh --validate-only --json
TRAVERSE_REPO=/path/to/Traverse bash scripts/register-traverse-app.sh --json
```

`--validate-only` is CI-safe and does not require a Traverse checkout. With
`TRAVERSE_REPO` set to Traverse `v0.5.0` or newer and real WASM component
artifacts present, the wrapper invokes public `traverse-cli app validate` and
`traverse-cli app register` and returns the CLI-produced validation,
registration, digest, workspace, app, workflow, model-readiness, and failure
evidence in its JSON output.

The end-to-end answer workflow integration gate is:

```bash
bash scripts/traverse-answer-workflow-smoke.sh
TRAVERSE_REPO=/path/to/Traverse bash scripts/traverse-answer-workflow-smoke.sh
```

The gate validates prepared search artifacts, graph source evidence, public
trace requirements, model dependency policy, Traverse `v0.5.0` readiness, and
the app registration boundary. Without `TRAVERSE_REPO`, it validates local
youaskm3 artifacts and skips the live Traverse step so default smoke remains
CI-safe. With real component artifacts available, the live Traverse step
validates/registers through Traverse v0.5.0 public CLI surfaces or returns a
stable youaskm3 implementation/setup error.

The MCP parity gate is:

```bash
bash scripts/traverse-mcp-answer-workflow-smoke.sh
TRAVERSE_REPO=/path/to/Traverse bash scripts/traverse-mcp-answer-workflow-smoke.sh
```

Without `TRAVERSE_REPO`, it proves the MCP tool contract maps to the same
registered `knowledge.query.answer` workflow, capability contract, component
manifests, trace evidence, failure policies, and model dependency metadata as
the app-facing path. With `TRAVERSE_REPO`, it also runs Traverse's public
downstream MCP smoke so the release pairing proves MCP model-resolution
evidence through Traverse-owned surfaces.

Follow-up tickets:

- MVP-031: local Traverse-backed chat happy path
- MVP-033: imported-document answer acceptance test
- MVP-035: Traverse blocker escalation process

## Local Validation

For this bundle slice:

```bash
rg -n "v0.5.0|model_dependencies|knowledge.query.answer|knowledge.retrieve|knowledge.infer" traverse/youaskm3-app
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
cargo build --locked --workspace --target wasm32-wasip1 --release
bash scripts/traverse-component-manifests.sh --check
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

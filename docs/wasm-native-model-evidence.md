# WASM-Native Model Engine Evidence

## Purpose

youaskm3 can already require Traverse-governed inference selection, placement, trace evidence, and failure handling. That is not the same as proving that the model engine itself runs as WASM.

Until Traverse exposes stable model-engine execution evidence, release notes and readiness reports must keep the first-MVP caveat: inference is Traverse-governed, but the model engine is not proven WASM-native.

## Required Evidence

A positive WASM-native model-engine claim requires Traverse evidence with all of these fields:

- `traverse_version`
- `inference_dependency_id`
- `selected_candidate_id`
- `model_dependency_id`
- `model_engine_wasm_native: true`
- `module_identity`
- `module_sha256`, as a SHA-256 digest
- `model_asset_id`
- `model_asset_sha256`, as a SHA-256 digest
- `runtime_placement: wasm`
- `execution_trace_id`
- `failure_mode: null`

If any required positive evidence is absent, the readiness validator must fail a positive WASM-native model-engine claim.

## Supported Distinction

Governed inference evidence may prove:

- Traverse selected an inference dependency.
- Traverse recorded placement and trace evidence.
- Traverse reported selected or rejected candidates.
- youaskm3 did not hardcode downstream provider selection.

WASM-native model-engine evidence must additionally prove:

- the engine module identity
- the engine module digest
- the model asset identity
- the model asset digest
- WASM runtime placement
- the model dependency id connected to that execution
- the public trace id for the execution
- no failure mode for the claimed successful execution

## Readiness Policy

The readiness validator supports two release postures:

- Caveated posture: `--claim-wasm-native false`; governed inference may pass while the WASM-native model caveat remains.
- Positive posture: `--claim-wasm-native true`; the validator fails unless required Traverse evidence proves model-engine WASM-native execution.

This keeps unsupported WASM-native model claims out of docs, release notes, and acceptance reports.

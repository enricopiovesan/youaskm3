# First MVP Local Inference Readiness Policy

Status: First-MVP policy
Owner: youaskm3 Traverse integration
Last updated: 2026-06-22

## Purpose

This policy defines what "local inference ready" means for the first MVP.

The first MVP must not require a paid external service, hosted account, hosted database, or live local LLM in the default validation path. Inference is still a governed runtime dependency: youaskm3 declares `knowledge.infer` and Traverse resolves, places, traces, and fails that dependency through public Traverse surfaces.

## Policy

### Default Validation

Default CI and `bash scripts/smoke.sh` MUST NOT require a live local LLM.

Default smoke validates that:

- the inference need is declared in `contracts/capabilities/knowledge.infer.json`
- the app manifest declares governed `model_dependencies`
- Traverse-specific readiness can be checked separately with `bash scripts/traverse-readiness.sh`
- missing inference capability is treated as a runtime dependency failure, not as a missing repo setup step

### Optional Live Local Conformance

Live local inference proof is opt-in for the first MVP:

```bash
TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1 bash scripts/traverse-readiness.sh
```

Minimum supported first-MVP local provider configuration:

- Provider path: Traverse-governed local Ollama provider candidate
- Candidate id: `local-ollama-llama-3-2`
- Model identifier: `llama3.2:3b`
- Default base URL: `http://127.0.0.1:11434`
- Minimum context window: 8192 tokens

This provider is a Traverse-resolved candidate. youaskm3 UI, CLI, and business capability code MUST NOT hardcode Ollama, WebLLM, llama.cpp, a cloud API, or any fallback provider.

### Missing Model Dependency

When no compatible inference capability is available, the app-facing answer workflow MUST fail clearly as a dependency failure.

Required failure category:

- `MISSING_MODEL_DEPENDENCY`

Allowed more-specific failure codes:

- `INFERENCE_PROVIDER_UNAVAILABLE`
- `INFERENCE_PLACEMENT_UNSATISFIED`
- `INFERENCE_DEPENDENCY_REJECTED`

Required user-facing copy shape:

```text
Inference dependency unavailable. Traverse could not resolve a compatible local or allowed server inference capability for this workspace.
```

The UI may shorten that copy for layout, but it must preserve the meaning:

- the app setup is not necessarily broken
- the knowledge artifacts are not necessarily broken
- the failure is about Traverse dependency resolution or provider availability
- the user can enable optional local conformance only when they intentionally run a compatible local provider

### Trace Evidence

When Traverse resolves inference, the public trace or execution report SHOULD expose:

- inference interface id
- selected candidate id when resolution succeeds
- rejected candidate ids or rejection reasons when resolution fails
- placement target considered or selected
- provider implementation id only when safe for public display
- stable failure code for missing or rejected inference dependency

The UI may display summarized placement and dependency status, but it must not duplicate Traverse's routing or provider-selection logic.

### WASM-Native Model Caveat

Traverse `v0.5.0` preserves governed model dependency resolution and includes an opt-in local Ollama provider path. It does not prove that the model engine itself is WASM-native.

The first MVP may proceed while this caveat is true because the architectural requirement is that inference selection, placement, trace evidence, and failure handling are governed by Traverse rather than hardcoded downstream app logic. A later release may require the model engine itself to run as WASM when Traverse exposes stable readiness evidence for that path.

## Acceptance Checks

- `scripts/traverse-readiness.sh` reports live local model conformance separately from baseline Traverse readiness.
- Default smoke passes without `TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1`.
- Optional live local model conformance is documented with the exact opt-in command.
- Missing inference capability uses `MISSING_MODEL_DEPENDENCY` or a more-specific inference dependency code.
- Docs preserve the WASM-native model caveat until Traverse proves that path.

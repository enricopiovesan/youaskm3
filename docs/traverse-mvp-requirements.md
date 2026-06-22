# Traverse Requirements for the First Knowledge-App MVP

Status: Updated for Traverse v0.4.0 first-MVP baseline
Owner: youaskm3 downstream integration
Last updated: 2026-06-22

## Purpose

This document describes what a downstream local-first knowledge application needs from Traverse for its first MVP.

The Traverse team should be able to read this without knowing the product roadmap. The downstream application can be summarized as:

- a browser/PWA user interface
- a local CLI that prepares static knowledge artifacts from user-owned files
- a chat experience that answers from those artifacts with source attribution
- all product/business behavior executed as governed WASM capabilities through Traverse

The core requirement is not "make a chat app." The core requirement is:

> Traverse must be able to run, compose, trace, and expose portable WASM business capabilities for a downstream application whose UI is only a UI and whose CLI is only a build/setup caller.

## Non-Negotiable Architecture Rule

All downstream product/business logic must run through Traverse as governed WASM capabilities or agents.

The UI may render screens, collect input, and display results. The CLI may convert files, write artifacts, start local services, and register bundles. Neither the UI nor the CLI should own core business decisions such as retrieval ranking, graph traversal, context construction, answer grounding, citation validation, or model selection.

Traverse is expected to own the runtime boundary:

- capability registration
- capability execution
- WASM execution
- capability contracts
- event contracts
- workflow composition
- runtime placement
- execution traces
- MCP exposure
- app-facing HTTP/JSON exposure
- model/capability dependency resolution
- local/server placement decisions where applicable

The downstream app should only depend on Traverse public surfaces, not private crate internals.

## Current Baseline Confirmed

As of 2026-06-22, Traverse `v0.4.0` is the minimum approved first-MVP integration baseline for this downstream app.

Release:

- Tag: `v0.4.0`
- URL: https://github.com/enricopiovesan/Traverse/releases/tag/v0.4.0
- Release date: 2026-06-22
- Governing Traverse specs: `044-application-bundle-manifest` and `045-governed-model-dependency-resolution`

The exact `v0.4.0` tag conformance path passed locally:

```bash
bash scripts/ci/downstream_app_mvp_conformance.sh
```

Traverse `v0.4.0` covers the first-MVP runtime baseline:

- application bundle manifests
- WASM component manifests
- atomic app bundle registration
- governed model dependency schema and resolution
- deterministic selected/rejected model candidate evidence
- local Ollama inference provider path, opt-in for live local conformance
- HTTP/JSON app path exists
- MCP stdio path exists
- WASM execution via Wasmtime exists
- public trace evidence exists
- programmatic registration exists
- downstream app MVP conformance exists

Important caveat:

Traverse `v0.4.0` proves governed model dependency resolution and includes a local Ollama provider path, but the default conformance suite does not require a reachable live local model. Live local Ollama conformance is separately gated with `TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1`. Also, this baseline does not prove that the model engine itself is WASM-native. The first youaskm3 MVP may proceed as long as `knowledge.infer` is declared, resolved, placed, traced, and failed through Traverse-governed dependency surfaces rather than hardcoded downstream app provider logic.

The downstream local inference policy is defined in [mvp-local-inference-policy.md](mvp-local-inference-policy.md). Default youaskm3 smoke must not require a live local LLM; optional live local conformance remains explicit and opt-in.

## MVP Runtime Flow

The downstream app needs this end-to-end runtime flow:

1. CLI prepares local artifacts from user-owned source files.
2. CLI registers a Traverse application bundle into a workspace.
3. Browser/PWA discovers the local Traverse app endpoint.
4. Browser/PWA sends a user prompt to Traverse.
5. Traverse executes a governed workflow composed of WASM capabilities.
6. Capabilities retrieve relevant artifacts, traverse graph context, construct prompt/context, call model inference, validate grounding, and return an answer.
7. Traverse returns a structured result and public trace.
8. UI renders answer, citations, graph/source evidence, and execution status.
9. MCP clients can discover and call the same governed capabilities through Traverse MCP.

## Boundaries

### Downstream CLI Owns

The CLI may own build/setup tooling:

- file discovery
- file-to-markdown conversion using external tools such as MarkItDown
- writing static artifacts to disk
- invoking build/sync
- starting local Traverse where appropriate
- registering Traverse bundles through public APIs

Important boundary: conversion tooling is allowed outside Traverse when it is mechanical source conversion. If transformation becomes product semantics, it should move into a Traverse capability.

Examples:

- Allowed outside Traverse: "convert this DOCX/PDF/PPTX to raw markdown."
- Should be inside Traverse: "decide which chunks are relevant to a user question."
- Should be inside Traverse: "validate that an answer is grounded in sources."
- Should be inside Traverse: "choose graph paths to include in context."

### Downstream UI Owns

The UI may own:

- visual layout
- chat input
- rendering messages
- rendering source cards
- rendering graph views
- rendering trace/status details
- local browser storage for UI preferences

The UI must not own:

- retrieval logic
- ranking logic
- graph traversal logic
- prompt construction
- answer validation
- citation enforcement
- model placement decisions
- hidden alternate runtime behavior

### Traverse Owns

Traverse must own:

- validated capability execution
- WASM capability sandboxing
- capability placement
- workflow orchestration
- evented capability coordination
- dependency resolution
- trace generation
- app-facing APIs
- MCP-facing APIs
- model/inference capability abstraction
- local/server execution policy

## Prioritized Requirements

### P0 - Required for MVP

#### TRV-P0-001: Governed Application Bundle Registration

Traverse must support registering a complete downstream application bundle into a workspace through public APIs.

The bundle must include:

- capability contracts
- event contracts
- workflow definitions
- WASM agent/capability package manifests
- binary paths and digests
- model dependency declarations
- runtime constraints
- permitted targets

Acceptance criteria:

- A CLI can register the bundle without depending on private Traverse internals.
- Bundle registration is idempotent.
- Bundle registration is atomic.
- Invalid bundles fail before partial registration.
- Registration returns machine-readable artifact ids, versions, digests, and execution links.
- Registration can be validated in CI.

#### TRV-P0-002: WASM Business Capability Execution

Traverse must execute downstream business capabilities compiled to WASM.

Acceptance criteria:

- WASM modules run through the governed Traverse executor.
- Input is passed as JSON according to the capability contract.
- Output is returned as JSON according to the capability contract.
- Binary digest is verified before execution.
- Unauthorized host imports are rejected.
- No ambient filesystem, network, or environment access is granted.
- Execution result and failure modes appear in traces.

#### TRV-P0-003: Model Inference as a Governed Capability

Traverse must model LLM inference as a governed capability or agent dependency, not as hidden downstream app code.

The downstream app should declare that it needs an inference capability by contract. Traverse should decide how to satisfy and place that capability.

Acceptance criteria:

- A downstream capability can declare a model/inference dependency using a governed contract.
- Traverse can resolve the dependency at registration or execution time.
- Traverse can fail clearly if no compatible inference capability is available.
- The downstream app does not hardcode Ollama, WebLLM, llama.cpp, a cloud API, or any provider.
- The same downstream workflow can run against different inference implementations as Traverse improves.
- The selected inference capability and placement appear in the trace.

#### TRV-P0-004: Runtime Dependency Resolution for Model Dependencies

Traverse `v0.4.0` turns model dependency declarations into runtime-governed dependencies. youaskm3 must consume those public surfaces and must not hardcode an inference provider in product/business logic.

Acceptance criteria:

- `model_dependencies` or a successor field has a schema.
- Dependencies reference stable interface ids and versions.
- Dependencies can be satisfied by registered capabilities, agents, connectors, or model providers.
- Unsatisfied dependencies fail before user-facing execution begins.
- Resolution result is visible in registration output or execution trace.
- Dependency resolution does not require downstream app code changes when a new implementation is available.

#### TRV-P0-005: Workflow Execution From App-Facing API

The browser/PWA must be able to ask Traverse to execute a downstream workflow through a public app-facing API.

Acceptance criteria:

- UI can discover Traverse base URL through a documented public mechanism.
- UI can submit a runtime request to a workspace.
- UI can receive synchronous or async execution status.
- UI can fetch public trace data.
- Error envelopes are stable and machine-readable.
- No private Traverse filesystem layout is required.

#### TRV-P0-006: MCP Surface for the Same Capabilities

The same downstream capabilities must be available through Traverse MCP.

Acceptance criteria:

- MCP clients can discover the downstream capabilities.
- MCP clients can inspect capability contracts.
- MCP clients can execute the relevant entrypoints.
- MCP clients can render or fetch execution reports/traces.
- MCP behavior is backed by the same registered capabilities, not a separate implementation.

#### TRV-P0-007: Trace Evidence for Grounded Answers

Traverse traces must provide enough public evidence for a UI and an auditor to understand how an answer was produced.

Minimum trace evidence:

- workflow id and version
- capability ids and versions executed
- placement target chosen for each capability
- dependency/model capability selected
- source artifact ids used
- graph nodes/edges included in context
- citation ids returned
- validation outcome
- failure reason if validation fails

Acceptance criteria:

- UI can show a useful "why this answer" view from public trace data.
- Private sensitive inputs are not leaked into public traces.
- Public traces are stable enough for downstream tests.

#### TRV-P0-008: Deterministic Failure Modes

The downstream app must be able to distinguish setup failure, dependency failure, execution failure, validation failure, and user-input failure.

Acceptance criteria:

- Missing model dependency has a stable error code.
- Missing artifact bundle has a stable error code.
- Invalid capability input has a stable error code.
- Unsupported placement has a stable error code.
- WASM execution failure has a stable error code.
- Trace lookup failure has a stable error code.

### P1 - Strongly Required for MVP Quality

#### TRV-P1-001: Application Manifest Contract

Traverse should support a first-class application manifest that declares the downstream app's runtime needs.

The manifest should describe:

- application id
- workspace defaults
- required bundles
- required capabilities
- required workflows
- required MCP tools
- required model interfaces
- preferred placement policy
- public app endpoint assumptions

Acceptance criteria:

- Manifest can be validated before runtime startup.
- Manifest can be cited by downstream app docs.
- Manifest can be used by CI/conformance tests.

#### TRV-P1-002: Capability Interface Versioning

Traverse must allow the downstream app to depend on stable capability interfaces while implementations evolve.

Acceptance criteria:

- Downstream app can request an interface/version or semver range.
- Traverse resolves an implementation.
- Breaking changes require explicit version movement.
- Trace records resolved implementation.

#### TRV-P1-003: Evented Capability Coordination

The downstream workflow needs to coordinate several steps without hiding sequencing in UI code.

Example capability sequence:

- receive question
- retrieve candidate sources
- expand graph context
- pack context
- run inference
- validate answer grounding
- format response

Acceptance criteria:

- Workflow steps can be modeled as direct or event-triggered edges.
- Event contracts can be registered with the bundle.
- Event publication is validated against contracts.
- Event-related failures are traceable.

#### TRV-P1-004: Browser/PWA Consumption Without Private Internals

The PWA must consume Traverse through public browser-safe surfaces.

Acceptance criteria:

- Browser/PWA can connect to local Traverse without importing private Traverse source.
- Browser/PWA can subscribe to execution progress or poll status.
- Browser/PWA can fetch public traces.
- Browser adapter behavior is documented and tested.
- CORS/local dev behavior is explicit.

#### TRV-P1-005: Local-First Operation

The first MVP must work without paid external services.

Acceptance criteria:

- A local Traverse execution path exists.
- Missing server/cloud capability does not block local execution if a local compatible capability is installed.
- Local execution path is documented.
- The downstream app can state honestly whether the current setup is local-only, server-enabled, or mixed.

#### TRV-P1-006: Placement Policy Visibility

Traverse owns placement, but the downstream app needs visibility into the decision.

Acceptance criteria:

- Trace includes requested target, selected target, reason, and confidence.
- If placement changes from local to server or server to local, the trace explains why.
- Downstream app can display placement status without understanding Traverse internals.

### P2 - Needed Soon After MVP

#### TRV-P2-001: Server/Local Capability Equivalence

Traverse should support the same capability contract running locally or on a server.

Acceptance criteria:

- Same workflow can run with local or server implementation.
- Downstream app code does not change when placement changes.
- Traces identify selected implementation and target.

#### TRV-P2-002: Capability/Model Benchmark Evidence

For model-heavy workflows, Traverse should expose enough benchmark or runtime performance evidence to support placement heuristics.

Acceptance criteria:

- Runtime snapshot can include model/capability latency or load.
- Placement reasons can cite heuristic inputs.
- Downstream app can avoid making its own model routing logic.

#### TRV-P2-003: Connector or Dependency Path for Large Local Assets

Some inference or graph capabilities may need large local artifacts such as model weights or indexes.

Acceptance criteria:

- Large artifacts are referenced by governed manifest fields.
- Digests are verified.
- Runtime can fail clearly when artifacts are missing.
- Artifact access remains explicit and portable.

#### TRV-P2-004: Better Distribution Than Source-Build Only

Source-build is acceptable for early MVP validation, but not ideal for ordinary users.

Acceptance criteria:

- Traverse publishes installable or cacheable runtime artifacts.
- Downstream app can pin a version without requiring users to build all of Traverse manually.
- Supply-chain evidence remains available.

## Downstream Capability Set Needed

The downstream app expects to register capabilities similar to the following. Names are illustrative; Traverse does not need to know product details.

### `knowledge.query.answer`

Purpose: top-level chat/question workflow entrypoint.

Input:

- user question
- optional conversation context
- workspace/instance id
- optional user-selected source filters

Output:

- answer text
- citations
- source ids
- graph evidence
- validation status
- trace reference

### `knowledge.retrieve`

Purpose: retrieve candidate source chunks from local artifacts.

Business logic:

- parse query
- rank chunks
- return source-aware candidates

### `knowledge.graph.expand`

Purpose: expand context using graph nodes and edges.

Business logic:

- identify relevant nodes
- follow bounded graph paths
- return explainable graph context

### `knowledge.context.pack`

Purpose: create a bounded context package for model inference.

Business logic:

- deduplicate sources
- fit token/context limits
- preserve citation ids
- include graph hints

### `knowledge.infer`

Purpose: invoke a governed inference capability.

Business logic:

- call/compose with the resolved model capability
- enforce prompt/input contract
- return structured model output

### `knowledge.answer.validate`

Purpose: verify answer grounding.

Business logic:

- ensure cited claims map to sources
- identify unsupported claims
- return pass/warn/fail result

### `knowledge.answer.format`

Purpose: produce final UI/MCP-ready response.

Business logic:

- final answer text
- citations
- graph summary
- failure warnings
- trace summary

## Required Public APIs

The downstream app needs stable public APIs for:

- starting or discovering a local Traverse runtime
- registering app bundles
- registering capabilities
- registering events
- registering workflows
- executing a workflow/capability
- fetching execution status
- fetching public traces
- discovering MCP tools
- executing MCP entrypoints

Traverse `v0.4.0` covers the required public API baseline through application manifests, WASM component manifests, atomic registration, governed model dependency resolution, HTTP/JSON trace paths, MCP reporting, and downstream MVP conformance evidence.

## Required Validation Evidence

Traverse should provide or extend validation scripts that prove:

1. A downstream bundle can be registered from a clean checkout.
2. A WASM capability can be executed through the HTTP/JSON app path.
3. The same capability can be discovered or exercised through MCP.
4. A workflow with multiple capabilities can execute and produce a public trace.
5. A model dependency can be declared, resolved, selected, and traced.
6. Failure to satisfy a model dependency fails deterministically.
7. Browser/PWA consumption works without private Traverse internals.
8. The conformance suite can run from a pinned release tag.

Required Traverse validation command:

```bash
bash scripts/ci/downstream_app_mvp_conformance.sh
```

Downstream readiness wrapper:

```bash
bash scripts/traverse-readiness.sh
```

The wrapper looks for a local Traverse checkout at `../Traverse` by default. Use `TRAVERSE_REPO=/path/to/Traverse` or `TRAVERSE_CHECKOUT=/path/to/Traverse` when the checkout is elsewhere. It verifies that the checkout contains the `v0.4.0` baseline, reports the active tag and commit, delegates to Traverse's public downstream conformance script, and summarizes the capability areas instead of printing full passing logs:

```text
Traverse readiness passed.
Capability areas:
- application bundle registration: passed
- WASM workflow execution: passed
- model dependency resolution: passed
- HTTP/JSON app path: passed
- MCP parity path: passed
- live local model conformance: optional skipped
```

Optional live local model conformance:

```bash
TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1 bash scripts/traverse-readiness.sh
```

Normal repository smoke does not require Traverse to be installed. Run `scripts/traverse-readiness.sh` when validating the Traverse pairing for integration work, release evidence, or a ticket that touches the Traverse runtime boundary.

## Non-Goals for Traverse

Traverse does not need to own:

- file conversion from PDF/DOCX/PPTX/etc. to raw markdown
- product UI layout
- product-specific visual design
- source content authoring
- downstream product release notes
- downstream app smoke tests beyond public-surface compatibility
- Graphy adoption decisions
- MarkItDown adoption decisions

Traverse should only care about these external tools if the downstream app wraps their outputs into governed capabilities or artifacts.

## Open Questions for Traverse

1. What additional evidence should Traverse expose before youaskm3 can claim the model engine itself is WASM-native?
2. How should large model weights or local indexes be referenced, digested, and placed after the first MVP?
3. What trace fields are safe for public UI display when inference and private source data are involved?

## Recommended Traverse Work Order

1. Pin youaskm3 specs and docs to Traverse `v0.4.0`.
2. Create the youaskm3 application bundle skeleton using v0.4.0 manifest fields.
3. Add a youaskm3 readiness check that delegates to `downstream_app_mvp_conformance.sh`.
4. Implement the MVP WASM capabilities and component manifests.
5. Register the youaskm3 app bundle through Traverse public APIs.
6. Wire the PWA and MCP paths to the same registered workflow.
7. Add optional live local model conformance after the default no-paid-service path is stable.

## MVP Readiness Definition

Traverse is ready for this downstream MVP when the downstream app can honestly say:

> The UI sends a user request to Traverse. Traverse executes all product/business behavior as governed WASM capabilities, resolves the needed inference capability, selects placement, records a trace, and exposes the same behavior through HTTP/JSON and MCP. The downstream app does not contain alternate business logic paths.

## Summary

Traverse already has a strong foundation for the first integration:

- application bundle manifests
- WASM component manifests
- atomic app bundle registration
- governed model dependency resolution
- public HTTP/JSON app path
- public MCP path
- WASM execution
- programmatic registration
- trace evidence
- downstream app MVP conformance evidence

The critical missing piece has moved to the downstream app: youaskm3 must now build and register its own Traverse v0.4.0 application bundle, implement the MVP WASM capabilities, wire the PWA/MCP paths to the registered workflow, and document the local inference caveat clearly.

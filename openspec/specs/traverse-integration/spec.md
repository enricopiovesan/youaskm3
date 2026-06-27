# traverse-integration Specification

## Purpose

The traverse-integration capability defines how youaskm3 hands product/business execution to Traverse while keeping the PWA as a UI-only application and the CLI as an artifact builder and bundle registrar. MVP runtime acceptance requires real WASM microservice capabilities for deterministic business logic and real WASM agent capabilities for judgement, generation, planning, or model-use behavior.

## Requirements

### Requirement: Register an application bundle through public Traverse surfaces

The system SHALL register the youaskm3 application bundle through documented Traverse public APIs, including capability contracts, event contracts, workflow definitions, WASM package manifests, binary digests, runtime constraints, permitted targets, and model dependency declarations.

For MVP-031 onward, the minimum approved Traverse baseline is `v0.5.0`. Local development setup SHALL validate bundles through `traverse-cli app validate --manifest <path> --json` and register them into a workspace through `traverse-cli app register --manifest <path> --workspace <workspace-id> --json`.

#### Scenario: Register the MVP bundle

- GIVEN the CLI has built the MVP artifact and WASM package set
- WHEN it registers the application with Traverse
- THEN Traverse returns machine-readable bundle ids, versions, digests, and validation status without relying on private Traverse internals

#### Scenario: Validate and register through the Traverse v0.5.0 CLI

- GIVEN the CLI has built the youaskm3 Traverse application bundle
- WHEN local development setup validates and registers the bundle
- THEN it uses Traverse `v0.5.0` or newer public CLI app validation and local workspace registration commands
- AND the setup path does not depend on private Traverse internals or downstream runtime shortcuts

### Requirement: Execute the chat workflow through real Traverse capabilities

The system SHALL execute the first user-facing chat workflow through Traverse using real registered WASM microservice capabilities or real WASM agent capabilities. Temporary harnesses, contract stubs, fake workflow steps, placeholder component manifests, and Browser demo paths SHALL NOT satisfy MVP runtime acceptance.

#### Scenario: Answer a user prompt

- GIVEN a user submits a prompt in the PWA
- WHEN the runtime workflow starts
- THEN the workflow composes retrieval, graph expansion, context packing, inference, validation, and formatting capabilities behind the Traverse boundary
- AND each product/business step is a real registered WASM microservice or WASM agent capability

#### Scenario: Prove the local Traverse-backed happy path

- GIVEN a local Traverse runtime is available for the youaskm3 app bundle
- WHEN the PWA sends a `knowledge.query.answer` request through the configured Traverse HTTP/JSON endpoint
- THEN the response includes answer text, source evidence, graph evidence, validation status, and a trace reference
- AND the PWA does not execute hidden product/business logic outside the Traverse boundary

#### Scenario: Report unavailable Traverse without hidden fallback

- GIVEN Traverse local is selected as the runtime provider
- AND the configured Traverse endpoint is unavailable
- WHEN the user asks a question
- THEN the UI reports a stable Traverse runtime failure
- AND the selected provider remains Traverse local
- AND Browser demo execution does not run unless the user explicitly selects it

### Requirement: Delegate inference selection and placement

The system SHALL declare inference needs by contract and allow Traverse to choose a compatible local or server-side implementation based on availability, constraints, and placement policy.

#### Scenario: Use a local inference capability when available

- GIVEN a compatible local WASM inference capability is registered
- WHEN the answer workflow requires inference
- THEN Traverse may place the inference step locally and records the selected capability in the trace

### Requirement: Return public evidence traces

The system SHALL expose enough trace evidence for the UI, MCP clients, and auditors to understand how a grounded answer was produced.

#### Scenario: Inspect a completed answer trace

- GIVEN an answer workflow completed or failed validation
- WHEN a client fetches the public trace reference
- THEN the trace includes executed capability ids, versions, placement, source artifacts, graph evidence, inference dependency, validation outcome, and failure reasons where applicable

### Requirement: Generate real component evidence for implemented WASM capabilities

The system SHALL generate real WASM artifacts and component manifest digests for every MVP capability before that capability can satisfy runtime acceptance.

#### Scenario: Build implemented capability artifacts

- GIVEN the MVP capability crates build for `wasm32-wasip1`
- WHEN the Traverse bundle manifest generator runs without skeleton mode
- THEN each MVP component references a real `.wasm` artifact or a real WASM agent artifact
- AND each MVP component manifest includes a real SHA-256 digest
- AND placeholder digests, skeleton status, and pending implementation markers fail MVP acceptance

### Requirement: Treat inference as a real WASM agent capability

The system SHALL implement `knowledge.infer` as a real Traverse-governed WASM agent capability when the workflow needs judgement, generation, planning, semantic interpretation, or model use.

#### Scenario: Execute inference through a governed agent

- GIVEN the answer workflow needs to generate an answer from packed context
- WHEN Traverse executes `knowledge.infer`
- THEN Traverse invokes a real registered WASM agent capability
- AND model dependency selection, placement, success, or failure is captured in governed trace evidence
- AND deterministic microservice logic is not used as a fake replacement for the agent behavior

#### Scenario: Reject recording-only inference as MVP acceptance

- GIVEN `knowledge.infer` receives a packed context and a Traverse-selected inference dependency
- WHEN the first-MVP workflow requires generated answer text
- THEN the capability performs real agent execution through Traverse-governed WASM agent behavior
- AND a crate that only records pre-generated model output does not satisfy MVP acceptance

### Requirement: Prove final first-MVP acceptance end to end

The system SHALL provide a final first-MVP acceptance gate that proves the complete local-first product path without Browser demo, placeholder manifests, contract stubs, fake workflow steps, or downstream runtime shortcuts.

#### Scenario: Complete the first-MVP release gate

- GIVEN a clean checkout with required local tools and a Traverse v0.5.0-or-newer runtime
- WHEN the final MVP acceptance gate runs
- THEN the CLI prepares artifacts, builds real WASM microservices and WASM agents, validates/registers the app bundle through public Traverse surfaces, asks an imported-document question through the PWA path, and verifies answer text, citations, graph evidence, validation status, trace evidence, and MCP parity
- AND every failed prerequisite is reported as setup, downstream implementation, or Traverse blocker evidence

### Requirement: Escalate confirmed Traverse blockers upstream

The system SHALL capture confirmed missing Traverse public surfaces as upstream Traverse requirements instead of adding downstream runtime shortcuts.

#### Scenario: Open a Traverse blocker from youaskm3 evidence

- GIVEN a youaskm3 ticket cannot satisfy its DoD through existing Traverse public surfaces
- WHEN a focused validation command demonstrates the blocker
- THEN the blocked youaskm3 issue links to a Traverse requirement or issue with affected capability, expected public surface, observed failure, Traverse version, and reproduction evidence
- AND youaskm3 does not add non-portable downstream provider, placement, or runtime logic to hide the blocker

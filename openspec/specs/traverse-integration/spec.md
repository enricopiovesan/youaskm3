# traverse-integration Specification

## Purpose

The traverse-integration capability defines how youaskm3 hands product/business execution to Traverse while keeping the PWA as a UI-only application and the CLI as an artifact builder and bundle registrar.

## Requirements

### Requirement: Register an application bundle through public Traverse surfaces

The system SHALL register the youaskm3 application bundle through documented Traverse public APIs, including capability contracts, event contracts, workflow definitions, WASM package manifests, binary digests, runtime constraints, permitted targets, and model dependency declarations.

#### Scenario: Register the MVP bundle

- GIVEN the CLI has built the MVP artifact and WASM package set
- WHEN it registers the application with Traverse
- THEN Traverse returns machine-readable bundle ids, versions, digests, and validation status without relying on private Traverse internals

### Requirement: Execute the chat workflow through Traverse

The system SHALL execute the first user-facing chat workflow through Traverse or a temporary harness that exactly mirrors the Traverse request and response contract.

#### Scenario: Answer a user prompt

- GIVEN a user submits a prompt in the PWA
- WHEN the runtime workflow starts
- THEN the workflow composes retrieval, graph expansion, context packing, inference, validation, and formatting capabilities behind the Traverse boundary

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

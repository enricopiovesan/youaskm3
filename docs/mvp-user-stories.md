# First MVP User Stories

Status: First-MVP acceptance guide
Owner: youaskm3 product/spec alignment
Last updated: 2026-06-25

## Purpose

This document names the first-MVP personas and user-facing stories that guide specs, tickets, tests, and demos.

The first MVP is a local-first PWA chat experience over user-owned knowledge artifacts. The CLI prepares markdown, search, graph, and bundle artifacts. Traverse executes product/business behavior as governed portable WASM capabilities or agents. The UI renders the experience and must not contain alternate retrieval, graph traversal, context packing, inference selection, answer validation, or answer formatting logic.

## MVP Boundary

### In The First MVP

- Local source files can be converted or normalized into markdown artifacts.
- Static search and graph artifacts can be generated from the local knowledge folder.
- A browser/PWA chat surface can ask a question and display an answer with source and graph evidence.
- Runtime product/business behavior is represented by explicit capability contracts and routed through Traverse-compatible boundaries.
- Traverse readiness, bundle manifests, component manifests, model dependency readiness, HTTP/JSON, and MCP paths have traceable validation evidence.

### Post-MVP

- Federation discovery beyond a local or checked-in registry fixture.
- Hosted accounts, hosted databases, billing, teams, permissions, or enterprise administration.
- Cross-instance search fan-out as a required path.
- Production-quality hosted model service.
- Claims that the local model engine itself is WASM-native before Traverse exposes that evidence.

## Personas And Stories

### Local-First Knowledge Owner

As a local-first knowledge owner, I want to ask questions against my own markdown-backed knowledge folder, so that I can get useful answers without sending my documents to a mandatory hosted service.

Capability and ticket map:

- `knowledge.query.answer`
- `knowledge.retrieve`
- `knowledge.graph.expand`
- `knowledge.context.pack`
- `knowledge.answer.validate`
- `knowledge.answer.format`
- MVP-011 Traverse readiness check
- MVP-019 PWA chat adapter to Traverse HTTP/JSON
- MVP-026 `knowledge.query.answer` workflow entry point
- MVP-028 end-to-end Traverse answer workflow smoke
- MVP-031 local Traverse-backed chat happy path
- MVP-033 real imported-document question acceptance test
- MVP-034 explicit Browser demo fallback semantics

Acceptance criteria:

- GIVEN a local knowledge corpus with generated search and graph artifacts
- WHEN the user asks a question in the PWA chat
- THEN the UI receives a structured answer through the Traverse boundary
- AND the answer includes citations or source references from local artifacts
- AND the UI does not run hidden retrieval, ranking, context packing, inference selection, validation, or formatting logic
- AND Browser demo is used only when explicitly selected as a fallback provider

### Fork-And-Run Developer

As a fork-and-run developer, I want to clone the repo, build the artifacts, validate Traverse readiness, and serve the PWA locally, so that I can run my own instance without a database or hosted backend.

Capability and ticket map:

- `scripts/smoke.sh`
- `scripts/traverse-readiness.sh`
- `scripts/traverse-component-manifests.sh`
- `traverse/youaskm3-app/manifest.json`
- MVP-010 Traverse application bundle skeleton
- MVP-011 Traverse readiness check
- MVP-027 component manifests and binary digests
- MVP-032 real WASM artifacts and component digests

Acceptance criteria:

- GIVEN a fresh checkout with required local tools installed
- WHEN the developer runs the documented smoke and Traverse readiness commands
- THEN the repo reports pass/fail status with actionable setup messages
- AND normal smoke does not require Traverse to be installed
- AND Traverse-specific validation is available when a local Traverse checkout is configured
- AND implemented capability manifests use real WASM digests rather than skeleton placeholders where artifacts exist

### Source-Grounded Researcher

As a source-grounded researcher, I want every answer to show which documents, chunks, and graph context supported it, so that I can audit the response before trusting or reusing it.

Capability and ticket map:

- `knowledge.retrieve`
- `knowledge.graph.expand`
- `knowledge.context.pack`
- `knowledge.answer.validate`
- `knowledge.answer.format`
- MVP-014 source/citation validation logic
- MVP-020 Traverse MCP parity smoke
- MVP-023 `knowledge.graph.expand`
- MVP-024 `knowledge.context.pack`
- MVP-025 `knowledge.answer.format`
- MVP-033 real imported-document question acceptance test

Acceptance criteria:

- GIVEN a generated knowledge artifact index and graph artifact
- WHEN an answer is produced
- THEN source ids, source paths, chunk ids, and graph/context evidence are available in the response or trace
- AND unsupported answer claims fail validation or are marked as failures
- AND the same grounding evidence can be inspected through the PWA and MCP-facing paths when those paths are enabled
- AND at least one acceptance test starts from an imported or normalized fixture document rather than only prebuilt static artifacts

### Privacy-Conscious Professional

As a privacy-conscious professional, I want model and runtime choices to be delegated through Traverse placement and dependency policies, so that local execution can be preferred without hardcoding one provider in downstream app logic.

Capability and ticket map:

- `knowledge.infer`
- Traverse `model_dependencies`
- `scripts/traverse-readiness.sh`
- MVP-021 local inference readiness policy
- MVP-030 `knowledge.infer` dependency failure and evidence tests
- MVP-034 explicit Browser demo fallback semantics

Acceptance criteria:

- GIVEN a Traverse app manifest declaring inference needs
- WHEN Traverse resolves runtime dependencies
- THEN selected and rejected model candidates are visible as governed evidence
- AND no downstream UI or CLI code hardcodes Ollama, WebLLM, llama.cpp, cloud APIs, or a fallback provider
- AND missing local inference capability fails clearly before or during governed execution
- AND Traverse runtime failures remain visible instead of automatically switching to Browser demo

### MCP And Agent User

As an MCP and agent user, I want the same knowledge capabilities exposed through Traverse MCP, so that agents can query my knowledge through the same governed workflow as the browser.

Capability and ticket map:

- `knowledge.query.answer`
- `knowledge.retrieve`
- `knowledge.graph.expand`
- `knowledge.context.pack`
- `knowledge.answer.validate`
- `knowledge.answer.format`
- MVP-020 Traverse MCP parity smoke
- MVP-028 end-to-end Traverse answer workflow smoke
- MVP-031 local Traverse-backed chat happy path

Acceptance criteria:

- GIVEN the app bundle is registered through Traverse
- WHEN an MCP client discovers or invokes the answer workflow
- THEN the capability contracts and execution evidence match the app-facing workflow
- AND MCP does not use a separate implementation path for retrieval, graph context, validation, or formatting
- AND the app-facing and MCP-facing paths expose equivalent grounding and trace evidence for the same workflow

### Product Maintainer Validating Traverse Integration

As a product maintainer validating Traverse integration, I want each MVP runtime claim backed by a ticket, spec, manifest, script, or CI check, so that we can tell Traverse when a required public surface is missing or when youaskm3 is ready to consume it.

Capability and ticket map:

- `openspec/specs/traverse-integration/spec.md`
- `docs/traverse-mvp-requirements.md`
- `scripts/traverse-readiness.sh`
- `scripts/traverse-component-manifests.sh`
- MVP-018 bundle registration
- MVP-020 MCP parity smoke
- MVP-028 end-to-end Traverse answer workflow smoke
- MVP-035 Traverse blocker escalation template

Acceptance criteria:

- GIVEN a first-MVP readiness review
- WHEN the maintainer checks the repo
- THEN runtime claims cite a spec, contract, manifest, ticket, or validation script
- AND readiness commands summarize pass/fail by capability area instead of requiring large log inspection
- AND remaining gaps are represented as backlog tickets rather than undocumented assumptions
- AND confirmed missing Traverse public surfaces are escalated upstream with reproduction evidence instead of hidden in downstream workaround code

## Demo Acceptance Path

The first MVP demo is acceptable when these steps pass from a clean local setup:

1. Prepare or refresh markdown, search, and graph artifacts from local knowledge files.
2. Validate normal repo health with `bash scripts/smoke.sh`.
3. Validate Traverse pairing with `bash scripts/traverse-readiness.sh` when a local Traverse checkout is available.
4. Generate or check component manifests with real WASM digests for implemented capabilities; use skeleton mode only for capabilities that genuinely do not have artifacts yet.
5. Register the youaskm3 app bundle through Traverse public APIs.
6. Ask one question through the PWA.
7. Inspect answer text, citations, graph/source evidence, selected inference dependency, and trace.
8. Exercise the same answer workflow through MCP parity validation.
9. Explicitly select Browser demo only when validating the documented no-server fallback path.

The demo must not require a hosted account, hosted database, paid external model service, or product/business logic outside Traverse-governed capabilities.

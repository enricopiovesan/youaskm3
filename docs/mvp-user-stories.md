# First MVP User Stories

Status: First-MVP acceptance guide
Owner: youaskm3 product/spec alignment
Last updated: 2026-06-29

## Purpose

This document names the first-MVP personas and user-facing stories that guide specs, tickets, tests, and demos.

The first MVP is a local-first second-brain chat experience over user-owned knowledge artifacts and structured reasoning logs. The CLI prepares markdown, decision-log packages, search, graph, sync, and bundle artifacts. Traverse executes product/business behavior as governed portable WASM microservice capabilities or WASM agent capabilities. The UI renders the chat experience and must not contain alternate retrieval, graph traversal, context packing, inference selection, answer validation, response formatting, gap lifecycle, sync conflict policy, or reasoning graph extraction logic.

The expanded product goal is a reasoning-and-knowledge-cementing loop. A persona uses a ChatGPT/Claude-style skill to reason through concepts in natural conversation, challenge assumptions, clarify ambiguity, and produce a decision-log package. youaskm3 ingests that package, updates personal knowledge and the graph, and later answers open questions from that cemented reasoning. When information is unavailable, uncertain, or conflicting, the system defers to the human and records a knowledge gap instead of guessing.

MVP runtime acceptance requires the real implementation. Browser demo, temporary harnesses, contract stubs, fake workflow steps, skeleton manifests, placeholder digests, and all-zero component evidence are developer aids only and do not count as acceptance evidence.

## MVP Boundary

### In The First MVP

- Local source files can be converted or normalized into markdown artifacts.
- A persona can create a decision-log package through an LLM-agnostic assistant skill generated for ChatGPT and Claude.
- The CLI can ingest decision-log package directories, validate them, preserve provenance, and update knowledge.
- Full reasoning graph extraction captures concepts, questions, options, tradeoffs, assumptions, decisions, claims, gaps, citations, confidence, and validation evidence.
- Unsupported, uncertain, or conflicting answers create or update knowledge gaps.
- Simple factual gaps can be resolved in chat through internal mini packages; reasoning-heavy gaps require decision-log packages.
- File-system sync-folder usage is supported with conflict detection and safe append-only merge behavior.
- A local server powers chat and MCP runtime through the same Traverse-backed workflow.
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
- Hosted youaskm3 sync service, user accounts, or cloud storage control plane.
- Zip/archive decision-log package ingestion.
- Automatic inbox watcher for decision-log packages.
- Claim-level partial ingestion after failed semantic validation.

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
- AND Browser demo output does not count as MVP runtime acceptance evidence

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
- AND MVP runtime capability manifests use real WASM or WASM agent digests rather than skeleton placeholders
- AND pending markers or all-zero digests block MVP runtime acceptance

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
- MVP-039 real `knowledge.infer` WASM agent

Acceptance criteria:

- GIVEN a Traverse app manifest declaring inference needs
- WHEN Traverse resolves runtime dependencies
- THEN selected and rejected model candidates are visible as governed evidence
- AND no downstream UI or CLI code hardcodes Ollama, WebLLM, llama.cpp, cloud APIs, or a fallback provider
- AND missing local inference capability fails clearly before or during governed execution
- AND Traverse runtime failures remain visible instead of automatically switching to Browser demo
- AND generation, judgement, planning, semantic interpretation, or model-use behavior is handled by a real Traverse-governed WASM agent capability
- AND recording pre-generated model output does not count as real MVP inference

### Reasoning Persona

As a reasoning persona, I want an assistant skill to help me reason through a concept, challenge assumptions, ask one clarifying question at a time, and produce a structured decision-log package, so that my reasoning becomes durable personal knowledge instead of disappearing in chat history.

Capability and ticket map:

- `reasoning-assistant-skill`
- `decision-log-package`
- `reasoning-graph`
- MVP-041 LLM-agnostic reasoning skill generator and adapters
- MVP-042 decision-log package schema and fixtures

Acceptance criteria:

- GIVEN a persona starts a reasoning conversation in a generated ChatGPT or Claude adapter
- WHEN the concept has unresolved ambiguity
- THEN the adapter asks one question at a time with options, pros, cons, and a recommendation when useful
- AND it challenges weak assumptions respectfully
- AND it does not finalize the package while blocking clarifications remain
- AND the resulting package contains `decision-log.md`, `knowledge-note.md`, and `metadata.json`
- AND the generated adapter includes the generic CLI command `m3 ingest-decision-log /path/to/decision-log-package/`

### Second-Brain Knowledge Curator

As a second-brain knowledge curator, I want decision-log packages to be validated, preserved, transformed into notes, and extracted into a reasoning graph, so that future answers can use my actual decisions, assumptions, tradeoffs, and confidence evidence.

Capability and ticket map:

- `decision-log-package`
- `reasoning-graph`
- `knowledge-gap-lifecycle`
- MVP-043 CLI decision-log package ingestion
- MVP-044 reasoning graph schema and extraction
- MVP-045 knowledge gap and conflict lifecycle

Acceptance criteria:

- GIVEN a valid decision-log package directory
- WHEN `m3 ingest-decision-log /path/to/package/` runs with Traverse available
- THEN deterministic validation passes
- AND the package is copied into `knowledge/sources/decision-logs/<package-id>/`
- AND original import path provenance is recorded
- AND `knowledge-note.md` is validated against `decision-log.md`
- AND a normalized knowledge note is available in the knowledge store
- AND the reasoning graph contains required nodes and edges for concepts, questions, options, tradeoffs, assumptions, decisions, claims, gaps, citations, confidence, source artifacts, and validation results

### Human-In-The-Loop Teacher

As a human-in-the-loop teacher, I want youaskm3 to ask me when knowledge is missing, uncertain, or conflicting, so that the second brain improves instead of hallucinating.

Capability and ticket map:

- `knowledge-gap-lifecycle`
- `reasoning-graph`
- `knowledge.query.answer`
- MVP-045 knowledge gap and conflict lifecycle
- MVP-046 graph-aware answer classification and context selection
- MVP-047 direct chat fact resolution
- MVP-052 chat-only gap and evidence UX

Acceptance criteria:

- GIVEN the user asks a question unsupported by current knowledge
- WHEN the answer workflow cannot produce a grounded answer
- THEN the chat defers instead of guessing
- AND a structured gap is created or updated
- AND simple factual gaps can be resolved directly in chat
- AND direct chat resolutions create internal mini decision-log packages
- AND reasoning-heavy gaps require an external decision-log package
- AND conflicting knowledge is summarized with evidence and creates or updates a conflict/gap record

### Multi-Device Local User

As a multi-device local user, I want my knowledge root to work in a file-system sync folder with conflict detection, so that I can use the same second brain across machines without a hosted youaskm3 service.

Capability and ticket map:

- `local-runtime-sync`
- `knowledge-gap-lifecycle`
- `reasoning-graph`
- MVP-049 first-run setup and knowledge-root configuration
- MVP-050 sync preflight and conflict detection
- MVP-051 local runtime serve/start-attach

Acceptance criteria:

- GIVEN a knowledge root is inside a file-system sync folder
- WHEN a knowledge-writing command runs
- THEN sync/conflict preflight runs first
- AND safe append-only changes can auto-merge
- AND semantic conflicts stop writes and create structured markdown conflict reports
- AND chat only discloses sync conflicts when they affect the answer or confidence

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
- MVP-048 local HTTP JSON and MCP runtime
- MVP-053 MCP answer/gaps/resolve parity

Acceptance criteria:

- GIVEN the app bundle is registered through Traverse
- WHEN an MCP client discovers or invokes the answer workflow
- THEN the capability contracts and execution evidence match the app-facing workflow
- AND MCP does not use a separate implementation path for retrieval, graph context, validation, or formatting
- AND the app-facing and MCP-facing paths expose equivalent grounding and trace evidence for the same workflow
- AND MCP can list unresolved gaps and resolve simple factual gaps through the same Traverse-backed workflow as chat

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
- MVP-040 final first-MVP acceptance and release gate
- MVP-054 expanded first-MVP acceptance gate

Acceptance criteria:

- GIVEN a first-MVP readiness review
- WHEN the maintainer checks the repo
- THEN runtime claims cite a spec, contract, manifest, ticket, or validation script
- AND readiness commands summarize pass/fail by capability area instead of requiring large log inspection
- AND remaining gaps are represented as backlog tickets rather than undocumented assumptions
- AND confirmed missing Traverse public surfaces are escalated upstream with reproduction evidence instead of hidden in downstream workaround code
- AND first-MVP completion is declared only after the final acceptance gate passes

## Demo Acceptance Path

The expanded first MVP demo is acceptable when these steps pass from a clean local setup:

1. Generate ChatGPT and Claude assistant-skill adapters from the canonical LLM-agnostic skill source and verify no drift.
2. Produce or use a real decision-log package directory containing `decision-log.md`, `knowledge-note.md`, and `metadata.json`.
3. Run `m3 init --knowledge-root <path> --traverse-repo <path>` or an equivalent configured setup.
4. Run `m3 ingest-decision-log /path/to/decision-log-package/`.
5. Prepare or refresh markdown, search, and graph artifacts from local knowledge files and ingested reasoning packages.
6. Validate reasoning graph extraction with required node/edge types and provenance.
7. Validate knowledge gap and conflict lifecycle behavior.
8. Validate sync preflight with a clean state and at least one conflict fixture.
9. Start local runtime with `m3 serve`, which starts or attaches to Traverse or fails with clear setup guidance.
10. Ask one supported question through the PWA.
11. Ask one unsupported or uncertain question through the PWA and verify gap creation/update.
12. Resolve one simple factual gap through chat and verify an internal mini package is produced.
13. Inspect answer text, concise provenance type, citations, graph/source evidence, selected inference dependency, and trace.
14. Exercise the same answer, gap list, and simple fact resolution workflow through MCP parity validation.
15. Run `m3 mvp-check --traverse-repo <path> --knowledge-root <path>` and record exact remaining caveats.

The earlier Traverse-backed runtime baseline remains valid when these steps pass:

1. Prepare or refresh markdown, search, and graph artifacts from local knowledge files.
2. Validate normal repo health with `bash scripts/smoke.sh`.
3. Validate Traverse pairing with `bash scripts/traverse-readiness.sh` when a local Traverse checkout is available.
4. Generate or check component manifests with real WASM or WASM agent digests for every MVP runtime capability; skeleton mode is not acceptable for MVP runtime acceptance.
5. Register the youaskm3 app bundle through Traverse public APIs.
6. Ask one question through the PWA.
7. Inspect answer text, citations, graph/source evidence, selected inference dependency, and trace.
8. Exercise the same answer workflow through MCP parity validation.
9. Explicitly select Browser demo only when validating the documented no-server fallback path.
10. Treat any missing real Traverse workflow/capability support as a blocked youaskm3 ticket plus an upstream Traverse requirement, not as permission to add placeholders.
11. Run the baseline first-MVP acceptance/release gate and record exact remaining caveats.

The demo must not require a hosted account, hosted database, paid external model service, or product/business logic outside Traverse-governed capabilities.

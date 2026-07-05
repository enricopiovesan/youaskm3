# youaskm3 MVP Ticket Backlog

Status: Draft implementation backlog
Last updated: 2026-06-25

## Goal

This backlog breaks the first youaskm3 MVP into independent tickets that can be picked up by separate contributors or agents.

The MVP target is:

> A local-first PWA chat experience that answers from user-owned knowledge artifacts, with source attribution and graph context, while preparing the product to hand runtime business logic to Traverse as governed WASM capabilities.

## Operating Rules

- Each ticket must be independently understandable.
- Each ticket must include a clear definition of done.
- Each ticket must keep `bash scripts/smoke.sh` green.
- MVP runtime/product business logic must run through Traverse as real WASM microservice capabilities or real WASM agent capabilities.
- Temporary harnesses, Browser demo, skeleton manifests, contract stubs, placeholder digests, and fake workflow steps are developer aids only; they never count as MVP acceptance evidence.
- The CLI may own mechanical build/setup tasks.
- The PWA may own rendering and interaction only.

## Ticket MVP-001: Rewrite Roadmap Around the New MVP

### Objective

Update the public roadmap so it reflects the new product and architecture decisions:

- MarkItDown is the default conversion layer.
- The first MVP includes graph-backed chat.
- The PWA chat is the user-facing product.
- Traverse owns runtime/business capability execution.
- youaskm3 owns artifact preparation and product contracts.

### Scope

Update:

- `README.md`
- `SPEC.md`
- relevant `openspec/specs/*/spec.md` files if they conflict with the new direction

### Out of Scope

- Implementing graph generation
- Implementing Traverse integration
- Changing command behavior

### Definition of Done

- README roadmap matches the new milestone sequence.
- SPEC milestones no longer describe stale M0-M5 assumptions as the current plan.
- The first MVP is explicitly described as local-first PWA chat backed by markdown, graph, search, and Traverse-run capabilities.
- The document distinguishes build-time CLI responsibilities from Traverse runtime responsibilities.
- All changed docs are internally consistent.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-002: Define MVP Capability Contracts

### Objective

Create product-level contracts for the first chat workflow capabilities.

These contracts are the target interface for Traverse and for any temporary local harness.

### Required Capabilities

- `knowledge.query.answer`
- `knowledge.retrieve`
- `knowledge.graph.expand`
- `knowledge.context.pack`
- `knowledge.infer`
- `knowledge.answer.validate`
- `knowledge.answer.format`

### Scope

Add contract files under a clear repo path, for example:

- `contracts/capabilities/knowledge.query.answer.json`
- `contracts/capabilities/knowledge.retrieve.json`
- `contracts/capabilities/knowledge.graph.expand.json`
- `contracts/capabilities/knowledge.context.pack.json`
- `contracts/capabilities/knowledge.infer.json`
- `contracts/capabilities/knowledge.answer.validate.json`
- `contracts/capabilities/knowledge.answer.format.json`

Each contract must include:

- stable id
- version
- purpose
- input schema
- output schema
- source/citation fields where relevant
- trace/evidence fields where relevant
- explicit notes about Traverse execution expectations

### Out of Scope

- Implementing the capabilities
- Registering them with Traverse
- Selecting a real LLM/model

### Definition of Done

- All seven contracts exist.
- Each contract has a JSON schema for inputs and outputs.
- Contracts are strict enough to prevent arbitrary unstructured blobs.
- Contracts include source attribution requirements where relevant.
- Contracts include graph evidence requirements where relevant.
- Contracts include validation/failure output shapes.
- A new contract smoke test validates that the files are parseable JSON and contain required fields.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
node -e "for (const f of require('fs').readdirSync('contracts/capabilities')) JSON.parse(require('fs').readFileSync('contracts/capabilities/' + f, 'utf8'))"
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-003: Define the Normalized Markdown Artifact Contract

### Objective

Define the canonical markdown format produced after MarkItDown/raw conversion.

The goal is to make every source artifact traceable, chunkable, graph-ready, and indexable.

### Scope

Add documentation and validation for normalized markdown artifacts.

Suggested files:

- `docs/markdown-artifact-contract.md`
- `contracts/markdown-artifact.schema.json`
- smoke test script for sample artifacts

The contract must define:

- required metadata
- source path or URL
- source type
- title
- stable artifact id
- ingestion/conversion tool metadata
- content section requirements
- source attribution rules
- graph extraction hints if applicable

### Out of Scope

- Implementing graph generation
- Implementing semantic cleanup
- Replacing MarkItDown

### Definition of Done

- A clear markdown artifact contract exists.
- At least one sample artifact validates against the contract.
- Existing `markitdown2m3` output either conforms or has a documented follow-up gap.
- Validation is added to smoke or a focused script called by smoke.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-004: Add a Real MVP Fixture Corpus

### Objective

Add a small, real-enough fixture corpus so the product loop can be tested without empty indexes or placeholder sample documents.

### Scope

Create a minimal corpus with:

- one note
- one article-like document
- one paper/book-like document
- metadata/source attribution
- at least three chunks total

Suggested location:

- `knowledge/fixtures/` for source fixtures, or
- `knowledge/books/`, `knowledge/papers/`, `knowledge/blog/` if intended to be part of the visible default instance

### Out of Scope

- Large author corpus ingestion
- Real private/personal content
- Federation

### Definition of Done

- `app/site/search-index.json` generated from the fixture corpus contains at least three documents.
- `m3 search` returns results for at least two fixture queries.
- Fixtures are small enough for repo use.
- Fixtures do not include copyrighted long-form content.
- Smoke or a focused test checks that the search index is non-empty.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
./scripts/m3.sh sync
./scripts/m3.sh search portable
./scripts/m3.sh search architecture
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-005: Define Graph Artifact Contract

### Objective

Define the graph artifact shape before choosing or integrating Graphy.

The graph contract must be owned by youaskm3. Graphy can be evaluated against it later.

### Scope

Add:

- `docs/graph-artifact-contract.md`
- `contracts/knowledge-graph.schema.json`
- sample graph artifact

The graph artifact must support:

- nodes
- edges
- source artifact references
- source chunk references
- labels/types
- confidence or extraction method
- stable ids
- deterministic ordering

### Out of Scope

- Graphy integration
- graph visualization
- graph traversal implementation

### Definition of Done

- Graph artifact schema exists.
- Sample graph artifact validates.
- Contract explains how graph nodes/edges link back to source markdown.
- Contract explains what must be deterministic.
- Contract explains what may be generated heuristically later.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
node -e "JSON.parse(require('fs').readFileSync('contracts/knowledge-graph.schema.json','utf8'))"
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-006: Generate Initial Graph Artifacts from Markdown Fixtures

### Objective

Generate a deterministic first graph artifact from the fixture corpus.

This does not need to be smart. It needs to create valid, source-linked graph data that the UI and Traverse contracts can target.

### Scope

Add a build/sync step that produces:

- `app/site/knowledge-graph.json`

Minimum generation rules:

- one document node per processed markdown artifact
- one chunk/source node per indexed document
- edges from document to chunk/source
- optional topic nodes from headings or metadata

### Out of Scope

- Graphy integration
- semantic entity extraction
- LLM-generated graph extraction
- graph ranking

### Definition of Done

- `m3 sync` generates `app/site/knowledge-graph.json`.
- Graph artifact conforms to `contracts/knowledge-graph.schema.json`.
- Graph references source paths already present in `search-index.json`.
- Graph generation is deterministic.
- Smoke validates that graph artifact exists and is valid.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
./scripts/m3.sh sync
test -f app/site/knowledge-graph.json
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-007: Replace Browser Sample Documents with Artifact Loading

### Objective

Move the PWA away from hardcoded sample documents and toward real generated artifacts.

### Scope

Update browser runtime/component code so it can load:

- `app/site/search-index.json`
- `app/site/knowledge-graph.json` if present
- `app/site/author-instance.json`
- `app/site/provider-config.json`

The UI can still use a temporary local adapter response, but source/result data must come from generated artifacts.

### Out of Scope

- Real Traverse runtime calls
- LLM chat
- graph visualization beyond simple source evidence

### Definition of Done

- No primary user-facing search/result display depends on `SAMPLE_BROWSER_DOCUMENTS`.
- PWA can render at least one real search result from `search-index.json`.
- Missing or empty artifacts produce a clear UI state.
- Tests cover successful artifact loading and empty artifact handling.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
npm test
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-008: Define Temporary Traverse-Compatible Chat Harness

### Objective

Create a strict local test harness that mimics the future Traverse response shape.

This allowed the PWA chat UI to be developed before the Traverse-backed runtime path was ready. After Traverse `v0.4.0`, the harness remains a replaceable development fallback while youaskm3 implements its real bundle, WASM capabilities, and Traverse adapter.

### Scope

Add a harness module that accepts the future `knowledge.query.answer` input and returns the future output shape.

The harness may be deterministic:

- retrieve top matching source entries
- produce a simple templated answer
- include citations
- include graph evidence if available
- include a fake-but-structured trace summary marked as `harness`

### Out of Scope

- Real LLM inference
- Hidden alternative runtime
- Business logic that will remain permanently in TypeScript

### Definition of Done

- Harness input/output matches the capability contract from MVP-002.
- Harness is clearly named and documented as temporary.
- Harness response includes answer, citations, graph evidence, validation status, and trace summary.
- Tests ensure the harness output conforms to the contract.
- UI can call the harness through the same adapter interface intended for Traverse.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
npm test
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-009: Build the First PWA Chat Interaction

### Objective

Turn the PWA shell into an actual chat interface backed by the temporary Traverse-compatible harness.

### Scope

Implement:

- prompt input
- submit action
- answer rendering
- citation rendering
- source cards
- graph evidence summary
- loading state
- error state
- empty corpus state

### Out of Scope

- Real Traverse integration
- real LLM inference
- polished graph explorer
- account/auth

### Definition of Done

- User can type a question.
- User can submit the question.
- UI renders an answer from the harness.
- UI renders citations and source paths.
- UI renders graph evidence when available.
- UI handles no-result and error states.
- Existing PWA install/offline smoke still passes.
- Tests cover the chat rendering states.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
npm test
bash scripts/pwa-shell-smoke.sh
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-010: Create Traverse v0.4.0 Application Bundle Skeleton

### Objective

Create the repo structure and checked-in manifest files for the first youaskm3 Traverse application bundle, aligned to Traverse `v0.4.0` public manifest surfaces.

This is no longer a placeholder for missing Traverse manifest/model features. Traverse `v0.4.0` provides application bundle manifests, WASM component manifests, governed model dependency declarations, atomic registration, and downstream conformance evidence.

### Scope

Add:

- bundle manifest
- capability contract references
- workflow references
- README explaining how it maps to Traverse `v0.4.0`
- model dependency declaration for `knowledge.infer`
- placement policy and permitted target metadata suitable for local-first MVP execution

Suggested path:

- `traverse/youaskm3-app/manifest.json`
- `traverse/youaskm3-app/README.md`
- `traverse/youaskm3-app/workflows/`

### Out of Scope

- Executable WASM capabilities
- real Traverse registration
- live local model/Ollama proof

### Definition of Done

- Bundle skeleton exists.
- Bundle references the capability contracts from MVP-002.
- Manifest names Traverse `v0.4.0` as the minimum tested runtime baseline.
- README explains which fields depend on real WASM binaries from later tickets.
- Manifest includes governed model dependency metadata without hardcoding an inference provider in downstream app logic.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-011: Add Traverse Readiness Check Command

### Objective

Add a youaskm3 command or script that checks whether the local Traverse environment is ready for integration.

### Scope

Add a script such as:

- `scripts/traverse-readiness.sh`

It should check:

- Traverse checkout location is configured or discoverable
- Traverse commit/tag
- Cargo available
- required Traverse conformance script can run
- HTTP app path available
- MCP path available

### Out of Scope

- Installing Traverse
- modifying Traverse
- starting long-running services by default

### Definition of Done

- Readiness script exists.
- It produces clear pass/fail output.
- It does not require private Traverse internals beyond documented scripts.
- It can be skipped in normal smoke if Traverse is not present.
- Documentation explains how to run it.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/traverse-readiness.sh
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-012: Add Product-Level MVP Acceptance Test

### Objective

Add a single smoke test that proves the local MVP loop works without Traverse runtime dependency.

This test validates our side while Traverse works on runtime gaps.

### Scope

Add a script such as:

- `scripts/mvp-local-loop-smoke.sh`

It should:

1. initialize temp instance
2. add/prepare fixture content
3. sync artifacts
4. verify non-empty search index
5. verify graph artifact exists
6. invoke chat harness
7. assert answer includes citations

### Out of Scope

- Real LLM inference
- real Traverse execution
- browser screenshot testing

### Definition of Done

- Script exists and is called by `scripts/smoke.sh`.
- Script uses temp directories and leaves no repo pollution.
- Script fails if search index is empty.
- Script fails if graph artifact is missing.
- Script fails if harness answer has no citations.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/mvp-local-loop-smoke.sh
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-013: Prepare First WASM Capability Implementation

### Objective

Implement the first youaskm3 business capability as Rust that can compile to `wasm32-wasip1`.

Best first candidate:

- `knowledge.retrieve`

Reason:

- deterministic
- no model dependency
- easy to test
- immediately useful for chat and MCP

### Scope

Add Rust code for retrieval capability with:

- contract-shaped input
- contract-shaped output
- source-aware ranked results
- no filesystem access in runtime function
- pure logic callable from tests
- WASM-compatible crate target

### Out of Scope

- Traverse registration
- model inference
- graph traversal

### Definition of Done

- Capability logic exists in Rust.
- Unit tests cover ranking, empty input, no results, and source attribution.
- It builds for native target.
- It builds for `wasm32-wasip1`.
- It can be wrapped later as a Traverse stdin/stdout JSON agent.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
cargo test --locked --workspace
cargo build --locked --workspace --target wasm32-wasip1
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-014: Add Source/Citation Validation Logic

### Objective

Create deterministic answer validation logic that checks whether a response includes source-backed citations.

This will become part of `knowledge.answer.validate`.

### Scope

Implement pure Rust validation logic:

- input answer text
- citation list
- available source ids
- output pass/warn/fail
- missing citation reasons
- unsupported citation reasons

### Out of Scope

- semantic claim verification
- LLM calls
- UI rendering

### Definition of Done

- Validation logic exists in Rust.
- Tests cover valid citations, missing citations, unknown citations, duplicate citations, and empty answer.
- Output matches the contract from MVP-002.
- Builds for `wasm32-wasip1`.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
cargo test --locked --workspace
cargo build --locked --workspace --target wasm32-wasip1
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-015: Document Current Local Development Toolchain

### Objective

Document the toolchain needed to run the full local smoke path.

### Scope

Update developer docs with:

- Rustup requirement
- pinned Rust `1.94.0`
- `wasm32-wasip1` target
- `cargo-llvm-cov`
- Python 3.10+ requirement for MarkItDown
- recommended Python path on this machine
- npm install
- exact smoke command

### Out of Scope

- Installing tools automatically
- CI changes

### Definition of Done

- README or docs page explains setup.
- Exact passing smoke command is documented:

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-031: Prove the Local Traverse-Backed Chat Happy Path

### Objective

Make the primary local demo path use real Traverse workflow composition for `knowledge.query.answer` instead of relying on the explicit browser demo fallback.

This ticket validates the product-led integration loop: the PWA remains UI-only, product/business behavior runs as real Traverse-governed WASM microservices or WASM agents, and missing runtime capability fails visibly instead of silently falling back.

### Scope

Add or update the smallest set of scripts, docs, fixtures, and tests needed to prove:

- a local Traverse HTTP/JSON runtime can be started or targeted for the youaskm3 app workflow
- `knowledge.query.answer` is a Traverse workflow composed from separate real capabilities
- deterministic steps run as real WASM microservice capabilities
- judgement, generation, planning, semantic interpretation, or model-use steps run as real WASM agent capabilities
- the PWA provider configuration points to that runtime as the default local provider
- a local question reaches `knowledge.query.answer` through the Traverse app-facing boundary
- the response includes answer text, citations or source references, graph evidence, validation status, and a trace reference
- unavailable Traverse runtime returns a stable visible failure such as `TRAVERSE_UNAVAILABLE`
- any missing Traverse support is captured as a detailed Traverse requirement and the ticket is marked blocked rather than completed with placeholders

### Out of Scope

- hosted deployment
- production model quality
- adding new model providers in downstream UI or CLI code
- changing Traverse internals except by creating a separate upstream Traverse issue for a confirmed blocker
- removing the explicit browser demo fallback
- accepting Browser demo, temporary harnesses, contract stubs, fake workflow steps, skeleton manifests, or placeholder digests as completion evidence

### Definition of Done

- A documented command starts or targets the local Traverse-backed youaskm3 answer path.
- A focused smoke test verifies a successful Traverse-backed answer when the local Traverse runtime is available.
- The smoke test proves `knowledge.query.answer` executes as a Traverse-composed workflow, not as a monolithic fake capability.
- Each workflow step is backed by a real registered WASM microservice or real registered WASM agent capability.
- `knowledge.infer` is backed by a real WASM agent capability when generation, judgement, planning, semantic interpretation, or model use is required.
- The smoke test verifies that source citations or source references are non-empty.
- The smoke test verifies that graph evidence is non-empty.
- The smoke test verifies that the response includes validation status and a trace reference.
- The smoke test verifies that missing Traverse runtime fails with a stable user-visible error and does not auto-fallback to Browser demo.
- The PWA default local provider remains Traverse-backed.
- Browser demo remains available only as an explicit user-selected fallback.
- Browser demo, temporary harnesses, skeleton manifests, contract stubs, fake workflow steps, and placeholder digests do not satisfy this ticket.
- `docs/mvp-user-stories.md` demo acceptance path references the local Traverse-backed happy path.
- `bash scripts/smoke.sh` passes without requiring a live Traverse runtime.
- A separate live validation command is documented for machines that have Traverse available.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh

TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-readiness.sh

TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-answer-workflow-smoke.sh
```

## Ticket MVP-032: Wire Real WASM Artifacts Into the Traverse Bundle

### Objective

Move the checked-in Traverse app bundle from skeleton confidence to real registration evidence by building every MVP runtime capability artifact and generating real component digests.

### Scope

Update the bundle generation path so every MVP runtime capability can produce real WASM artifacts or real WASM agent artifacts and real SHA-256 digests in:

- `traverse/youaskm3-app/manifest.json`
- `traverse/youaskm3-app/components/*/component.manifest.json`

The MVP acceptance pass must cover every runtime capability required by `knowledge.query.answer`; no required capability may remain pending, skeleton-only, or all-zero-digest.

### Out of Scope

- implementing missing capability business logic
- inference model quality
- hosted artifact publishing
- changing Traverse manifest fields without a confirmed Traverse requirement
- accepting partial bundle evidence for MVP runtime completion

### Definition of Done

- A documented command builds all MVP runtime capability crates or WASM agent artifacts for `wasm32-wasip1`.
- `scripts/traverse-component-manifests.sh` or the equivalent generator runs without `--skeleton` for the MVP runtime bundle.
- Every MVP runtime component manifest contains a real `wasm_digest`, not an all-zero placeholder digest.
- App manifest component entries contain real digests for every MVP runtime capability.
- Pending markers, skeleton status, all-zero digests, and placeholder validation evidence fail MVP runtime acceptance.
- Registration validation distinguishes environment/setup failure from real invalid bundle evidence.
- Smoke or a focused script fails if any required MVP runtime capability keeps placeholder evidence.
- `cargo build --locked --workspace --target wasm32-wasip1` passes.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
cargo build --locked --workspace --target wasm32-wasip1

bash scripts/traverse-component-manifests.sh --check

PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-033: Add a Real Imported-Document Question Acceptance Test

### Objective

Prove the first MVP against a realistic local user flow: import or normalize a source document, build artifacts, ask one question through the real Traverse-composed workflow, and verify answer evidence.

### Scope

Create an acceptance smoke that uses repo-safe fixture content and exercises:

- source conversion or normalization into markdown
- artifact sync/build
- search index generation
- graph artifact availability
- runtime answer request through the real Traverse-composed local path
- answer text with source-backed citations
- graph evidence
- validation status

### Out of Scope

- private user content
- large copyrighted documents
- benchmark-quality retrieval scoring
- mandatory live local LLM availability in default CI
- accepting Browser demo, temporary harnesses, contract stubs, fake workflow steps, skeleton manifests, or placeholder digests as completion evidence

### Definition of Done

- The test starts from fixture input that represents an imported document, not only a prebuilt `app/site/search-index.json`.
- The test rebuilds or refreshes the relevant markdown/search/graph artifacts.
- The test asks a concrete user question with an expected source-backed answer path.
- The answer path uses the real Traverse-composed `knowledge.query.answer` workflow.
- Every runtime business step is a real WASM microservice or real WASM agent capability.
- The test asserts at least one cited source or source reference from the imported fixture.
- The test asserts at least one graph node or edge from the imported fixture.
- The test asserts a validation status and trace reference.
- If model-backed inference is required, it runs through a real Traverse-governed WASM agent capability or fails with governed missing-dependency evidence.
- A live Traverse variant is documented when a local Traverse checkout/runtime is available.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh

TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-readiness.sh
```

## Ticket MVP-034: Enforce Explicit Browser Demo Fallback Semantics

### Objective

Prevent regressions where the PWA silently falls back to browser-side product/business behavior when Traverse is unavailable.

The Browser demo is useful for local no-server inspection, but it must remain an explicit developer-only provider choice and must not become a hidden alternate runtime or MVP acceptance path.

### Scope

Add tests and documentation that enforce:

- Traverse local is the default local provider
- Browser demo is visible and selectable
- Browser demo is not selected automatically after a Traverse failure
- Traverse failures remain visible with stable status, reason, and trace evidence
- UI code does not duplicate hidden retrieval, graph traversal, context packing, inference selection, validation, or formatting outside the explicit Browser demo developer aid

### Out of Scope

- removing Browser demo
- changing Traverse runtime behavior
- adding a hosted provider

### Definition of Done

- Unit or browser tests prove the default provider is Traverse local.
- Tests prove that a Traverse failure does not switch the selected provider to Browser demo.
- Tests prove Browser demo only runs after explicit provider selection.
- The visible UI status distinguishes Traverse failure from Browser demo success.
- Browser demo output is clearly marked as developer/demo evidence and not MVP runtime acceptance evidence.
- The temporary harness documentation states the retirement condition and says it cannot satisfy MVP runtime tickets.
- Placeholder/fallback scans do not find undocumented fallback paths in PWA runtime code.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
npm test -- app/components/browser-runtime.test.ts

PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-035: Add Traverse Blocker Escalation and Upstream Issue Template

### Objective

Create a disciplined feedback loop from youaskm3 to Traverse so app work drives Traverse evolution without adding downstream workarounds.

When a youaskm3 MVP ticket proves that Traverse is missing a required public surface, the agent should create a traceable Traverse requirement instead of hiding the gap in youaskm3 code.

### Scope

Add a lightweight blocker/escalation process covering:

- how to decide a gap belongs to Traverse rather than youaskm3
- required evidence before opening a Traverse issue
- required fields for the upstream issue
- how to link the upstream Traverse issue from the youaskm3 ticket or PR
- how to keep the youaskm3 ticket blocked instead of adding non-portable downstream logic

Suggested files:

- `docs/traverse-blocker-escalation.md`
- `.github/ISSUE_TEMPLATE/traverse-blocker.yml` or a markdown template if YAML templates are not used
- a short reference from `docs/youaskm3-ops.md`

### Out of Scope

- creating speculative Traverse issues without failing evidence
- changing Traverse code
- replacing the existing Traverse requirements document

### Definition of Done

- A documented decision checklist distinguishes youaskm3 bugs, Traverse blockers, and environment/setup failures.
- The template captures affected capability, expected public surface, observed failure, validation command, logs excerpt, Traverse version/commit, and downstream impact.
- The process requires a local/focused reproduction command or explains why one cannot exist.
- The process requires linking the upstream issue from the blocked youaskm3 issue.
- The ops docs tell future agents not to add downstream provider/runtime shortcuts when the blocker belongs upstream.
- A docs/spec smoke or focused check validates any new issue-template YAML.
- `bash scripts/smoke.sh` passes, or a docs-only focused validation is recorded with rationale.

### Validation

```bash
ruby -e 'require "yaml"; Dir.glob(".github/ISSUE_TEMPLATE/*.yml").sort.each { |path| YAML.load_file(path) }'

PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-036: Adopt Traverse v0.5.0 as the MVP-031 Runtime Baseline

### Objective

Pin youaskm3 MVP-031 and later runtime integration work to Traverse `v0.5.0`, the first Traverse release that adds public CLI app validation and local workspace registration surfaces for downstream apps.

### Scope

Update the repo baseline and validation references so future work uses:

- Traverse release `v0.5.0`
- governing Traverse spec `046-public-cli-app-registration`
- `traverse-cli app validate --manifest <path> --json`
- `traverse-cli app register --manifest <path> --workspace <workspace-id> --json`
- v0.5.0 release-pinned evidence and caveats

### Out of Scope

- Implementing `scripts/register-traverse-app.sh` consumption of `traverse-cli`
- Changing Traverse code
- Claiming real WASM agent execution is proven before MVP-031 validates it

### Definition of Done

- `SPEC.md` names Traverse `v0.5.0` as the minimum approved baseline for MVP-031 onward.
- `docs/traverse-mvp-requirements.md` documents v0.5.0 release evidence, new CLI surfaces, and remaining caveats.
- `scripts/traverse-readiness.sh` defaults to `MIN_TRAVERSE_TAG=v0.5.0`.
- The youaskm3 Traverse app manifest requires `v0.5.0`.
- Bundle docs reference `traverse-cli app validate` and `traverse-cli app register`.
- Historical v0.4.0 references remain only where they describe completed earlier work.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh

MIN_TRAVERSE_TAG=v0.5.0 \
TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-readiness.sh
```

If the local Traverse checkout is older than v0.5.0, the readiness command must fail with a clear setup message rather than weakening the baseline.

## Ticket MVP-037: Consume Traverse v0.5.0 Public App Validate/Register CLI

### Objective

Update the youaskm3 registration command to use Traverse v0.5.0 public CLI app validation and local workspace registration instead of stopping at the old missing-surface error.

### Scope

Update `scripts/register-traverse-app.sh` so that, when real component artifacts are present and `TRAVERSE_REPO` points to Traverse v0.5.0 or newer, it invokes:

- `traverse-cli app validate --manifest <path> --json`
- `traverse-cli app register --manifest <path> --workspace <workspace-id> --json`

The command must preserve machine-readable evidence for local validation, registration status, workspace id, app id, version, digests, failures, and Traverse version.

### Out of Scope

- Hosted registration service
- HTTP admin API registration
- Changing Traverse CLI behavior
- Accepting skeleton manifests, placeholder digests, fake workflow steps, or Browser demo evidence

### Definition of Done

- `scripts/register-traverse-app.sh --validate-only --json` remains CI-safe and validates local bundle evidence without requiring Traverse.
- With `TRAVERSE_REPO` set to Traverse v0.5.0 or newer and real WASM artifacts present, the script calls public `traverse-cli app validate`.
- With a workspace id provided, the script calls public `traverse-cli app register`.
- The script records CLI-produced workspace registration evidence in its JSON output.
- Missing `traverse-cli`, stale Traverse checkout, invalid manifest, missing workspace id, and CLI validation failures return stable machine-readable error codes.
- Existing smoke coverage is updated so the old `MISSING_PUBLIC_APP_REGISTRATION_SURFACE` path is no longer the expected success/failure result for v0.5.0.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
cargo build --locked --workspace --target wasm32-wasip1 --release

bash scripts/register-traverse-app.sh --validate-only --json

MIN_TRAVERSE_TAG=v0.5.0 \
TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/register-traverse-app.sh --json

PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-038: Add Release-Pinned Traverse v0.5.0 Conformance Evidence

### Objective

Add release-pinned evidence proving youaskm3 can validate the Traverse v0.5.0 pairing from a local checkout and distinguish setup failures from runtime blockers.

### Scope

Update readiness docs and smoke evidence around:

- v0.5.0 tag verification
- downstream app MVP conformance
- public CLI app registration conformance
- local checkout freshness errors
- optional live local model conformance caveat

### Out of Scope

- Implementing missing youaskm3 runtime capabilities
- Changing Traverse conformance scripts
- Treating release prose as enough evidence when local conformance can run

### Definition of Done

- `docs/traverse-mvp-requirements.md` contains a v0.5.0 release-pinned evidence checklist.
- `scripts/traverse-readiness.sh` reports the active Traverse tag/commit and minimum baseline.
- A stale local Traverse checkout fails clearly as an environment/setup failure.
- A v0.5.0-or-newer checkout runs downstream conformance through public Traverse surfaces.
- Readiness output summarizes application bundle registration, WASM workflow execution, model dependency resolution, HTTP/JSON app path, MCP parity path, and public CLI app registration where available.
- Optional live local model conformance remains opt-in.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
MIN_TRAVERSE_TAG=v0.5.0 \
TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-readiness.sh

TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1 \
MIN_TRAVERSE_TAG=v0.5.0 \
TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-readiness.sh

PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

- Common failures are documented:
  - missing `cargo`
  - missing `wasm32-wasip1`
  - Python 3.9 too old for MarkItDown
  - missing `eslint`
  - missing `cargo-llvm-cov`
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

## Ticket MVP-039: Implement `knowledge.infer` as a Real Traverse-Governed WASM Agent

### Objective

Replace the current recording/validation-only inference behavior with a real Traverse-governed WASM agent capability for `knowledge.infer`.

The first MVP requires real agent behavior for judgement, generation, planning, semantic interpretation, or model use. A capability that only records pre-generated model output is useful plumbing, but it does not satisfy MVP runtime acceptance.

### Scope

Implement or wire `knowledge.infer` so it can execute as a real WASM agent capability through Traverse:

- accepts packed context and inference request data from the Traverse workflow
- uses Traverse-governed model/capability dependency selection
- performs the agent execution required to produce answer text
- returns structured output matching `contracts/capabilities/knowledge.infer.json`
- records selected dependency, placement, status, failure reason, and trace id
- fails with governed missing-dependency evidence when no compatible model/capability is available

### Out of Scope

- hardcoding Ollama, WebLLM, llama.cpp, cloud APIs, or provider-specific routing in youaskm3
- accepting deterministic summary code as a fake replacement for agent behavior
- accepting pre-generated answer recording as MVP inference
- changing Traverse internals except through a linked Traverse blocker when public surfaces are insufficient
- production-quality model answer benchmarking

### Definition of Done

- `knowledge.infer` is implemented as a real WASM agent capability or is blocked by a linked Traverse requirement proving the missing public surface.
- The implementation compiles for `wasm32-wasip1`.
- The capability contract clearly identifies the agent behavior, input, output, dependency evidence, failure evidence, and trace fields.
- Unit tests cover successful agent output, missing prompt/context, missing selected dependency, missing trace id, empty generated output, and governed dependency failure.
- The Traverse component manifest identifies `knowledge.infer` as a real runtime artifact with a real digest.
- `knowledge.query.answer` workflow uses the real `knowledge.infer` agent step, not a recording-only shim.
- PWA, CLI, and tests do not hardcode model providers.
- If Traverse cannot execute the real WASM agent shape, the youaskm3 issue is marked Blocked and a detailed Traverse blocker is created.
- `cargo build --locked --workspace --target wasm32-wasip1` passes.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
cargo test --locked --package youaskm3-knowledge-infer

PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
cargo build --locked --workspace --target wasm32-wasip1

PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh

TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-answer-workflow-smoke.sh
```

## Ticket MVP-040: Add Final First-MVP Acceptance and Release Gate

### Objective

Create the final release gate that proves the entire first MVP end to end from a clean local setup.

This ticket is the point where the project can honestly say the first MVP is complete. It must not count Browser demo, temporary harnesses, contract stubs, fake workflow steps, skeleton manifests, placeholder digests, or downstream provider shortcuts as acceptance evidence.

### Scope

Add a final acceptance command, checklist, or smoke path that proves:

- local source input is converted or normalized into markdown artifacts
- search and graph artifacts are generated from local knowledge
- all MVP runtime capabilities build as real WASM microservices or real WASM agents
- component manifests contain real digests
- the app bundle validates and registers through Traverse v0.5.0 public CLI surfaces
- the PWA path asks a question through the real Traverse `knowledge.query.answer` workflow
- answer text, citations/source references, graph evidence, validation status, and trace reference are present
- the MCP path exposes equivalent workflow evidence
- failure cases are classified as setup, downstream implementation, or Traverse blocker

### Out of Scope

- federation discovery or cross-instance fan-out
- hosted accounts, billing, teams, or databases
- production hosted model service
- claiming the model engine itself is WASM-native unless Traverse evidence proves it
- accepting any placeholder/demo path as release evidence

### Definition of Done

- A single documented acceptance command or ordered checklist exists for the first MVP release gate.
- The gate starts from a clean local setup and does not rely on pre-opened browser state.
- The gate validates normal repo health with `bash scripts/smoke.sh`.
- The gate validates Traverse v0.5.0 readiness or reports a clear setup failure.
- The gate validates/registers the app bundle through public Traverse CLI surfaces.
- The gate asks at least one imported-document question through the PWA/Traverse path.
- The gate asserts non-empty answer text, citations/source references, graph evidence, validation status, and trace reference.
- The gate exercises MCP parity for the same registered workflow.
- The gate fails if Browser demo, temporary harnesses, contract stubs, fake workflow steps, skeleton manifests, placeholder digests, or all-zero component evidence are used as acceptance evidence.
- The final docs list exact remaining caveats, including whether local model execution is optional and whether the model engine itself is WASM-native.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh

MIN_TRAVERSE_TAG=v0.5.0 \
TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-readiness.sh

TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-answer-workflow-smoke.sh

TRAVERSE_REPO=/Users/enricopiovesan/Documents/repos/Traverse \
bash scripts/traverse-mcp-answer-workflow-smoke.sh
```

## Recommended Parallelization

These tickets can start immediately and independently:

- MVP-001 roadmap rewrite
- MVP-002 capability contracts
- MVP-003 markdown artifact contract
- MVP-005 graph artifact contract
- MVP-011 Traverse readiness script
- MVP-015 toolchain docs

These become easier after the contracts exist:

- MVP-006 graph generation
- MVP-008 chat harness
- MVP-010 Traverse bundle skeleton
- MVP-013 first WASM capability
- MVP-014 citation validation

These become most useful after fixture artifacts exist:

- MVP-004 fixture corpus
- MVP-007 artifact-backed PWA
- MVP-009 PWA chat interaction
- MVP-012 product-level MVP acceptance test

Next highest-ROI tranche after MVP-030:

- MVP-031 local Traverse-backed chat happy path
- MVP-032 real WASM artifacts and component digests
- MVP-033 real imported-document question acceptance test
- MVP-034 explicit Browser demo fallback semantics
- MVP-035 Traverse blocker escalation template
- MVP-036 Traverse v0.5.0 baseline adoption
- MVP-037 public CLI app validate/register consumption
- MVP-038 release-pinned v0.5.0 conformance evidence
- MVP-039 real `knowledge.infer` WASM agent
- MVP-040 final first-MVP acceptance and release gate

Approved expanded second-brain tranche after the 2026-06-29 brainstorming session:

- MVP-041 canonical LLM-agnostic reasoning skill and generated ChatGPT/Claude adapters ([#138](https://github.com/enricopiovesan/youaskm3/issues/138))
- MVP-042 decision-log package schema, validator, and executable fixtures ([#139](https://github.com/enricopiovesan/youaskm3/issues/139))
- MVP-043 CLI decision-log package ingestion and provenance preservation ([#140](https://github.com/enricopiovesan/youaskm3/issues/140))
- MVP-044 full reasoning graph schema and deterministic extraction ([#141](https://github.com/enricopiovesan/youaskm3/issues/141))
- MVP-045 knowledge gap and conflict lifecycle ([#142](https://github.com/enricopiovesan/youaskm3/issues/142))
- MVP-046 graph-aware answer classification and context selection ([#143](https://github.com/enricopiovesan/youaskm3/issues/143))
- MVP-047 direct chat simple fact resolution through internal mini packages ([#144](https://github.com/enricopiovesan/youaskm3/issues/144))
- MVP-048 local HTTP JSON runtime and Traverse-backed MCP parity ([#145](https://github.com/enricopiovesan/youaskm3/issues/145))
- MVP-049 `m3 init` first-run setup, external knowledge roots, and runtime config ([#146](https://github.com/enricopiovesan/youaskm3/issues/146))
- MVP-050 file-system sync preflight and conflict detection ([#147](https://github.com/enricopiovesan/youaskm3/issues/147))
- MVP-051 `m3 serve` Traverse start/attach orchestration ([#148](https://github.com/enricopiovesan/youaskm3/issues/148))
- MVP-052 chat-only PWA UX for evidence, gaps, conflicts, and direct fact resolution ([#149](https://github.com/enricopiovesan/youaskm3/issues/149))
- MVP-053 MCP answer, gaps, and simple fact resolution tools ([#150](https://github.com/enricopiovesan/youaskm3/issues/150))
- MVP-054 expanded first-MVP acceptance gate with `m3 mvp-check` ([#151](https://github.com/enricopiovesan/youaskm3/issues/151))

Approved hosted public gap collector tranche after the 2026-07-05 planning session:

- FUTURE-008 hosted public gap collector architecture ([#187](https://github.com/enricopiovesan/youaskm3/issues/187))
- FUTURE-009 static chat gap submission UX ([#190](https://github.com/enricopiovesan/youaskm3/issues/190))
- FUTURE-010 minimal hosted gap collector endpoint ([#189](https://github.com/enricopiovesan/youaskm3/issues/189))
- FUTURE-011 CLI pull/review/import for hosted gap reports ([#188](https://github.com/enricopiovesan/youaskm3/issues/188))
- FUTURE-012 hosted gap collector security, privacy, and cost gate ([#186](https://github.com/enricopiovesan/youaskm3/issues/186))

## Ticket MVP-041: Build the Canonical Reasoning Skill and Generated Adapters

### Objective

Create the LLM-agnostic reasoning skill source and generated ChatGPT and Claude adapters that help a persona reason through concepts and produce valid decision-log packages.

### Governing Specs

- `docs/expanded-second-brain-mvp-decision-log.md`
- `openspec/specs/reasoning-assistant-skill/spec.md`
- `openspec/specs/decision-log-package/spec.md`

### Scope

- Add canonical skill source with provider-neutral interview rules.
- Add structured manifest metadata for generation.
- Generate ChatGPT and Claude adapter outputs from the canonical source.
- Add a drift check so generated adapters cannot fall behind the canonical source.
- Include generic CLI handoff instructions: `m3 ingest-decision-log /path/to/decision-log-package/`.

### Definition of Done

- Canonical skill source exists in the repo and is provider-neutral.
- ChatGPT and Claude generated adapter artifacts exist and are generated from the same source.
- Generated adapters preserve one-question-at-a-time brainstorming, options, pros, cons, recommendation, assumption challenge, and no-finalization-until-clear rules.
- Generated adapters require output package files: `decision-log.md`, `knowledge-note.md`, `metadata.json`.
- A drift check fails when generated artifacts are stale.
- No generated adapter contains hardcoded local user paths.
- `bash scripts/smoke.sh` or a focused documented validation gate passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-042: Define Decision-Log Package Schema, Validator, and Fixtures

### Objective

Define and validate the decision-log package contract used by external assistant-generated packages and internal mini packages.

### Governing Specs

- `openspec/specs/decision-log-package/spec.md`
- `openspec/specs/reasoning-assistant-skill/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`

### Scope

- Add package schema for `metadata.json`.
- Add structural rules for `decision-log.md` and `knowledge-note.md`.
- Support modes: `knowledge_addition`, `gap_resolution`, `direct_fact_resolution`, `conflict_resolution`.
- Add valid and invalid fixture packages.
- Add deterministic validation for required files, ids, mode-specific sections, no blocking clarifications, provenance, and knowledge-note consistency.

### Definition of Done

- Package schema and fixture packages exist.
- Validator rejects missing files, unsupported modes, incomplete required sections, and mismatched ids.
- Validator rejects `knowledge-note.md` claims not represented in `decision-log.md`.
- Validator records semantic validation as optional and distinguishes unavailable from failed.
- Failed semantic validation blocks the whole package and emits gap creation data.
- Archive/zip inputs are explicitly out of scope and rejected.
- Tests cover all first-MVP package modes and at least one invalid package per failure class.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-043: Implement CLI Decision-Log Package Ingestion and Provenance

### Objective

Implement `m3 ingest-decision-log /path/to/package/` so package directories become durable personal knowledge with traceable provenance.

### Governing Specs

- `openspec/specs/decision-log-package/spec.md`
- `openspec/specs/local-runtime-sync/spec.md`
- `openspec/specs/reasoning-graph/spec.md`

### Scope

- Add the generic CLI ingest command.
- Accept package directories only.
- Copy accepted packages into `knowledge/sources/decision-logs/<package-id>/`.
- Record original import path, package id, persona id, mode, timestamps, validation evidence, and Traverse availability.
- Create normalized knowledge notes from accepted packages.
- Support offline staging only; final ingestion and graph update require Traverse.

### Definition of Done

- `m3 ingest-decision-log /path/to/package/` exists.
- The command rejects archive files and missing package directories with stable errors.
- The command runs sync/conflict preflight before writes.
- The command validates package structure before copying or writing final knowledge.
- Accepted packages are copied into the knowledge store and preserve original path provenance.
- Normalized notes are written with links back to the source package.
- Offline mode can stage packages but cannot mark them as final ingested knowledge.
- Tests prove success, deterministic validation failure, offline staging, and uninitialized external knowledge root failure.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-044: Implement Full Reasoning Graph Schema and Deterministic Extraction

### Objective

Extend the graph contract and generator so decision-log packages produce full reasoning graph elements required by the expanded first MVP.

### Governing Specs

- `openspec/specs/reasoning-graph/spec.md`
- `openspec/specs/decision-log-package/spec.md`
- `openspec/specs/knowledge-graph/spec.md`

### Scope

- Extend graph schema for required reasoning node and edge types.
- Add deterministic extraction from structured decision-log package sections.
- Add executable fixture package and expected graph output.
- Preserve provenance to package, decision log, knowledge note, source gap, citations, confidence, and validation results.
- Record optional Traverse agent enrichment as unavailable, passed, or failed without making it mandatory.

### Definition of Done

- Graph schema supports `concept`, `question`, `option`, `tradeoff`, `assumption`, `decision`, `claim`, `open_question`, `source_gap`, `knowledge_note`, `citation`, `source_artifact`, `confidence_assessment`, and `validation_result`.
- Deterministic extraction produces stable node and edge ids and ordering.
- Expected graph fixture output is checked in and validated.
- Graph extraction fails when required package sections cannot produce mandatory graph elements.
- Existing source-document graph behavior still works.
- Tests cover at least one full reasoning package and one invalid extraction package.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-045: Implement Knowledge Gap and Conflict Lifecycle

### Objective

Create structured gap and conflict records for missing, uncertain, ambiguous, and conflicting knowledge discovered during answers, ingestion, validation, and sync.

### Governing Specs

- `openspec/specs/knowledge-gap-lifecycle/spec.md`
- `openspec/specs/reasoning-graph/spec.md`
- `openspec/specs/local-runtime-sync/spec.md`

### Scope

- Store gaps as `knowledge/gaps/open/<gap-id>.md` and resolved gaps as `knowledge/gaps/resolved/<gap-id>.md`.
- Store conflicts as `knowledge/conflicts/open/<conflict-id>.md` and resolved conflicts as `knowledge/conflicts/resolved/<conflict-id>.md`.
- Use structured front matter for status, persona, trace, source question, reason, linked package, linked graph nodes, and allowed resolution path.
- Create/update gaps from question-time failures and ingestion/validation failures.
- Classify gap complexity with deterministic baseline and optional Traverse agent override.

### Definition of Done

- Gap and conflict markdown schemas are documented and validated.
- Question-time unsupported/uncertain answers create or update open gaps.
- Ingestion validation failures create or update gaps without final knowledge ingestion.
- Semantic conflicts create conflict reports and do not silently merge.
- Gap complexity classification records deterministic result, optional agent result, final result, and allowed resolution path.
- `m3 gaps list` can list unresolved gaps with stable output.
- Tests cover gap creation, gap update, conflict creation, resolved movement, and invalid front matter.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-046: Add Graph-Aware Answer Classification and Context Selection

### Objective

Make the answer workflow select reasoning graph context based on answer type and disclose conflicts or uncertainty when relevant.

### Governing Specs

- `openspec/specs/reasoning-graph/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`
- `openspec/specs/traverse-integration/spec.md`

### Scope

- Add deterministic answer-type classification for factual, decision, uncertainty, concept explanation, and gap-oriented questions.
- Allow optional Traverse-governed agent refinement when available.
- Select graph context according to final answer type.
- Record deterministic answer type, optional agent-refined answer type, final answer type, and context strategy in trace/evidence.
- Summarize conflicts and create/update gaps when conflicts affect the answer.

### Definition of Done

- Answer-type classifier has deterministic tests for all MVP answer types.
- Context selection uses claims/citations for factual answers, decisions/rationale/tradeoffs/options for decision answers, assumptions/open questions/confidence for uncertainty answers, and gaps/conflicts when relevant.
- Trace output includes all required classification and context-strategy fields.
- Conflicting relevant knowledge is surfaced with evidence and creates/updates a gap.
- The UI receives formatted evidence from the runtime and does not implement classification or context selection.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-047: Implement Direct Chat Fact Resolution Through Internal Mini Packages

### Objective

Allow simple factual gaps to be resolved directly in chat while preserving the same package validation, provenance, graph extraction, and gap update path as external decision-log packages.

### Governing Specs

- `openspec/specs/knowledge-gap-lifecycle/spec.md`
- `openspec/specs/decision-log-package/spec.md`
- `openspec/specs/reasoning-graph/spec.md`

### Scope

- Detect when an open gap allows direct factual resolution.
- Convert the user's chat answer into an internal mini package using the shared package schema.
- Validate, ingest, extract graph elements, and resolve/update the gap through the same pipeline as external packages.
- Reject direct chat resolution for reasoning-heavy gaps and direct the user to decision-log package flow.

### Definition of Done

- Direct simple fact resolution produces an internal package artifact with provenance.
- Internal packages use the same schema with mode-specific required sections.
- Successful direct resolution updates knowledge, graph, and gap status.
- Reasoning-heavy gaps cannot be resolved through direct chat.
- Trace records the internal package id and linked gap id.
- Tests cover simple fact success, reasoning-heavy rejection, invalid direct answer, and graph update.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-048: Build Local HTTP JSON Runtime and Traverse-Backed MCP Parity

### Objective

Provide local runtime surfaces for PWA chat and MCP that call the same Traverse-backed workflows.

### Governing Specs

- `openspec/specs/local-runtime-sync/spec.md`
- `openspec/specs/mcp-interface/spec.md`
- `openspec/specs/traverse-integration/spec.md`

### Scope

- Add HTTP JSON endpoints for answer, gaps list, and direct simple fact resolution.
- Add or extend MCP tools for the same operations.
- Ensure HTTP and MCP share the same Traverse workflow and do not duplicate business logic.
- Return equivalent trace, evidence, provenance, gap, and conflict fields.

### Definition of Done

- Local HTTP JSON answer endpoint exists and calls Traverse-backed workflow.
- Local HTTP JSON gaps list and simple fact resolution endpoints exist.
- MCP exposes answer, gaps list, and simple fact resolution tools.
- HTTP and MCP parity tests prove equivalent behavior for the same fixture workspace.
- Neither surface implements retrieval, graph traversal, context packing, inference selection, validation, formatting, gap lifecycle, or conflict policy outside Traverse-governed capabilities.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-049: Extend `m3 init` for First-Run Setup and Knowledge Roots

### Objective

Make `m3 init` the first-run setup command for workspace defaults, external knowledge roots, Traverse configuration, and offline mode.

### Governing Specs

- `openspec/specs/local-runtime-sync/spec.md`
- `openspec/specs/decision-log-package/spec.md`

### Scope

- Support `m3 init --knowledge-root <path> --traverse-repo <path>`.
- Support `m3 init --offline --knowledge-root <path>`.
- Create/validate external knowledge-root markers before writes.
- Write project config and allow CLI override for runtime commands.
- Validate Traverse baseline when provided.
- Mark runtime readiness unavailable in offline mode.

### Definition of Done

- `m3 init` initializes default workspace knowledge root and external roots.
- External roots require a marker before any write command can mutate them.
- Project config records Traverse path/config and knowledge-root defaults.
- CLI overrides take precedence over config.
- Offline mode can prepare storage but cannot final-ingest packages or run runtime acceptance.
- Stable setup errors guide the user to the next command.
- Tests cover workspace root, external root, offline mode, Traverse unavailable, and CLI override behavior.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-050: Add File-System Sync Preflight and Conflict Detection

### Objective

Support multi-machine local usage through file-system sync folders with safe preflight checks and conflict reports.

### Governing Specs

- `openspec/specs/local-runtime-sync/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`

### Scope

- Add sync state metadata for decision-log packages, knowledge notes, gaps, conflicts, graph artifacts, and index metadata.
- Run sync/conflict preflight before knowledge-writing commands.
- Provide `m3 sync check`.
- Auto-merge only safe append-only artifacts.
- Stop and create structured conflict reports for semantic conflicts.

### Definition of Done

- `m3 sync check` reports clean, auto-merged, open conflict, and blocked states.
- Knowledge-writing commands run preflight before mutation.
- Safe append-only merge is narrowly defined and tested.
- Semantic conflicts stop writes and create `knowledge/conflicts/open/<conflict-id>.md`.
- Chat only discloses sync conflicts when they affect answer or confidence.
- Tests cover clean sync, append-only merge, semantic conflict, metadata/index conflict, and blocked write.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-051: Implement `m3 serve` Traverse Start/Attach Runtime Orchestration

### Objective

Provide `m3 serve` as the local runtime command that starts or attaches to Traverse and powers HTTP JSON plus MCP surfaces.

### Governing Specs

- `openspec/specs/local-runtime-sync/spec.md`
- `openspec/specs/traverse-integration/spec.md`

### Scope

- Read Traverse and knowledge-root configuration from project config with CLI overrides.
- Try to start or attach to Traverse.
- Validate the registered app bundle or fail with actionable setup errors.
- Start local HTTP JSON and MCP surfaces only after runtime readiness is established.

### Definition of Done

- `m3 serve` exists and reads config plus CLI overrides.
- Traverse unavailable errors are stable and actionable.
- The command does not silently fall back to Browser demo or local fake runtime.
- The command exposes local HTTP JSON and MCP surfaces when Traverse is ready.
- The command reports runtime URL, MCP endpoint, workspace id, and trace/evidence mode.
- Tests cover config read, CLI override, Traverse unavailable, and successful attach/start using the repo's available test harness.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-052: Implement Chat-Only PWA UX for Evidence, Gaps, Conflicts, and Direct Fact Resolution

### Objective

Make the PWA behave like a chat interface while rendering runtime-provided answers, evidence, deferrals, gaps, conflicts, and simple fact resolution states.

### Governing Specs

- `openspec/specs/pwa-shell/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`
- `openspec/specs/reasoning-graph/spec.md`

### Scope

- Render supported answers with concise provenance/evidence by default.
- Render unsupported/uncertain deferral responses.
- Let the user answer a simple factual gap in chat.
- Display conflict summaries only when they affect the answer.
- Keep rebuild, extraction, sync, and pipeline internals out of the UI.

### Definition of Done

- PWA renders answer, provenance type, citations, graph evidence, validation status, and trace reference from runtime response data.
- PWA renders deferral and gap request states without implementing gap lifecycle logic.
- PWA can submit direct simple fact resolution only when runtime marks it allowed.
- PWA surfaces relevant conflicts without becoming a task dashboard.
- PWA does not implement retrieval, graph traversal, context packing, inference selection, validation, formatting, gap lifecycle, sync conflict policy, or graph extraction.
- Frontend tests cover supported answer, unsupported deferral, direct fact resolution prompt, relevant conflict disclosure, and no Browser demo acceptance path.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-053: Add MCP Answer, Gaps, and Simple Fact Resolution Tools

### Objective

Expose the expanded first-MVP chat loop through MCP with parity to the local HTTP JSON path.

### Governing Specs

- `openspec/specs/mcp-interface/spec.md`
- `openspec/specs/local-runtime-sync/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`

### Scope

- Add or update MCP contracts for answer, gaps list, and direct simple fact resolution.
- Ensure tools invoke the same Traverse-backed workflow as HTTP/PWA.
- Return equivalent provenance, evidence, trace, gap, and conflict data.

### Definition of Done

- MCP tool contracts exist for answer, gaps list, and simple fact resolution.
- MCP implementation does not duplicate business logic outside Traverse-governed capabilities.
- MCP parity smoke covers the same fixture workspace as HTTP/PWA tests.
- MCP responses include trace ids, provenance type, citations/evidence, gap ids, and conflict ids when relevant.
- MCP rejects unsupported direct resolution attempts for reasoning-heavy gaps.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
```

## Ticket MVP-054: Add Expanded First-MVP Acceptance Gate

### Objective

Create `m3 mvp-check` as the final expanded first-MVP acceptance gate that proves the full second-brain product loop without placeholders.

### Governing Specs

- `docs/expanded-second-brain-mvp-decision-log.md`
- `docs/mvp-user-stories.md`
- `openspec/specs/reasoning-assistant-skill/spec.md`
- `openspec/specs/decision-log-package/spec.md`
- `openspec/specs/reasoning-graph/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`
- `openspec/specs/local-runtime-sync/spec.md`
- `openspec/specs/traverse-integration/spec.md`

### Scope

- Add `m3 mvp-check --traverse-repo <path> --knowledge-root <path>`.
- Run or orchestrate the real acceptance workflow from clean setup.
- Validate assistant skill generation, package ingestion, reasoning graph extraction, gap lifecycle, sync preflight, local serve, PWA/HTTP answer, MCP parity, direct fact resolution, and provenance/evidence.
- Link to baseline final gate issue `#136` and existing runtime baseline tickets `#120`, `#122`, and `#135`.

### Definition of Done

- `m3 mvp-check` exists and documents the real first-MVP acceptance path.
- The gate validates normal repo health and Traverse readiness.
- The gate fails if Browser demo, temporary harnesses, fake workflow steps, skeleton manifests, placeholder digests, all-zero evidence, or downstream runtime shortcuts are used as acceptance evidence.
- The gate validates ChatGPT and Claude adapter generation drift.
- The gate ingests at least one real decision-log package fixture.
- The gate validates full reasoning graph extraction and expected graph output.
- The gate validates gap creation, gap listing, direct simple fact resolution, and conflict report behavior.
- The gate validates local HTTP JSON and MCP parity against the same Traverse-backed workflow.
- The gate records exact remaining caveats, including optional semantic validation availability and WASM-native model-engine caveat.
- `bash scripts/smoke.sh` passes.

### Validation

```bash
bash scripts/smoke.sh
m3 mvp-check --traverse-repo /path/to/Traverse --knowledge-root /path/to/root
```

## Post-First-MVP Missing Scope

The following tickets cover missing surfaces that are intentionally outside the expanded first MVP but now have traceable specs and DoD.

## Ticket FUTURE-001: Package and Distribute Assistant Adapters ([#168](https://github.com/enricopiovesan/youaskm3/issues/168))

### Objective

Turn generated ChatGPT, Claude, and future assistant adapters into packaged, versioned distribution artifacts without moving product logic out of the canonical LLM-agnostic skill.

### Governing Specs

- `openspec/specs/assistant-distribution/spec.md`
- `openspec/specs/reasoning-assistant-skill/spec.md`

### Scope

- Define platform packaging metadata for ChatGPT and Claude.
- Generate packaged artifacts from existing generated adapters.
- Add package/version drift checks against canonical skill and package schema versions.
- Document platform limitations for marketplace publishing, file export, local handoff, and action/tool availability.

### Definition of Done

- Packaging metadata exists for ChatGPT and Claude adapters.
- Packaged artifacts are generated from canonical skill/adapters, not hand-edited copies.
- Drift checks fail when canonical skill, adapter, or schema versions change without regenerated packages.
- Package docs list each platform's known limitations and blocked capabilities.
- ChatGPT and Claude are both treated as equal golden targets.
- Bundles include examples for `knowledge_addition`, `gap_resolution`, and `conflict_resolution`.
- Bundles produce package files for CLI ingestion without requiring platform action/tool integration.
- No package hardcodes private user paths or private knowledge.
- Validation passes.

### Resolved Planning Decisions

- Distribution starts as generated platform artifact bundles, not marketplace-ready publishing.
- ChatGPT and Claude are equal golden targets.
- Marketplace publication and platform action/tool integration are later scope.

### Remaining Unknowns To Discuss

- What exact packaging format does each platform require at implementation time?
- Should marketplace publication become a separate release ticket once package artifacts are stable?

## Ticket FUTURE-002: Add Archive and Inbox Decision-Log Import Automation ([#169](https://github.com/enricopiovesan/youaskm3/issues/169))

### Objective

Add convenience import flows for decision-log packages after the canonical CLI directory ingestion path is stable.

### Governing Specs

- `openspec/specs/package-import-automation/spec.md`
- `openspec/specs/decision-log-package/spec.md`
- `openspec/specs/local-runtime-sync/spec.md`

### Scope

- Add safe zip/archive ingestion with path traversal, size, and structure validation.
- Add optional inbox/watch-folder processing.
- Preserve the same validation, provenance, sync preflight, and Traverse final-ingestion rules as `m3 ingest-decision-log`.
- Add clear ingested, rejected, staged, and blocked result records.

### Definition of Done

- Archive ingestion rejects unsafe paths, oversized packages, missing files, and invalid metadata before writes.
- `.zip` is the first supported archive format.
- Unsupported archive formats fail with stable errors.
- Inbox processing can be enabled explicitly and does not silently ingest final knowledge without validation.
- First inbox processing is command-driven, not a background watcher.
- Automated imports can be reproduced through the canonical CLI command.
- Validation and error messages match package directory ingestion semantics.
- Tests cover safe archive, traversal attack, invalid archive, inbox success, inbox rejection, and offline staging.
- Validation passes.

### Resolved Planning Decisions

- Archive ingestion comes first.
- `.zip` is first; tar formats are later only if needed.
- Inbox processing starts as an explicit command; watcher behavior is later.

### Remaining Unknowns To Discuss

- What should the explicit inbox command be named?
- How much user confirmation is required before final ingestion from automation?

## Ticket FUTURE-003: Add Claim-Level Partial Ingestion and Answer Benchmarks ([#170](https://github.com/enricopiovesan/youaskm3/issues/170))

### Objective

Move beyond first-MVP all-or-nothing semantic validation by supporting claim-level partial ingestion and production-quality answer benchmarks.

### Governing Specs

- `openspec/specs/semantic-quality-evaluation/spec.md`
- `openspec/specs/decision-log-package/spec.md`
- `openspec/specs/reasoning-graph/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`

### Scope

- Define claim-level extraction and validation records.
- Allow accepted claims to ingest while rejected claims become gaps.
- Add benchmark fixture corpus for grounding, provenance, conflicts, gaps, and reasoning usefulness.
- Report unsupported claim rate, conflict disclosure rate, gap behavior, and provenance completeness.

### Definition of Done

- Claim-level validation schema exists.
- Deterministic claim extraction is required.
- Optional Traverse-governed semantic refinement is supported when available.
- Partial ingestion records accepted and rejected claims with provenance.
- Rejected claims create or update gaps instead of disappearing.
- Generic benchmarks run deterministically and do not mutate personal knowledge.
- Persona-specific benchmarks are optional, local, and private.
- Benchmark reports are useful for release quality decisions.
- Release gates cover correctness, grounding, provenance, unsupported claim rate, conflict disclosure, gap creation behavior, and citation completeness.
- Tests cover partial package ingestion, rejected claim gap creation, and benchmark reporting.
- Validation passes.

### Resolved Planning Decisions

- Generic benchmark is required; persona-specific benchmark is optional/local.
- Release-blocking benchmark dimensions cover full trust behavior.
- Claim extraction is deterministic with optional Traverse-governed semantic refinement.

### Remaining Unknowns To Discuss

- What numeric answer-quality thresholds should block release?
- Which Traverse semantic validator/agent is acceptable for refinement?

## Ticket FUTURE-004: Support Multi-Persona Knowledge Isolation and Sharing ([#171](https://github.com/enricopiovesan/youaskm3/issues/171))

### Objective

Support multiple personas in one installation while preserving isolation, provenance, and explicit sharing rules.

### Governing Specs

- `openspec/specs/multi-persona/spec.md`
- `openspec/specs/decision-log-package/spec.md`
- `openspec/specs/reasoning-graph/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`

### Scope

- Add persona registry and active persona selection.
- Isolate knowledge, gaps, conflicts, graph context, and assistant package metadata by default.
- Support explicit shared scopes with conflict visibility.
- Generate persona-aware assistant packages without embedding private knowledge.

### Definition of Done

- Multiple personas can exist in one installation.
- A persona is a knowledge identity, distinct from hosted account.
- Answer context uses only the active persona's allowed scope.
- Hybrid graph model isolates persona scopes by default and supports explicit shared scopes.
- Shared scopes require explicit metadata and are read-only by default.
- Shared-scope writes require explicit policy.
- Conflicts follow scope visibility.
- Default persona plus explicit chat/CLI switch are supported; no silent persona inference occurs.
- Assistant adapters can include persona metadata without embedding private knowledge content.
- Tests cover isolated personas, shared scope, conflict visibility, and provenance.
- Validation passes.

### Resolved Planning Decisions

- Persona is a knowledge identity: person, role, project, or domain identity.
- Graph model is hybrid: isolated persona scopes plus explicit shared scopes.
- Active persona uses default persona plus explicit switch.
- Full behavior is future scope, but schemas reserve persona/scope fields now.

### Remaining Unknowns To Discuss

- What exact CLI/chat syntax should switch personas?
- How should shared-scope write policies be expressed?

## Ticket FUTURE-005: Define Optional Hosted Service, Accounts, Teams, and Hosted Sync ([#172](https://github.com/enricopiovesan/youaskm3/issues/172))

### Objective

Define optional hosted youaskm3 capabilities without weakening local-first operation.

### Governing Specs

- `openspec/specs/hosted-service/spec.md`
- `openspec/specs/local-runtime-sync/spec.md`
- `openspec/specs/multi-persona/spec.md`

### Scope

- Define hosted account, team, permission, and hosted sync boundaries.
- Keep hosted identity separate from local persona identity.
- Preserve local operation when hosted service is unavailable.
- Preserve conflict records and no-silent-overwrite policy in hosted sync.

### Definition of Done

- Hosted service architecture spec exists for accounts, teams, permissions, and hosted sync.
- Local-first operation remains valid without hosted config.
- Nothing leaves the user's machine by default.
- Hosted features require explicit opt-in and state what data leaves the machine.
- Hosted identity and local persona metadata are separate.
- Personal hosted sync defaults to end-to-end encrypted blobs.
- Raw readable or team/shared hosted modes require explicit policy and consent.
- Hosted runtime execution is allowed only per explicit capability placement policy.
- Hosted sync uses the same semantic conflict principles as local sync.
- Security and privacy risks are documented before implementation.
- Validation passes for docs/spec checks.

### Resolved Planning Decisions

- Hosted service is an optional hosted convenience layer over the local-first core.
- Nothing leaves the machine by default.
- Hosted sync is mode-specific: encrypted personal sync by default, raw/shared/team modes by explicit opt-in.
- Hosted runtime is per-capability, explicit, and Traverse-governed.

### Remaining Unknowns To Discuss

- What identity provider and permission model are acceptable?
- Which hosted capabilities are worth implementing first?

## Ticket FUTURE-006: Add Federated Cross-Instance Answer Flows ([#173](https://github.com/enricopiovesan/youaskm3/issues/173))

### Objective

Extend existing federation registry and index work into explicit cross-instance search and answer behavior.

### Governing Specs

- `openspec/specs/federated-answer/spec.md`
- `openspec/specs/federation/spec.md`
- `openspec/specs/reasoning-graph/spec.md`

### Scope

- Add opt-in policy for federated search and answers.
- Label remote evidence separately from local personal knowledge.
- Preserve remote instance, source artifact, retrieval path, and confidence provenance.
- Support explicit import from federated evidence into local knowledge or decision-log reasoning.

### Definition of Done

- Federated answer policy is explicit and disabled unless allowed.
- Federated answers can appear in the same chat only when explicitly enabled per question or session.
- Answers distinguish local evidence from remote instance evidence.
- Remote evidence is lower-trust, evidence-only by default.
- Remote evidence is never silently treated as personal knowledge.
- Import from remote evidence can save a source artifact or create a decision-log package for adopted personal reasoning.
- Import preserves source provenance.
- Tests cover disabled federation, remote-evidence answer, and explicit import path.
- Validation passes.

### Resolved Planning Decisions

- Federated answers are same-chat only when explicitly enabled.
- Remote evidence is lower-trust evidence-only by default.
- Remote import supports source artifact and decision-log package paths.

### Remaining Unknowns To Discuss

- How should remote content licensing and removal be handled?
- What UI control enables federation per question/session?

## Ticket FUTURE-007: Prove WASM-Native Model-Engine Execution When Traverse Supports It ([#174](https://github.com/enricopiovesan/youaskm3/issues/174))

### Objective

Define and validate the evidence required before youaskm3 claims the model engine itself is WASM-native.

### Governing Specs

- `openspec/specs/wasm-native-model-evidence/spec.md`
- `docs/mvp-local-inference-policy.md`
- `openspec/specs/traverse-integration/spec.md`

### Scope

- Distinguish Traverse-governed inference from WASM-native model-engine execution.
- Define required Traverse evidence: module identity, digest, placement, execution trace, model dependency id, and failure mode.
- Add readiness checks that fail unsupported WASM-native model claims.
- Keep the first-MVP caveat until evidence exists.

### Definition of Done

- Docs clearly distinguish governed inference from WASM-native model-engine execution.
- Required Traverse evidence contract includes engine/module identity and digest, model/weights id and digest, placement target, trace id, dependency id, selected provider/candidate id, and failure mode.
- Readiness validation fails if release notes or docs claim fully WASM-native inference without evidence.
- Positive validation passes when Traverse exposes stable model-engine WASM evidence.
- Tests cover unsupported claim failure and supported evidence success.
- Validation passes.

### Resolved Planning Decisions

- WASM-native model execution means WASM-governed runtime engine plus digest-traceable model assets.
- Fully WASM-native inference evidence is required only for releases that claim fully WASM-native inference.
- Normal releases may claim Traverse-governed inference while preserving the model-engine caveat.

### Remaining Unknowns To Discuss

- What exact Traverse trace field names will expose the required evidence?
- Should fully WASM-native inference become a release blocker later or remain a conformance badge?

## Ticket FUTURE-008: Define Hosted Public Gap Collector Architecture ([#187](https://github.com/enricopiovesan/youaskm3/issues/187))

### Objective

Define the smallest optional hosted architecture that makes public GitHub Pages chat gap capture low-friction without creating a full hosted youaskm3 service.

### Governing Specs

- `openspec/specs/hosted-gap-collector/spec.md`
- `openspec/specs/hosted-service/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`

### Scope

- Document why browser WASM and GitHub Secrets cannot safely provide automatic public writes from GitHub Pages.
- Define the recommended minimal architecture: GitHub Pages chat, trusted collector endpoint, abuse validation, pending gap storage, and CLI owner import.
- Define accepted equivalent provider requirements for alternatives to Cloudflare Worker, D1, and Turnstile.
- Define public gap report schema fields and stable error codes at the spec level.

### Definition of Done

- `openspec/specs/hosted-gap-collector/spec.md` describes local-first source-of-truth, no browser secrets, pending-only storage, owner review/import, abuse controls, privacy disclosure, and cost limits.
- Architecture docs distinguish this narrow collector from full hosted youaskm3 accounts, sync, teams, hosted runtime, and inference.
- Public gap report payload fields are listed: question, missing knowledge, published scope, checked evidence, source URL, timestamp, reporter context, schema version, and validation version.
- Failure modes are documented for missing collector config, invalid payload, abuse challenge failure, rate limit, storage failure, and owner import failure.
- No implementation claims direct graph writes or automatic local knowledge mutation from the public hosted collector.
- Validation passes for OpenSpec/docs checks.

### Resolved Planning Decisions

- Low-friction GitHub Pages gap capture requires a trusted hosted boundary.
- The collector is optional and narrow; it stores pending reports only.
- The local user-owned instance remains the source of truth.
- Cloudflare Worker, D1, and Turnstile are the recommended first near-zero-cost architecture, but equivalent providers are allowed if they preserve the same trust and cost boundaries.

### Remaining Unknowns To Discuss

- Which provider should be the first supported reference implementation?
- What retention period should pending public gap reports use by default?

## Ticket FUTURE-009: Add Static Chat Gap Submission UX ([#190](https://github.com/enricopiovesan/youaskm3/issues/190))

### Objective

Add the GitHub Pages/static-chat UX for reporting a knowledge gap to a configured hosted collector, with honest fallback behavior when no collector exists.

### Governing Specs

- `openspec/specs/hosted-gap-collector/spec.md`
- `openspec/specs/pwa-shell/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`

### Scope

- Add static client configuration for an optional gap collector endpoint and public scope metadata.
- Show transparent insufficient-knowledge messaging and a submit-gap action for public chat.
- Send a validated public gap report to the configured collector.
- Provide fallback actions when no collector is configured: GitHub issue draft, copy markdown, or download gap package.
- Keep the PWA UI-only: no graph mutation, no inference, no secret handling, and no business-logic shortcuts in the client.

### Definition of Done

- Static chat shows what was known, what is missing, and the action to submit a public gap.
- Submit action posts only the public gap report payload to the configured collector endpoint.
- The browser bundle contains no write token, GitHub secret, database credential, or hidden privileged endpoint.
- UI discloses what data leaves the page before submission.
- Missing collector config produces a clear fallback path and does not show fake one-click hosted submission.
- Tests cover configured collector success, collector unavailable failure, invalid input, and no-collector fallback.
- Accessibility checks cover the submit, fallback, success, and error states.
- Validation passes.

### Resolved Planning Decisions

- GitHub Pages public chat may capture gaps through a hosted collector when configured.
- Without a collector, the product must offer honest manual fallbacks instead of pretending the flow is painless.
- Static client code must not contain secrets or mutate knowledge directly.

### Remaining Unknowns To Discuss

- What exact public UI label should distinguish hosted submit from manual fallback?
- Should copy/download fallback use markdown only or a zip package from day one?

## Ticket FUTURE-010: Implement Minimal Hosted Gap Collector Endpoint ([#189](https://github.com/enricopiovesan/youaskm3/issues/189))

### Objective

Implement the optional hosted collector reference endpoint that accepts public gap reports, validates abuse controls, and stores pending reports for owner review.

### Governing Specs

- `openspec/specs/hosted-gap-collector/spec.md`
- `openspec/specs/hosted-service/spec.md`

### Scope

- Implement a reference Cloudflare Worker or equivalent serverless endpoint.
- Validate payload schema, origin policy, Turnstile or equivalent challenge, body size, and rate limits.
- Store accepted reports in D1 or equivalent pending storage.
- Return stable success and error responses.
- Avoid LLM calls, inference, graph writes, and automatic GitHub issue creation in the collector.

### Definition of Done

- Collector rejects requests with missing required fields, oversized payloads, failed challenge, disallowed origin, and rate limit violations.
- Accepted reports receive a stable report id and are stored with pending status.
- Stored report includes schema version, validation version, created timestamp, source URL, published scope, checked evidence, missing knowledge, and reporter context.
- No browser-facing secret is required for submission.
- No collector path can directly mutate local knowledge or mark a report imported without owner-side action.
- Tests cover valid report, invalid report, challenge failure, rate limit, storage failure, and stable error codes.
- Deployment docs list required environment variables/secrets and free-tier/cost assumptions.
- Validation passes.

### Resolved Planning Decisions

- The first hosted feature should be a gap collector, not full hosted youaskm3.
- The collector should use managed free/near-free primitives and conservative quotas.
- The collector must store pending reports only.

### Remaining Unknowns To Discuss

- Should the first reference implementation live in this repo or a separate deployable package?
- Should owner authentication for report-status updates be included in the first collector slice or deferred to CLI pull-only access?

## Ticket FUTURE-011: Add CLI Pull, Review, and Import for Hosted Gap Reports ([#188](https://github.com/enricopiovesan/youaskm3/issues/188))

### Objective

Allow an owner to pull pending hosted gap reports, review them, and import accepted reports into the local knowledge gap lifecycle.

### Governing Specs

- `openspec/specs/hosted-gap-collector/spec.md`
- `openspec/specs/knowledge-gap-lifecycle/spec.md`
- `openspec/specs/local-runtime-sync/spec.md`

### Scope

- Add CLI configuration for hosted collector source credentials or read endpoint.
- List pending reports with enough context for owner review.
- Import accepted reports as local structured knowledge gaps.
- Preserve hosted report provenance.
- Reject or archive reports without importing when the owner chooses.

### Definition of Done

- CLI can list pending reports from a configured collector without importing them.
- CLI can import a selected report into the local instance as a structured knowledge gap.
- Imported gap records hosted report id, collector source, source URL, published scope, reporter context, timestamp, schema version, and validation version.
- Import uses existing local validation and conflict/gap lifecycle rules.
- CLI can reject or archive a report when supported by the collector, or record local ignore state when remote status update is unavailable.
- Tests cover list, import, duplicate import prevention, reject/archive, invalid remote payload, and collector unavailable failure.
- No report bypasses local user consent or local validation.
- Validation passes.

### Resolved Planning Decisions

- Owner review/import is mandatory.
- Public submissions do not become local knowledge until imported.
- CLI is the bridge from hosted pending reports to local source-of-truth knowledge.

### Remaining Unknowns To Discuss

- What CLI command names should be used for hosted gap pull/review/import?
- Should accepted reports default to open gaps or staged review files?

## Ticket FUTURE-012: Add Hosted Gap Collector Security, Privacy, and Cost Gate ([#186](https://github.com/enricopiovesan/youaskm3/issues/186))

### Objective

Add release gating and documentation that prevents enabling the hosted gap collector without abuse controls, privacy disclosure, and cost limits.

### Governing Specs

- `openspec/specs/hosted-gap-collector/spec.md`
- `openspec/specs/hosted-service/spec.md`

### Scope

- Document the security, privacy, retention, and cost model for the hosted collector.
- Add validation that release docs do not claim painless public gap capture unless a collector or honest fallback exists.
- Add configuration checks for required collector limits and disclosure.
- Keep the gate independent from full hosted accounts/sync/team readiness.

### Definition of Done

- Docs list what public gap data is collected, where it is stored, who can read it, retention expectations, and owner deletion/export path.
- Docs list expected free-tier assumptions and conservative default limits.
- Validation fails if public hosted gap capture is enabled without configured abuse control, body limit, rate limit, and privacy disclosure.
- Validation fails if GitHub Pages docs claim automatic one-click submission while only GitHub issue draft/manual fallback is configured.
- Tests cover missing disclosure, missing abuse control, missing limits, configured collector success, and fallback-only success.
- The gate does not require full hosted youaskm3 accounts, sync, teams, or hosted runtime.
- Validation passes.

### Resolved Planning Decisions

- Reducing user friction must not hide privacy, abuse, or cost risks.
- Hosted collector readiness is separate from full hosted-service readiness.
- Fallback-only static deployments are valid, but must be labeled honestly.

### Remaining Unknowns To Discuss

- What usage threshold should trigger moving from free-tier collector assumptions to explicit billing alerts?
- What default retention period balances useful owner review with privacy minimization?

## First Tickets to Start

Recommended first implementation ticket for the Traverse-backed runtime baseline:

> MVP-031: Prove the Local Traverse-Backed Chat Happy Path

Reason:

- Traverse v0.5.0 is the approved baseline for MVP-031 onward.
- It validates the user-facing product with real runtime pressure.
- It exposes any remaining Traverse gaps through concrete evidence.
- It keeps youaskm3 from drifting into downstream runtime shortcuts.

Recommended first implementation ticket for the expanded second-brain tranche:

> MVP-041: Build the Canonical Reasoning Skill and Generated Adapters

Reason:

- It defines the quality of the reasoning content that future answers depend on.
- It produces the decision-log package source that downstream ingestion, graph extraction, gaps, and final acceptance need.
- It validates the LLM-agnostic adapter generation rule before ChatGPT/Claude-specific behavior can drift.

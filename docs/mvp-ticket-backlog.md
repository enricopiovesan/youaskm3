# youaskm3 MVP Ticket Backlog

Status: Draft implementation backlog
Last updated: 2026-06-12

## Goal

This backlog breaks the first youaskm3 MVP into independent tickets that can be picked up by separate contributors or agents.

The MVP target is:

> A local-first PWA chat experience that answers from user-owned knowledge artifacts, with source attribution and graph context, while preparing the product to hand runtime business logic to Traverse as governed WASM capabilities.

## Operating Rules

- Each ticket must be independently understandable.
- Each ticket must include a clear definition of done.
- Each ticket must keep `bash scripts/smoke.sh` green.
- Runtime/product business logic must move toward Traverse-compatible contracts and WASM capability boundaries.
- Temporary harnesses are allowed only when they mimic the future Traverse boundary and are clearly marked as replaceable.
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

## First Ticket to Start

Recommended first implementation ticket:

> MVP-002: Define MVP Capability Contracts

Reason:

- It unblocks Traverse alignment.
- It unblocks the harness.
- It unblocks WASM capability implementation.
- It forces the product shape to become explicit.

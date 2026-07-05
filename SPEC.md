# youaskm3 — Project Specification

> Your knowledge, queryable. Open source MCP layer that turns everything you write, read, and save into a conversational interface.

**Domain:** youaskm3.com  
**Registry:** github.com/youaskm3/registry  
**Born:** Golden, BC — Purcell Mountains  
**Spec framework:** [OpenSpec](https://openspec.dev/)  
**Spec version:** 0.1.0  
**Status:** MVP specification reset

---

## 1. Vision

youaskm3 is an open source, WASM-native, MCP-powered personal knowledge product. It ingests everything you write, read, and save — books, white papers, blog posts, YouTube transcripts, articles, notes, and structured reasoning logs — and turns those files into a local-first chat experience grounded in user-owned markdown, search, chunk, and graph artifacts.

The system answers as *you*: in your voice, from your accumulated thinking. Its core product loop is not only retrieval over files; it is a second-brain reasoning loop where a persona works with an assistant to clarify concepts, challenge assumptions, record decisions, turn the resulting decision log into durable knowledge, update the graph, and defer back to the human when knowledge is missing, uncertain, or conflicting.

Anyone can fork it, fill it with their own knowledge, and run their own instance for free on GitHub Pages. Runtime business behavior is delegated to Traverse as governed WASM capabilities so the same application logic can run locally, on a server, or through MCP as Traverse placement improves. Instances can optionally federate through a shared registry, making knowledge discoverable across the network.

**Core promise:** no mandatory hosted service, no database, no lock-in. Git and local files are the infrastructure, chat is the product surface, and Traverse is the portable business-logic runtime.

---

## 2. Design Principles

1. **Specs are the source of truth.** Code, tests, and PRs must align with approved specs. A PR that drifts from spec fails review.
2. **WASM-first portability.** Business logic compiles to WASM and runs through Traverse across browser, edge, cloud, CLI, and MCP hosts. No host-specific shortcuts.
3. **Contracts before code.** Every capability is defined by an explicit contract before implementation begins.
4. **100% business logic test coverage.** No exceptions. Coverage is enforced in CI — a PR that drops coverage below 100% does not merge.
5. **Production quality from day one.** No prototype shortcuts in core paths. Quality standards apply from the first commit.
6. **Open by default.** Apache-2.0 licensed. Designed to be forked, extended, and contributed to.
7. **Git as infrastructure.** Knowledge store, registry, deployment, and history are all git-native. No mandatory external services required.
8. **UI-only product shell.** The PWA renders chat, sources, graph context, gaps, conflicts, and traces; it does not own retrieval, ranking, graph traversal, context packing, inference selection, answer validation, response formatting, gap lifecycle, graph extraction, or sync conflict policy.
9. **CLI as artifact and setup manager.** The CLI may convert files, normalize markdown, ingest decision-log packages, write artifacts, build, sync, serve, and register bundles; product semantics belong in Traverse-run capabilities.
10. **Reasoning logs are first-class knowledge.** Decision-log packages from LLM-agnostic reasoning skills are first-class inputs to the knowledge store and graph, with provenance, validation, and gap/conflict handling.

---

## 3. Technology Stack

### Core runtime
| Layer | Technology | Rationale |
|---|---|---|
| Business logic | **Rust → WASM** | Portable, safe, fast. Runs anywhere. |
| WASM runtime | **Wasmtime** (CLI/server) / **browser native** | Same module, different host |
| Runtime model | **Traverse v0.5.0 baseline / UMA** | Contract-driven, governed, explainable release surface for portable capabilities |
| MCP interface | **WASM MCP module** | Portable MCP server compiled to WASM |
| Runtime integration | **Traverse app bundle** | Registers capability contracts, event contracts, workflows, WASM packages, and model dependencies |

### Frontend
| Layer | Technology | Rationale |
|---|---|---|
| UI components | **Web Components** | Framework-agnostic, native browser standard |
| App shell | **PWA** | Offline-capable, installable, no native app needed |
| Scripting | **TypeScript** | Only where Rust/WASM does not make sense (glue, config, build) |
| Styling | **CSS custom properties** | Design tokens, no preprocessor dependency |

### Knowledge store
| Layer | Technology | Rationale |
|---|---|---|
| Format | **Markdown** | Human-readable, LLM-native, git-diffable |
| Conversion | **MarkItDown** | Default source-to-markdown conversion layer for supported office, PDF, and document formats |
| Chunks | **Static JSON + markdown refs** | Deterministic context units with source and section evidence |
| Graph | **Static JSON graph artifact** | Source-aware nodes and edges for graph-backed context |
| Reasoning packages | **Decision-log package directories** | `decision-log.md`, `knowledge-note.md`, and `metadata.json` from LLM-agnostic assistant reasoning sessions |
| Diagrams | **Mermaid** | Plain text, renders in GitHub, LLM-readable |
| Index | **Static JSON** | Generated at build time, no DB needed |
| Search | **WASM retrieval capability** | Runs through Traverse locally or remotely based on placement |
| Version control | **Git** | The only database you need |

### Tooling & infrastructure
| Layer | Technology |
|---|---|
| Spec management | OpenSpec (`openspec/specs/`) |
| CI/CD | GitHub Actions |
| Hosting | GitHub Pages |
| Package manager (JS) | npm |
| Build (Rust) | Cargo + `wasm-pack` |
| Linting (Rust) | `clippy` — zero warnings policy |
| Linting (TS) | ESLint + strict TypeScript |
| Formatting | `rustfmt` + Prettier |
| Test (Rust) | `cargo test` — 100% business logic coverage |
| Test (TS) | Vitest |
| Coverage enforcement | `cargo-llvm-cov` — fails below 100% |

---

## 4. Repository Structure

```
youaskm3/
├── openspec/
│   ├── specs/                  ← source of truth, versioned, immutable once approved
│   │   ├── knowledge-ingest/
│   │   │   └── spec.md
│   │   ├── knowledge-search/
│   │   │   └── spec.md
│   │   ├── knowledge-graph/
│   │   │   └── spec.md
│   │   ├── traverse-integration/
│   │   │   └── spec.md
│   │   ├── mcp-interface/
│   │   │   └── spec.md
│   │   ├── federation/
│   │   │   └── spec.md
│   │   └── pwa-shell/
│   │       └── spec.md
│   └── changes/                ← proposals, design docs, task breakdowns
│
├── crates/
│   ├── youaskm3-core/          ← pure Rust business logic, zero I/O
│   │   ├── src/
│   │   └── tests/              ← 100% coverage enforced
│   ├── youaskm3-search/        ← WASM vector search capability
│   ├── youaskm3-ingest/        ← content parsing and chunking
│   └── youaskm3-mcp/           ← WASM MCP server module
│
├── contracts/
│   ├── capabilities/           ← MVP product capability contracts
│   ├── markdown-artifact.schema.json
│   ├── knowledge-graph.schema.json
│   └── mcp-tools.json          ← MCP tool definitions as UMA contracts
│
├── tools/
│   ├── markitdown2m3/          ← MarkItDown → normalized markdown wrapper
│   ├── pdf2m3/                 ← legacy PDF → structured markdown converter
│   └── url2m3/                 ← URL/transcript → markdown ingester
│
├── app/
│   ├── components/             ← Web Components (TypeScript)
│   ├── pwa/                    ← PWA shell, service worker, manifest
│   └── site/                   ← GitHub Pages static site
│
├── knowledge/                  ← your actual content (md files)
│   ├── index.md                ← master map, auto-generated TOC
│   ├── books/
│   ├── papers/
│   ├── blog/
│   ├── gaps/                   ← structured markdown knowledge gaps
│   ├── conflicts/              ← structured markdown sync/semantic conflicts
│   ├── sources/decision-logs/  ← immutable imported reasoning packages
│   ├── notes/                  ← normalized derived knowledge notes
│   └── inputs/                 ← raw captures (transcripts, notes, links)
│
├── scripts/
│   ├── build.sh                ← full build pipeline
│   ├── test.sh                 ← run all tests with coverage
│   └── m3.sh                   ← CLI entry point
│
├── .github/
│   └── workflows/
│       ├── ci.yml              ← lint, test, coverage on every PR
│       ├── pages.yml           ← deploy to GitHub Pages on main
│       └── index.yml           ← nightly knowledge index rebuild
│
├── SPEC.md                     ← this file
├── README.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── LICENSE-MIT
├── LICENSE-APACHE
├── Cargo.toml                  ← workspace root
└── rust-toolchain.toml
```

---

## 5. Spec Governance (OpenSpec)

Specs live in `openspec/specs/`, organized by capability. Each spec is a markdown file following the OpenSpec format.

### Spec lifecycle

```
idea → /openspec:proposal → proposal.md + design.md + tasks.md + spec delta
     → review → approve → implement → PR → merge
```

### Rules

- Specs are versioned and immutable once approved.
- A PR must reference the spec it implements.
- A PR that drifts from the approved spec must update the spec first (new proposal cycle).
- Spec changes require explicit review — they are not incidental to code review.
- The spec is the contract. If code and spec disagree, the spec wins.

### Traverse integration baseline

youaskm3 integrates with Traverse through documented public release surfaces instead of private Traverse internals. The minimum approved first-MVP integration baseline for MVP-031 onward is Traverse `v0.5.0`, released on 2026-06-26, as described in [docs/traverse-mvp-requirements.md](docs/traverse-mvp-requirements.md):

- governed application bundle registration
- WASM component manifest validation
- WASM business capability execution
- atomic bundle registration
- evented workflow composition
- app-facing HTTP/JSON execution path
- MCP-facing execution path
- public traces for answer grounding
- local/server placement and model dependency resolution
- downstream app MVP conformance evidence through `bash scripts/ci/downstream_app_mvp_conformance.sh`
- public CLI app validation with `traverse-cli app validate --manifest <path> --json`
- public CLI local workspace app registration with `traverse-cli app register --manifest <path> --workspace <workspace-id> --json`

Roadmap work that touches runtime, MCP, browser hosting, model inference, or fork-and-run setup must pin an approved Traverse release pairing and include the relevant Traverse validation path.

### First-MVP user stories

The first-MVP personas, "As a..., I want..., so that..." stories, capability mappings, and demo acceptance path are maintained in [docs/mvp-user-stories.md](docs/mvp-user-stories.md). Runtime and UI work should map back to those stories when defining tickets, smoke tests, and demo evidence.

### Expanded first-MVP second-brain scope

The expanded first-MVP decisions are recorded in [docs/expanded-second-brain-mvp-decision-log.md](docs/expanded-second-brain-mvp-decision-log.md). These decisions are approved through the user's brainstorming process and define the first MVP as a reasoning-and-knowledge-cementing product, not generic chat over documents.

The approved additional OpenSpec surfaces are:

- [reasoning-assistant-skill](openspec/specs/reasoning-assistant-skill/spec.md): LLM-agnostic canonical skill and generated ChatGPT/Claude adapters.
- [decision-log-package](openspec/specs/decision-log-package/spec.md): package format, validation, CLI ingestion, provenance, and offline staging rules.
- [reasoning-graph](openspec/specs/reasoning-graph/spec.md): full reasoning graph extraction and answer-type context selection.
- [knowledge-gap-lifecycle](openspec/specs/knowledge-gap-lifecycle/spec.md): gaps, conflicts, direct fact resolution, and gap visibility.
- [local-runtime-sync](openspec/specs/local-runtime-sync/spec.md): `m3 init`, `m3 serve`, sync preflight, `m3 sync check`, and `m3 mvp-check`.

### Next product-led MVP tranche

After Traverse `v0.5.0` readiness and the first youaskm3 WASM capability tranche, the next highest-ROI work is tracked as MVP-031 through MVP-040 in [docs/mvp-ticket-backlog.md](docs/mvp-ticket-backlog.md):

- prove the local Traverse-backed chat happy path
- wire real WASM artifacts and component digests for implemented capabilities
- add a real imported-document question acceptance test
- enforce explicit Browser demo fallback semantics
- create a Traverse blocker escalation template for confirmed upstream gaps
- adopt the v0.5.0 public CLI app validation/registration baseline
- implement `knowledge.infer` as a real Traverse-governed WASM agent capability
- add the final first-MVP acceptance and release gate

These tickets keep youaskm3 product-led while using concrete app evidence to drive Traverse requirements. They must not add downstream runtime/provider shortcuts that bypass Traverse-governed WASM capability execution.

The expanded second-brain tranche is tracked as MVP-041 and later in [docs/mvp-ticket-backlog.md](docs/mvp-ticket-backlog.md). It does not replace MVP-031 through MVP-040; it layers the approved decision-log, reasoning graph, knowledge gap, sync, local runtime, and final expanded acceptance requirements on top of the existing Traverse-backed runtime baseline.

### Public hosted gap collector

Published GitHub Pages chat can browse and answer from public artifacts without a server, but low-friction external knowledge-gap capture requires a trusted write boundary. The approved minimal hosted surface is [hosted-gap-collector](openspec/specs/hosted-gap-collector/spec.md): an optional, narrow gap inbox backed by zero/near-zero-cost managed primitives such as Cloudflare Worker, D1, and Turnstile.

The collector stores pending external gap reports only. It does not answer questions, run inference, write to the local knowledge graph, or replace the local Traverse-backed runtime. The owner pulls, reviews, and imports accepted reports through the CLI so the user-owned local instance remains the source of truth.

### Post-first-MVP missing scope

The following surfaces are intentionally outside the first MVP but now have explicit future-scope specs and backlog tickets:

- [assistant-distribution](openspec/specs/assistant-distribution/spec.md): packaged ChatGPT, Claude, and future assistant distribution artifacts.
- [package-import-automation](openspec/specs/package-import-automation/spec.md): zip/archive ingestion and optional inbox/watch-folder processing.
- [semantic-quality-evaluation](openspec/specs/semantic-quality-evaluation/spec.md): claim-level partial ingestion and production answer benchmarks.
- [multi-persona](openspec/specs/multi-persona/spec.md): multiple personas, isolation, and shared scopes.
- [hosted-service](openspec/specs/hosted-service/spec.md): optional hosted accounts, teams, permissions, sync, and runtime services.
- [federated-answer](openspec/specs/federated-answer/spec.md): cross-instance search and answer flows beyond registry/index discovery.
- [wasm-native-model-evidence](openspec/specs/wasm-native-model-evidence/spec.md): proof requirements before claiming the model engine itself is WASM-native.

### Real runtime implementation rule

First-MVP runtime acceptance requires the real product/business implementation, not placeholders:

- deterministic product/business logic runs as real Rust/WASM microservice capabilities through Traverse
- judgement, generation, model-use, or planning behavior runs as real WASM agent capabilities through Traverse
- `knowledge.query.answer` is Traverse workflow composition, not a monolithic fake capability
- Browser demo and temporary harnesses are allowed only as explicit developer aids and never count as MVP acceptance evidence
- placeholder component manifests, all-zero digests, contract stubs, fake workflow steps, or skeleton runtime paths must fail acceptance
- when Traverse cannot run the required real workflow, the youaskm3 ticket is blocked and a detailed Traverse requirement is created instead of adding downstream workaround logic

### Local inference readiness

The first-MVP local inference policy is maintained in [docs/mvp-local-inference-policy.md](docs/mvp-local-inference-policy.md). Default CI and smoke must not require a live local LLM. Live local model conformance is opt-in with `TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1`, and missing inference capability must fail as a Traverse dependency failure rather than as hidden downstream fallback logic.

### Spec format (OpenSpec)

```markdown
# capability-name Specification

## Purpose
One paragraph. What this capability does and why it exists.

## Requirements

### Requirement: [name]
The system SHALL [behaviour].

#### Scenario: [name]
- GIVEN [precondition]
- WHEN [action]
- THEN [outcome]
```

---

## 6. Quality Standards

### Code quality

- **Zero warnings** — `clippy` and ESLint run in CI. Any warning fails the build.
- **Formatted** — `rustfmt` and Prettier enforced. Unformatted code fails CI.
- **No unsafe Rust** in business logic crates without explicit review and documentation.
- **No `unwrap()` or `expect()` in production paths** — all errors must be handled explicitly.
- **No `any` in TypeScript** — strict mode enforced.
- **Dependencies reviewed** before addition — supply chain hygiene matters.

### Test coverage

- **100% line and branch coverage for all `youaskm3-core` logic.**
- Coverage measured by `cargo-llvm-cov`. CI fails if coverage drops below 100%.
- Integration tests required for every MCP tool.
- Web Component tests run in browser via Vitest + browser mode.

### PR requirements (enforced by CI — PRs cannot merge without all passing)

```
✓ cargo fmt --check              (no formatting changes)
✓ cargo clippy -- -D warnings    (zero warnings)
✓ cargo test                     (all tests pass)
✓ cargo llvm-cov --fail-under=100 (100% business logic coverage)
✓ cargo build --target wasm32-wasip1 (WASM builds cleanly)
✓ npm run lint                   (ESLint passes)
✓ npm run typecheck              (TypeScript strict, no errors)
✓ npm test                       (all frontend tests pass)
✓ spec reference present         (PR description references a spec)
✓ spec delta attached if spec changed
```

### PR description template

```markdown
## What this changes
[One paragraph]

## Spec reference
openspec/specs/[capability]/spec.md — [requirement name]

## Spec delta (if spec changed)
[paste the spec diff here]

## Test coverage
[confirm: 100% maintained / new tests added for new behaviour]

## Lean ops / minimality
[confirm: used focused evidence, avoided broad dumps/logs, and applied the Minimality Ladder before adding code]

## Breaking changes
[none / describe]
```

---

## 7. Open Source Setup

### Licenses
Dual-licensed: **MIT** and **Apache-2.0**. Users choose.

### Required files
- `LICENSE-MIT`
- `LICENSE-APACHE`
- `README.md` — setup, quick start, how to run your own instance
- `CONTRIBUTING.md` — spec-first workflow, PR requirements, code standards
- `CODE_OF_CONDUCT.md` — Contributor Covenant
- `SECURITY.md` — responsible disclosure process
- `CITATION.cff` — academic citation format

### Contribution flow
1. Open an issue describing the capability or bug.
2. For new capabilities: run `/openspec:proposal` — produce proposal, design, tasks, spec delta.
3. Get spec approved before writing code.
4. Implement against the spec.
5. Open PR — CI enforces all quality gates.
6. Reviewer checks: spec alignment, test coverage, code quality, no regressions.
7. Merge.

---

## 8. Milestones

### MVP-1 — Spec and Contract Reset *(now)*
- [ ] README and SPEC describe the chat-first MVP.
- [ ] OpenSpec capabilities cover ingest, search, graph, PWA shell, MCP, and Traverse integration.
- [ ] MVP capability contracts exist for query, retrieval, graph expansion, context packing, inference, answer validation, and answer formatting.
- [ ] Markdown and graph artifact schemas are machine-checkable.
- [ ] Smoke validation checks the new specs and contracts.

### MVP-2 — Artifact Pipeline
- [ ] MarkItDown is the default source-to-markdown converter.
- [ ] Normalized markdown artifacts include stable ids, source metadata, conversion metadata, sections, chunks, and graph hints.
- [ ] Deterministic chunks are generated from processed markdown, not raw captures.
- [ ] A small fixture corpus validates search, graph, and chat flows without private content.
- [ ] `m3 build` and `m3 sync` produce the full static artifact set.

### MVP-3 — Search and Graph Evidence
- [ ] Search artifacts include source paths, chunk ids, excerpts, and deterministic scoring inputs.
- [ ] Graph artifacts include nodes, edges, source artifact ids, source chunk ids, labels, extraction method, confidence, and deterministic ordering.
- [ ] Retrieval and graph expansion run behind Traverse-compatible capability contracts.
- [ ] Empty, stale, and invalid artifact states return machine-readable failures.

### MVP-4 — UI-Only PWA Chat
- [ ] The PWA provides the first user-facing product: a local-first chat interface.
- [ ] Web Components render chat messages, source cards, graph evidence, and execution status.
- [ ] The PWA can call the real Traverse app-facing workflow for MVP acceptance.
- [ ] The PWA contains no retrieval, ranking, graph traversal, prompt construction, inference selection, or answer validation logic.

### MVP-5 — Traverse Runtime Integration
- [ ] The CLI registers a Traverse application bundle through public APIs.
- [ ] The bundle includes capability contracts, event contracts, workflows, WASM package manifests, binary digests, runtime constraints, and model dependencies.
- [ ] Traverse executes the same product workflow through app-facing HTTP/JSON and MCP surfaces.
- [ ] Execution traces include capability versions, placement, source evidence, graph evidence, inference dependency, validation outcome, and failure reasons.

### MVP-6 — Local-First Inference Through Traverse
- [ ] `knowledge.infer` declares inference needs by contract instead of hardcoding a provider.
- [ ] Traverse can resolve and run a compatible governed local inference capability or provider when available.
- [ ] Traverse can choose a server-side inference capability when allowed and available.
- [ ] Missing inference capability fails clearly before user-facing execution begins.
- [ ] If the model engine itself is not yet WASM-native, the release notes and readiness checks state that caveat explicitly while preserving the Traverse-governed dependency boundary.

### Later — Fork, Federation, and Network Effects
- [ ] One-command setup documented in README with a target under 15 minutes.
- [ ] `youaskm3.com` serves the author's public instance.
- [ ] Optional hosted gap collector supports low-friction public gap submissions without browser secrets or full hosted youaskm3 accounts.
- [ ] Federation registry and cross-instance search remain separate from the first MVP.

---

## 9. MCP Tools (initial set)

Defined as UMA contracts in `contracts/mcp-tools.json`; MVP product capabilities are defined separately under `contracts/capabilities/` and exposed through Traverse app-facing and MCP surfaces.

| Tool | Description |
|---|---|
| `search` | Semantic + keyword hybrid search across all indexed knowledge |
| `remember` | Ingest and index new content (text, URL, file) |
| `recall` | Retrieve content by topic, date, source, or tag |
| `connect` | Surface connections between concepts across the knowledge base |
| `list_sources` | List all indexed sources with metadata |
| `status` | Report index status, last sync, coverage |

## 10. MVP Product Capabilities

The first chat workflow is composed from these product-level capability contracts:

| Capability | Description |
|---|---|
| `knowledge.query.answer` | User-facing workflow entrypoint that returns a grounded answer envelope |
| `knowledge.retrieve` | Source-aware retrieval over prepared search and chunk artifacts |
| `knowledge.graph.expand` | Graph context expansion from retrieved chunks, topics, or cited nodes |
| `knowledge.context.pack` | Deterministic context construction within model limits |
| `knowledge.infer` | Model inference dependency resolved and placed by Traverse |
| `knowledge.answer.validate` | Grounding, citation, and failure validation |
| `knowledge.answer.format` | Final response shaping for chat and MCP clients |

All seven capabilities must run as governed WASM capabilities or WASM agents through Traverse for the MVP runtime. Temporary local harnesses and Browser demo paths are developer aids only and do not count as MVP acceptance evidence.

---

## 11. Knowledge Structure

```
knowledge/
├── index.md              ← auto-generated master map
├── books/
│   └── [book-title]/
│       ├── index.md      ← chapter map + summaries
│       ├── ch01-*.md
│       ├── ch02-*.md
│       └── diagrams/
│           └── fig1.mmd  ← Mermaid source
├── papers/
│   └── [paper-title]/
│       ├── index.md
│       └── sections/
├── blog/
│   └── [post-slug].md
└── inputs/               ← raw captures, not yet processed
    ├── transcripts/
    ├── articles/
    └── notes/
```

### File size targets (for LLM context efficiency)
- Per chapter/section file: 2,000–4,000 tokens
- Index files: under 1,000 tokens
- Mermaid diagram files: plain text, no size limit

---

## 12. Federation Protocol

### Instance registration
An instance joins the federation by opening a PR to `youaskm3/registry` adding one JSON entry to `instances.json`:

```json
{
  "name": "Enrico Piovesan",
  "url": "youaskm3.com",
  "topics": ["WASM", "UMA", "distributed systems", "architecture"],
  "description": "Author of Universal Microservices Architecture",
  "since": "2026-04-01"
}
```

### Registry rules
- Instance must be publicly accessible.
- Instance must be running a valid youaskm3 fork.
- The registry maintainer (author) approves PRs.
- Instances can be removed by PR or by the maintainer if they go offline.

### Cross-instance index
A nightly GitHub Action in `youaskm3/registry`:
1. Fetches `index.json` from each registered instance.
2. Merges into a global `search-index.json`.
3. Commits to registry repo — served as static file.
4. `youaskm3.com/explore` loads this file client-side.

---

## 13. CLI Reference (`m3`)

```bash
m3 init                  # interactive setup for new instance
m3 add <file|url>        # ingest content into knowledge base
m3 build                 # full rebuild: index + WASM + site
m3 sync                  # incremental sync (changed files only)
m3 search <query>        # query from CLI
m3 status                # show index status and coverage
m3 serve                 # local dev server
```

---

## 14. Non-Goals

The following are explicitly out of scope for v1.0:

- Paid hosting or managed service
- Native mobile apps (PWA covers this)
- Real-time collaboration (git is async by design)
- Analytics or telemetry
- Authentication / access control beyond GitHub's own model
- Support for proprietary document formats beyond PDF conversion

---

*This document is the source of truth for youaskm3. All implementation must trace back to a spec in `openspec/specs/`. When this document and a spec disagree, update both and open a proposal.*

*Last updated: 2026-04-01*

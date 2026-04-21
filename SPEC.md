# youaskm3 — Project Specification

> Your knowledge, queryable. Open source MCP layer that turns everything you write, read, and save into a conversational interface.

**Domain:** youaskm3.com  
**Registry:** github.com/youaskm3/registry  
**Born:** Golden, BC — Purcell Mountains  
**Spec framework:** [OpenSpec](https://openspec.dev/)  
**Spec version:** 0.1.0  
**Status:** Foundation

---

## 1. Vision

youaskm3 is an open source, WASM-native, MCP-powered personal knowledge layer. It ingests everything you write, read, and save — books, white papers, blog posts, YouTube transcripts, articles, notes — and makes it all queryable via any LLM or chat interface.

The system answers as *you*: in your voice, from your accumulated thinking.

Anyone can fork it, fill it with their own knowledge, and run their own instance for free on GitHub Pages. Instances can optionally federate through a shared registry, making knowledge discoverable across the network.

**Core promise:** no server, no database, no cost, no lock-in. Git is the infrastructure.

---

## 2. Design Principles

1. **Specs are the source of truth.** Code, tests, and PRs must align with approved specs. A PR that drifts from spec fails review.
2. **WASM-first portability.** Business logic compiles to WASM and runs identically in browser, edge, cloud, and CLI. No host-specific shortcuts.
3. **Contracts before code.** Every capability is defined by an explicit contract before implementation begins.
4. **100% business logic test coverage.** No exceptions. Coverage is enforced in CI — a PR that drops coverage below 100% does not merge.
5. **Production quality from day one.** No prototype shortcuts in core paths. Quality standards apply from the first commit.
6. **Open by default.** Apache-2.0 licensed. Designed to be forked, extended, and contributed to.
7. **Git as infrastructure.** Knowledge store, registry, deployment, and history are all git-native. No external services required.

---

## 3. Technology Stack

### Core runtime
| Layer | Technology | Rationale |
|---|---|---|
| Business logic | **Rust → WASM** | Portable, safe, fast. Runs anywhere. |
| WASM runtime | **Wasmtime** (CLI/server) / **browser native** | Same module, different host |
| Runtime model | **Traverse v0.1 / UMA** | Contract-driven, governed, explainable release surface |
| MCP interface | **WASM MCP module** | Portable MCP server compiled to WASM |

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
| Diagrams | **Mermaid** | Plain text, renders in GitHub, LLM-readable |
| Index | **Static JSON** | Generated at build time, no DB needed |
| Search | **WASM vector search** | Runs client-side, no server |
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
│   └── mcp-tools.json          ← MCP tool definitions as UMA contracts
│
├── tools/
│   ├── pdf2m3/                 ← PDF → structured markdown converter
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

youaskm3 integrates with Traverse through documented public release surfaces instead of private Traverse internals. The current baseline is the Traverse v0.1 app-consumable release path:

- versioned consumer bundle: Traverse `docs/app-consumable-consumer-bundle.md`
- browser-hosted path: Traverse browser consumer package and browser adapter docs
- MCP-facing path: Traverse `traverse-mcp` stdio server and MCP library surface
- validation path: Traverse `youaskm3` integration, compatibility conformance, published artifact, and real shell validation scripts

Roadmap work that touches runtime, MCP, browser hosting, or fork-and-run setup must pin an approved Traverse release pairing and include the relevant Traverse validation path.

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

### M0 — Foundation *(now)*
- [ ] Repo created: `github.com/youaskm3/youaskm3`
- [ ] This SPEC.md committed as the root document
- [ ] OpenSpec installed and configured
- [ ] `openspec/specs/` directory seeded with initial capability specs
- [ ] CI skeleton: lint, test, coverage, WASM build
- [ ] LICENSE-MIT, LICENSE-APACHE, README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY
- [ ] Cargo workspace with `youaskm3-core` stub
- [ ] rust-toolchain.toml pinned
- [ ] youaskm3.com domain connected to GitHub Pages

### M1 — Knowledge layer *(v0.1)*
- [ ] Spec: `openspec/specs/knowledge-ingest/spec.md`
- [ ] `pdf2m3` tool: PDF → structured markdown with chapter chunking
- [ ] Mermaid diagram generation from visual PDF pages (via Claude API)
- [ ] `url2m3` tool: URL/transcript → markdown
- [ ] `knowledge/index.md` auto-generated from content
- [ ] `youaskm3-ingest` crate: 100% coverage
- [ ] Author's books, white papers, blog posts ingested as first content

### M2 — WASM MCP core *(v0.2)*
- [ ] Spec: `openspec/specs/mcp-interface/spec.md`
- [ ] `contracts/mcp-tools.json` — UMA contracts for all MCP tools
- [ ] `youaskm3-search` crate: WASM vector search
- [ ] Traverse v0.1 release pairing pinned for runtime, browser consumer, and MCP surfaces
- [ ] `youaskm3-mcp` crate acts as a thin integration adapter over the supported Traverse MCP/library surface where possible
- [ ] MCP tools: `search`, `remember`, `recall`, `connect` mapped to contract-defined Traverse-compatible tool semantics
- [ ] Runs through documented Traverse MCP/CLI validation paths before claiming browser, CLI, or edge compatibility
- [ ] Built on the Traverse v0.1 app-consumable runtime model, not a bespoke runtime fork
- [ ] 100% test coverage on all crates

### M3 — Chat interface *(v0.3)*
- [ ] Spec: `openspec/specs/pwa-shell/spec.md`
- [ ] PWA shell: installable, offline-capable
- [ ] Web Components: `<m3-chat>`, `<m3-result>`, `<m3-source>`
- [ ] Browser-hosted runtime path consumes the Traverse browser consumer package/adapter or its approved release successor
- [ ] WASM/MCP behavior is validated through the Traverse `youaskm3` real shell validation path
- [ ] youaskm3.com serves author's instance
- [ ] Claude API integration (configurable key)
- [ ] Works with any MCP-compatible LLM

### M4 — Fork and run your own *(v0.4)*
- [ ] `m3 init` — interactive setup for new instances
- [ ] `m3 build` — generates index, compiles WASM, prepares site
- [ ] `m3 sync` — incremental re-index on content changes
- [ ] GitHub Actions template included in repo
- [ ] Traverse release pairing and compatibility conformance commands documented for forked instances
- [ ] One-command setup documented in README
- [ ] Setup time target: under 15 minutes

### M5 — Federation *(v1.0)*
- [ ] Spec: `openspec/specs/federation/spec.md`
- [ ] `github.com/youaskm3/registry` repo created
- [ ] `instances.json` format defined
- [ ] PR-based join process documented
- [ ] Explore page at youaskm3.com (`/explore`)
- [ ] Browse by topic across registered instances
- [ ] Nightly GitHub Action: crawl registered instances, build cross-instance index
- [ ] Cross-instance search (client-side fan-out)

---

## 9. MCP Tools (initial set)

Defined as UMA contracts in `contracts/mcp-tools.json`.

| Tool | Description |
|---|---|
| `search` | Semantic + keyword hybrid search across all indexed knowledge |
| `remember` | Ingest and index new content (text, URL, file) |
| `recall` | Retrieve content by topic, date, source, or tag |
| `connect` | Surface connections between concepts across the knowledge base |
| `list_sources` | List all indexed sources with metadata |
| `status` | Report index status, last sync, coverage |

---

## 10. Knowledge Structure

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

## 11. Federation Protocol

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

## 12. CLI Reference (`m3`)

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

## 13. Non-Goals

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

<img width="100%" alt="youaskm3 — your knowledge, queryable" src="https://github.com/user-attachments/assets/1bcb40f2-03cf-455c-8360-7e100b795b15" />
# youaskm3


[![CI](https://github.com/enricopiovesan/youaskm3/actions/workflows/ci.yml/badge.svg)](https://github.com/enricopiovesan/youaskm3/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/enricopiovesan/youaskm3/actions/workflows/ci.yml)
[![Spec Governed](https://img.shields.io/badge/spec-governed-blueviolet)](openspec/specs/)
[![License](https://img.shields.io/badge/license-MIT%20%7C%20Apache--2.0-blue)](LICENSE-APACHE)
[![Rust](https://img.shields.io/badge/rust-1.94%2B-orange)](https://www.rust-lang.org/)
[![Built on Traverse](https://img.shields.io/badge/built%20on-Traverse-black)](https://github.com/enricopiovesan/Traverse)


**your knowledge, queryable**

youaskm3 is an open source, WASM-native, MCP-powered personal knowledge product for turning your books, papers, notes, and source material into a local-first chat experience you can query, inspect, fork, and evolve in the open.

It is designed on top of [Traverse](https://github.com/enricopiovesan/Traverse) and the broader [Universal Microservices Architecture](https://github.com/enricopiovesan/UMA-code-examples) direction: portable capability contracts, governed specs, and runtime surfaces that stay usable across tools and hosts.

## Why This Exists

Most personal knowledge tooling locks your context inside closed products, hosted backends, or app-specific interfaces. youaskm3 takes the opposite path:

- your knowledge stays in files you control
- your workflows stay visible in specs, scripts, and contracts
- your runtime path stays portable through WASM and MCP-friendly surfaces
- your project stays forkable by humans and workable by coding agents

## Core Use

youaskm3 is for people who want to:

- ingest source material like PDFs, DOCX files, slides, notes, and articles into a git-tracked knowledge base
- prepare markdown, chunk, search, and graph artifacts that can be queried by the chat product
- run a strict, deterministic development workflow with CI, coverage, and spec gates
- build an agent-friendly repo where humans and coding agents can work from the same source of truth

## What Works Today

If you clone this repository right now, you can:

- run the full repo validation path with `bash scripts/smoke.sh`
- lint, test, and build the Rust and TypeScript workspace from repo root
- initialize a local instance with `./scripts/m3.sh init`
- ingest a PDF or URL into the knowledge structure with `./scripts/m3.sh add`
- generate static knowledge artifacts and WASM builds with `./scripts/m3.sh build`
- refresh generated artifacts incrementally with `./scripts/m3.sh sync`
- query the generated local search index with `./scripts/m3.sh search <query>`
- serve the static PWA shell locally with `./scripts/m3.sh serve [port]`
- inspect and extend the current Rust crates for `core`, `ingest`, `search`, and `mcp`
- work against real OpenSpec contracts and CI gates instead of placeholders

## What Is Still Missing

This repository is not yet a finished end-user product. The main gaps today are:

- no finished end-user chat loop over Traverse-run WASM capabilities
- no production graph artifact generator yet
- no finished local LLM/inference capability delegated through Traverse yet
- no finished fork-and-run onboarding path for a brand-new user in under 15 minutes
- no complete federation explore experience
- no full cross-instance search fan-out flow
- no claim yet that the full MCP-powered knowledge experience is production-ready

The repo is ready for development today. The complete product experience is still being built milestone by milestone.

## Quick Start For Developers

```bash
git clone https://github.com/enricopiovesan/youaskm3.git
cd youaskm3

npm install
bash scripts/smoke.sh
```

For the exact local toolchain, including Rust `1.94.0`, `wasm32-wasip1`,
`cargo-llvm-cov`, Python 3.10+ for MarkItDown, and the known-good smoke command,
see [docs/local-development-toolchain.md](docs/local-development-toolchain.md).

If you want a smaller first pass:

```bash
bash scripts/lint.sh
bash scripts/test.sh
bash scripts/build.sh
```

## First Developer Flow

Use this path if you want to start contributing right away:

1. Read [SPEC.md](SPEC.md).
2. Read [CONTRIBUTING.md](CONTRIBUTING.md).
3. Review the governing capability specs in [openspec/specs/](openspec/specs/).
4. Run `bash scripts/smoke.sh`.
5. Make the smallest spec-backed change possible.

## First Agent Flow

If you are using Codex, Claude Code, or another coding agent, start here:

1. Read [SPEC.md](SPEC.md) before making changes.
2. Use [CONTRIBUTING.md](CONTRIBUTING.md) as the workflow contract.
3. Treat [openspec/specs/](openspec/specs/) as the implementation source of truth.
4. Use [contracts/mcp-tools.json](contracts/mcp-tools.json) for the current MCP surface contract.
5. Validate changes with `bash scripts/smoke.sh` before opening a PR.

This repo is intentionally structured so humans and agents can navigate the same files, rules, and validation commands without hidden context.

## Key Entry Points

| Goal | Start Here |
|---|---|
| Understand the project contract | [SPEC.md](SPEC.md) |
| Learn contribution rules | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Review active capability specs | [openspec/specs/](openspec/specs/) |
| Review current MCP contracts | [contracts/mcp-tools.json](contracts/mcp-tools.json) |
| Review MVP capability contracts | [contracts/capabilities/](contracts/capabilities/) |
| Set up local validation tools | [docs/local-development-toolchain.md](docs/local-development-toolchain.md) |
| Start or resume ops workflow | [docs/youaskm3-ops.md](docs/youaskm3-ops.md) |
| Inspect the repo command surface | [scripts/m3.sh](scripts/m3.sh) |
| Run the full validation path | [scripts/smoke.sh](scripts/smoke.sh) |
| Check Traverse v0.4.0 readiness | [scripts/traverse-readiness.sh](scripts/traverse-readiness.sh) |
| Update Traverse component manifests | [scripts/traverse-component-manifests.sh](scripts/traverse-component-manifests.sh) |
| Review current knowledge layout | [knowledge/index.md](knowledge/index.md) |

## Command Surface Today

The current repo-level command entrypoint is:

```bash
./scripts/m3.sh {init|add|build|sync|search|serve|test|lint|smoke|status}
```

Available now:

- `m3 init` bootstraps local instance metadata and knowledge scaffolding
- `m3 add` routes PDF and URL ingest into the knowledge structure
- `m3 build` generates static knowledge artifacts and validates native plus `wasm32-wasip1` builds
- `m3 sync` refreshes generated artifacts without forcing a full rebuild every time
- `m3 search <query>` queries the generated local search index from the CLI
- `m3 serve [port]` serves the static PWA shell from `app/site` for local inspection
- `m3 smoke` runs the full repository validation path

Traverse integration readiness is checked with:

```bash
bash scripts/traverse-readiness.sh
```

By default it looks for a sibling Traverse checkout at `../Traverse`. Set `TRAVERSE_REPO=/path/to/Traverse` when the checkout lives somewhere else. Set `TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE=1` only when the local model provider must be reachable during readiness validation.

Traverse component manifests are checked with:

```bash
bash scripts/traverse-component-manifests.sh --skeleton --check
```

Omit `--skeleton` when real capability WASM binaries are expected. In that mode the command fails if a referenced binary is missing and writes SHA-256 digests from the actual `.wasm` files.

## Project Standards

This project is set up like a production-minded open source repository:

- spec-governed changes
- zero-warning Rust quality gates
- 100% business-logic coverage enforcement
- strict TypeScript settings
- executable validation scripts from repo root
- CI-ready workflows for build, coverage, pages, and index tasks

## Built On Traverse and UMA

youaskm3 is not an isolated experiment. It sits in a larger line of work:

- [Traverse](https://github.com/enricopiovesan/Traverse) provides the portable runtime and integration baseline
- [UMA code examples](https://github.com/enricopiovesan/UMA-code-examples) provide the broader architectural direction and reference patterns

Traverse answers the runtime question. youaskm3 applies that model to personal knowledge.

For the first MVP, the boundary is strict:

- `youaskm3` CLI owns source discovery, MarkItDown-backed conversion, normalization, artifact writing, build/sync, and local serving.
- `Traverse` owns runtime execution of product/business behavior as governed WASM capabilities or agents.
- The PWA owns UI only: chat input, rendering answers, rendering sources, graph views, and execution status.
- Query planning, retrieval ranking, graph traversal, context packing, inference selection, answer grounding, and response formatting are capability contracts, not browser or CLI shortcuts.

## Roadmap

| Milestone | Focus |
|---|---|
| MVP-1 | Spec and contract reset around local-first chat, Traverse runtime boundaries, and artifact schemas |
| MVP-2 | MarkItDown default conversion, normalized markdown artifacts, deterministic chunks, and fixture corpus |
| MVP-3 | Search and graph artifact generation with source and chunk evidence |
| MVP-4 | UI-only PWA chat shell wired to a temporary Traverse-compatible runtime harness |
| MVP-5 | Traverse application bundle registration and real WASM capability execution |
| MVP-6 | Local/server inference capability delegated through Traverse placement and dependency resolution |
| Later | Fork-and-run polish, federation, cross-instance search, and registry workflows |

Roadmap source: [SPEC.md](SPEC.md#8-milestones) and [GitHub Project 3](https://github.com/users/enricopiovesan/projects/3).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md) before opening a PR.

## License

Dual licensed under [MIT](LICENSE-MIT) and [Apache-2.0](LICENSE-APACHE).


## Related Work

- [Traverse](https://github.com/enricopiovesan/Traverse)
- [Universal Microservices Architecture — Book](https://www.amazon.com/dp/B0GTTTTQH4)
- [Contract-Driven AI Development (C-DAD) — White Paper](https://drive.google.com/file/d/1HC_ZWJl9aYaMeN78qiL3ZYBVY7mAGl3f/view)
- [Speaking](https://enricopiovesan.github.io/enricopiovesan/)
- [github.com/enricopiovesan](https://github.com/enricopiovesan)

[![CI](https://github.com/enricopiovesan/youaskm3/actions/workflows/ci.yml/badge.svg)](https://github.com/enricopiovesan/youaskm3/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/enricopiovesan/youaskm3/actions/workflows/ci.yml)
[![Spec Governed](https://img.shields.io/badge/spec-governed-blueviolet)](openspec/specs/)
[![License](https://img.shields.io/badge/license-MIT%20%7C%20Apache--2.0-blue)](LICENSE-APACHE)
[![Rust](https://img.shields.io/badge/rust-1.94%2B-orange)](https://www.rust-lang.org/)
[![Built on Traverse](https://img.shields.io/badge/built%20on-Traverse-black)](https://github.com/enricopiovesan/Traverse)

# youaskm3

**your knowledge, queryable**

youaskm3 is an open source, WASM-native, MCP-powered personal knowledge project for turning your books, papers, notes, and source material into something you can query, inspect, fork, and evolve in the open.

It is designed on top of [Traverse](https://github.com/enricopiovesan/Traverse) and the broader [Universal Microservices Architecture](https://github.com/enricopiovesan/UMA-code-examples) direction: portable capability contracts, governed specs, and runtime surfaces that stay usable across tools and hosts.

## Why This Exists

Most personal knowledge tooling locks your context inside closed products, hosted backends, or app-specific interfaces. youaskm3 takes the opposite path:

- your knowledge stays in files you control
- your workflows stay visible in specs, scripts, and contracts
- your runtime path stays portable through WASM and MCP-friendly surfaces
- your project stays forkable by humans and workable by coding agents

## Core Use

youaskm3 is for people who want to:

- ingest source material like PDFs into a git-tracked knowledge base
- prepare knowledge artifacts that can later be queried through MCP-capable clients
- run a strict, deterministic development workflow with CI, coverage, and spec gates
- build an agent-friendly repo where humans and coding agents can work from the same source of truth

## Current Scope

This repository already gives you:

- a Rust workspace for `core`, `ingest`, `search`, and `mcp` crates
- strict TypeScript tooling for frontend and validation work
- OpenSpec contracts for ingest, search, MCP, federation, and PWA behavior
- smoke, lint, test, coverage, and WASM build validation from repo root
- the first `m3` command surface for add, build, lint, test, smoke, and status flows

## Quick Start

```bash
git clone https://github.com/enricopiovesan/youaskm3.git
cd youaskm3

npm install
bash scripts/smoke.sh
```

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
| Inspect the repo command surface | [scripts/m3.sh](scripts/m3.sh) |
| Run the full validation path | [scripts/smoke.sh](scripts/smoke.sh) |
| Review current knowledge layout | [knowledge/index.md](knowledge/index.md) |

## Command Surface

The current repo-level command entrypoint is:

```bash
./scripts/m3.sh {add|build|test|lint|smoke|status}
```

Current highlights:

- `m3 add` routes PDF ingest into the knowledge structure
- `m3 build` validates native and `wasm32-wasip1` builds
- `m3 smoke` runs the full repository validation path

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

## Roadmap

| Milestone | Focus |
|---|---|
| M1 | Knowledge ingest and indexing |
| M2 | WASM MCP core and contracts |
| M3 | PWA chat shell |
| M4 | Fork-and-run workflow |
| M5 | Federation and registry |

Roadmap source: [SPEC.md](SPEC.md#8-milestones) and [GitHub Project 3](https://github.com/users/enricopiovesan/projects/3).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md) before opening a PR.

## License

Dual licensed under [MIT](LICENSE-MIT) and [Apache-2.0](LICENSE-APACHE).

# youaskm3

your knowledge, queryable

youaskm3 is an open source, WASM-native, MCP-powered personal knowledge layer that ingests what you write, read, and save, then makes that knowledge queryable through conversational interfaces while preserving a git-native, zero-server deployment model.

## Why this exists

Most personal knowledge tooling traps context inside proprietary silos, hosted backends, or interfaces that do not travel with the author. youaskm3 exists to give people an open, portable layer they can fork, host, inspect, and evolve so their books, papers, notes, articles, and transcripts stay in plain text and remain usable through any MCP-capable client.

## Quick start

> Coming in M4. This milestone prepares the repository, specs, toolchain, and validation flow so a future contributor can implement the one-command setup path with confidence.

## How it works

The system keeps specs in `openspec/specs/`, business logic in Rust crates that compile to `wasm32-wasip1`, frontend glue in strict TypeScript, and knowledge artifacts in markdown and static indexes tracked by git. A future `m3` workflow will ingest content into `knowledge/`, generate indexes at build time, and expose that knowledge through a WASM MCP module that can run in the browser, CLI, or other hosts.

## Milestones

| Milestone | Focus | Status |
|---|---|---|
| M0 | Foundation: specs, repo layout, CI, workspace, open source setup | In progress |
| M1 | Knowledge ingest and indexing | Planned |
| M2 | WASM MCP core and contracts | Planned |
| M3 | PWA chat shell | Planned |
| M4 | Fork-and-run workflow | Planned |
| M5 | Federation and registry | Planned |

Roadmap source: [SPEC.md](SPEC.md#8-milestones) and [GitHub Project 3](https://github.com/users/enricopiovesan/projects/3).

## Stack

| Layer | Technology |
|---|---|
| Business logic | Rust to WASM |
| MCP interface | WASM MCP module |
| Runtime model | Traverse / UMA |
| UI | Web Components + PWA shell |
| Scripting | TypeScript |
| Knowledge format | Markdown + Mermaid + static JSON |
| Hosting | GitHub Pages |
| CI/CD | GitHub Actions |
| Spec management | OpenSpec |

## Contributing

Start with [CONTRIBUTING.md](CONTRIBUTING.md). The repo follows a spec-first workflow and treats approved specs as the contract for implementation.

## License

This project is dual licensed under [MIT](LICENSE-MIT) and [Apache-2.0](LICENSE-APACHE).

## Born in the Purcells

youaskm3 began in Golden, British Columbia, in the Purcell Mountains, where the idea of a portable personal knowledge layer became concrete enough to build in public.

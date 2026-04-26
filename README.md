<img width="1434" height="944" alt="Screenshot 2026-04-01 at 10 12 08 PM" src="https://github.com/user-attachments/assets/6127686f-e00c-458e-b108-26679f4b2ddc" />

# youaskm3


your knowledge, queryable

youaskm3 is an open source, WASM-native, MCP-powered personal knowledge layer that ingests what you write, read, and save, then makes that knowledge queryable through conversational interfaces while preserving a git-native, zero-server deployment model.

## Why this exists

Most personal knowledge tooling traps context inside proprietary silos, hosted backends, or interfaces that do not travel with the author. youaskm3 exists to give people an open, portable layer they can fork, host, inspect, and evolve so their books, papers, notes, articles, and transcripts stay in plain text and remain usable through any MCP-capable client.

## Quick start

The first M4 slice now bootstraps local instance metadata and knowledge scaffolding:

```bash
./scripts/m3.sh init --name "Your Instance" --shell-url "https://example.com/your-instance/" --yes
```

That command initializes `app/site/author-instance.json`, `app/site/provider-config.json`, and the tracked `knowledge/` layout. The full fork-and-run flow, including `m3 build` and `m3 sync`, continues in later M4 tickets.

## PWA shell validation

The current M3 slice ships an installable static shell under `app/site/`. To validate it locally:

- run `bash scripts/pwa-shell-smoke.sh`
- serve `app/site/` with a static file server such as `python3 -m http.server --directory app/site 4173`
- open the served page in a browser and confirm the manifest and standalone shell are recognized
- switch between provider profiles in the shell and confirm the selection persists in the browser
- inspect `app/site/author-instance.json` and `app/site/provider-config.json` to verify what would be published with the static author instance

## Provider configuration

The current M3 provider slice keeps deployment static and portable:

- `app/site/provider-config.json` defines the selectable provider profiles for the browser shell
- `app/site/author-instance.json` defines the published author-instance metadata that ships with the static site
- the browser demo profile remains the default publishable option, while hosted APIs stay explicit opt-in profiles that require user-supplied credentials in-browser

## How it works

The system keeps specs in `openspec/specs/`, business logic in Rust crates that compile to `wasm32-wasip1`, frontend glue in strict TypeScript, and knowledge artifacts in markdown and static indexes tracked by git. A future `m3` workflow will ingest content into `knowledge/`, generate indexes at build time, and expose that knowledge through the approved Traverse v0.1 app-consumable runtime, browser consumer, and MCP release surfaces.

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
| Runtime model | Traverse v0.1 / UMA |
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

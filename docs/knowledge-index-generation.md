# Knowledge Index Generation

This document defines the M1 index generation flow for `knowledge/index.md`. It is intentionally a contract before a full implementation: generated search artifacts must follow this shape so later Rust, CLI, and MCP work can depend on stable repository semantics.

## Inputs

The generator reads processed markdown artifacts from these directories:

| Directory | Included in search index | Notes |
|---|---:|---|
| `knowledge/books/` | yes | Book directories use a local `index.md` plus chapter files such as `ch01-*.md`. |
| `knowledge/papers/` | yes | Paper directories use a local `index.md` and optional section files. |
| `knowledge/blog/` | yes | Blog posts are single markdown files named by slug. |
| `knowledge/inputs/` | no | Raw captures stay pending until an ingest tool promotes them into a processed category. |

Each processed artifact must preserve source traceability in markdown metadata or a `## Source` section. The first supported promotion path is `tools/pdf2m3/pdf2m3.sh`, which renders PDF text into structured markdown suitable for `knowledge/papers/` or `knowledge/books/`.

## Outputs

The generator owns the managed section in `knowledge/index.md` between:

```md
<!-- youaskm3:index:start -->
<!-- youaskm3:index:end -->
```

The managed section contains:

| Section | Content |
|---|---|
| Summary | Counts for processed books, papers, blog posts, and pending raw inputs. |
| Books | Stable links to each book directory index. |
| Papers | Stable links to each paper directory index. |
| Blog | Stable links to each blog markdown file. |
| Pending Inputs | Counts and paths for raw captures that still need ingest. |

Ordering is deterministic: category order is books, papers, blog, then pending inputs; entries inside each category sort by repository-relative path using bytewise ascending order.

## Trigger Points

Index generation runs in three places:

| Trigger | Expected behavior |
|---|---|
| Local ingest | `m3 add` promotes content, then refreshes `knowledge/index.md` before returning. |
| Pull request validation | CI verifies the managed index is current once the generator exists. |
| Nightly rebuild | `.github/workflows/index.yml` refreshes derived knowledge artifacts on `main`. |

Until the generator is implemented, contributors must update the managed section manually when adding processed knowledge artifacts. Manual edits should follow the same ordering and source-traceability rules so the later generator can adopt the file without churn.

## Incremental Sync Rules

`m3 build` remains the full preparation path: it refreshes generated site artifacts and recompiles the Rust workspace for native and `wasm32-wasip1` targets.

`m3 sync` is the incremental path for already-initialized instances:

| Change | `m3 sync` behavior | Full rebuild required |
|---|---|---:|
| Processed markdown added, removed, or edited under `knowledge/books/`, `knowledge/papers/`, or `knowledge/blog/` | Recompute `app/site/search-index.json`, `app/site/build-manifest.json`, and `app/site/sync-state.json` | no |
| Raw captures added or removed under `knowledge/inputs/` | Refresh counts and tracked pending-input paths in generated site artifacts | no |
| `app/site/author-instance.json` changes | Refresh generated site artifacts so published metadata stays aligned | no |
| Rust code, frontend shell code, or dependency changes | `m3 sync` does not rebuild binaries or static shell assets | yes |

The incremental path is deterministic: it compares the current source fingerprint to the last generated `app/site/sync-state.json` and only rewrites artifacts when tracked inputs change. The sync state records every source path and content hash so later validations can trace exactly which files fed a generated artifact set.

## Non-Goals

This M1 flow does not define vector embeddings, federation-wide index exchange, browser storage, or MCP search execution. Those belong to later `knowledge-search`, `federation`, and `mcp-interface` implementation tickets.

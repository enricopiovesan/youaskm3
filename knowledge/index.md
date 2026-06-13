# Knowledge Index

This directory is the source-controlled knowledge store for a youaskm3 instance. It will hold authored content, imported material, and generated indexes in plain markdown so the repository remains inspectable, portable, and reviewable.

## Categories

| Category | Purpose |
|---|---|
| `books/` | Long-form book-derived knowledge, chapter maps, and diagrams |
| `papers/` | White papers and sectioned research notes |
| `blog/` | Blog posts and shorter written artifacts |
| `inputs/` | Raw captures such as transcripts, saved articles, and notes waiting for processing |

## Ingest path

`m3 add` now routes PDF inputs into `knowledge/papers/<name>/index.md` through the existing `pdf2m3` ingest path. This index defines the intended layout and keeps the repository structure explicit for contributors.

## Generated Map

The generated portion of this file is managed by the M1 knowledge index flow documented in [docs/knowledge-index-generation.md](../docs/knowledge-index-generation.md). Until the generator lands, contributors should update this section manually using the same deterministic ordering rules.

<!-- youaskm3:index:start -->
| Category | Processed entries | Pending inputs |
|---|---:|---:|
| `books/` | 1 | 0 |
| `papers/` | 1 | 0 |
| `blog/` | 1 | 0 |
| `inputs/` | 0 | 0 |

Processed fixture artifacts:

- `knowledge/books/mvp-fixture-handbook/index.md`
- `knowledge/papers/mvp-fixture-note/index.md`
- `knowledge/blog/mvp-fixture-article/index.md`
<!-- youaskm3:index:end -->

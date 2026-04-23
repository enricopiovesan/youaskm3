# url2m3

`url2m3` ingests web articles, transcripts, and other URL-backed content into the markdown-oriented knowledge workspace.

The first M1 slice uses `curl` for capture and the `youaskm3-ingest` crate for deterministic markdown rendering. `m3 add` uses this path as the repo-level entry point for HTTP and HTTPS URLs and writes the result into `knowledge/inputs/articles/<slug>.md`.

## Usage

```bash
tools/url2m3/url2m3.sh <url> <output.md> [title]
```

Example:

```bash
tools/url2m3/url2m3.sh https://example.com/post knowledge/inputs/articles/example-com-post.md
./scripts/m3.sh add https://example.com/post
```

The generated markdown includes:

- a document title derived from the URL or supplied title
- source URL traceability metadata
- normalized captured text grouped into markdown paragraphs

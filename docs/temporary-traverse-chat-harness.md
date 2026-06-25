# Temporary Traverse Chat Harness

The temporary Traverse chat harness is now an explicit browser-demo fallback for
development and contract fixtures. The default PWA answer path is the configured
Traverse HTTP/JSON runtime.

The harness is intentionally deterministic and replaceable. It accepts the same
minimum input shape as `knowledge.query.answer`, reads generated static
artifacts that the PWA already loads, and returns only the contract-defined
answer fields:

- `answer`
- `citations`
- `graph_evidence`
- `trace_id`
- `validation`

The harness may retrieve matching generated search-index entries, produce a
templated answer, attach source-backed citations, include graph evidence from
`knowledge-graph.json`, and mark the trace as `harness`.

The harness must not become permanent product business logic. Retrieval,
graph expansion, context packing, inference selection, answer validation, and
answer formatting remain Traverse-run capability responsibilities. Configured
Traverse failures must be surfaced as runtime errors; the PWA must not silently
fall back to this harness when Traverse mode is selected.

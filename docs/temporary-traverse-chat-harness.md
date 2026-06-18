# Temporary Traverse Chat Harness

The temporary Traverse chat harness lets the PWA exercise the future
`knowledge.query.answer` app-facing contract before Traverse can execute the full
workflow for youaskm3.

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
answer formatting remain Traverse-run capability responsibilities. When Traverse
can execute `knowledge.query.answer` for the PWA, this harness should be removed
or kept only as a contract fixture.

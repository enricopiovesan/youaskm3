# MCP Connection Flows

Status: Current capability map, not a production-ready MCP product claim

## Purpose

This guide explains how to connect the current youaskm3 MCP surface to clients and app integrations without implying unsupported product completeness.

The governing references are:

- [SPEC.md section 5](../SPEC.md#traverse-integration-baseline)
- [SPEC.md section 8](../SPEC.md#8-milestones)
- [mcp-interface spec](../openspec/specs/mcp-interface/spec.md)
- [MCP tools contract](../contracts/mcp-tools.json)
- [Traverse MVP requirements](traverse-mvp-requirements.md)

## What Works Today

The repository currently validates these MCP-related surfaces:

| Surface | Current path | What it proves |
|---|---|---|
| Tool contracts | `contracts/mcp-tools.json` | Tool names, capability ids, workflow ids, input schemas, output schemas, and error schemas are explicit. |
| Local runtime route map | `ruby scripts/m3-local-runtime.rb --routes-json` | HTTP JSON routes and MCP-labeled routes are exposed by the same local runtime adapter. |
| App-consumable HTTP JSON | `POST /api/answer`, `GET /api/gaps`, `POST /api/gaps/resolve-fact` | The PWA/app path maps to Traverse workflow requests instead of embedding product logic in the browser. |
| MCP-labeled local routes | `POST /mcp/tools/knowledge.query.answer`, `POST /mcp/tools/knowledge.gaps.list`, `POST /mcp/tools/knowledge.gaps.resolve_fact` | MCP calls map to the same capability and workflow contracts as the app path. |
| Parity validation | `bash scripts/local-runtime-mcp-parity-smoke.sh` | App and MCP surfaces produce equivalent Traverse requests and failure modes when Traverse is not configured. |

The local runtime adapter intentionally returns `MISSING_TRAVERSE_RUNTIME` when no Traverse endpoint is configured. That is a supported setup failure, not a fake answer path.

## Runtime Assumptions

Before a real answer can run end to end, a prepared environment needs:

- a built youaskm3 checkout
- the standard repo validation tools from [local-development-toolchain.md](local-development-toolchain.md)
- a Traverse endpoint that can execute the registered youaskm3 app workflow
- a workspace id, defaulting to `local-default`
- registered or validated youaskm3 Traverse app artifacts from `traverse/youaskm3-app/`

Check runtime readiness with:

```bash
./scripts/m3.sh serve --runtime 8787 \
  --traverse-endpoint http://127.0.0.1:8788 \
  --workspace-id local-default \
  --check-only
```

When ready, the command prints:

```text
youaskm3 runtime ready.
- runtime_url: http://127.0.0.1:8787/
- mcp_endpoint: http://127.0.0.1:8787/mcp
- workspace_id: local-default
- trace_evidence_mode: public
```

Start the local runtime without `--check-only`:

```bash
./scripts/m3.sh serve --runtime 8787 \
  --traverse-endpoint http://127.0.0.1:8788 \
  --workspace-id local-default
```

## Claude-Compatible MCP Clients

Claude Desktop-style clients should be treated as a client integration target, not as already-complete product support.

What a Claude-compatible setup can use today:

1. Use `contracts/mcp-tools.json` as the tool manifest source.
2. Point any local bridge or client adapter at the runtime-reported MCP endpoint, `http://127.0.0.1:8787/mcp`.
3. Map tool calls to the current MCP-labeled routes:

| MCP tool | Local route | Required input |
|---|---|---|
| `knowledge.query.answer` | `POST /mcp/tools/knowledge.query.answer` | `{ "query": "..." }` |
| `knowledge.gaps.list` | `POST /mcp/tools/knowledge.gaps.list` | `{}` or `{ "persona_id": "...", "limit": 20 }` |
| `knowledge.gaps.resolve_fact` | `POST /mcp/tools/knowledge.gaps.resolve_fact` | `{ "gap_id": "...", "answer": "..." }` |

Example local call:

```bash
curl -sS http://127.0.0.1:8787/mcp/tools/knowledge.query.answer \
  -H 'content-type: application/json' \
  -d '{"query":"What does this knowledge base say about portable knowledge?"}'
```

For offline contract validation, use the simulator:

```bash
ruby scripts/m3-local-runtime.rb \
  --simulate POST /mcp/tools/knowledge.query.answer \
  --body '{"query":"What is portable knowledge?","request_id":"local-contract-check"}'
```

Without Traverse configured, the expected response is a recoverable `MISSING_TRAVERSE_RUNTIME` failure that still includes the capability id, workflow id, contract path, and Traverse request shape.

## App-Consumable Integration Path

Apps should use the HTTP JSON routes unless they are specifically acting as an MCP client:

```bash
curl -sS http://127.0.0.1:8787/api/answer \
  -H 'content-type: application/json' \
  -d '{"query":"What changed in the latest decision log?"}'
```

The app route and MCP route both produce Traverse requests for the same `knowledge.query.answer` workflow. The difference is the caller surface:

- app path: `surface: "http"`, `requested_target: "local"`
- MCP path: `surface: "mcp"`, `requested_target: "mcp"`

This lets the PWA and MCP clients share governed capability contracts while keeping UI rendering separate from runtime business logic.

## Planned, Not Yet Supported

Do not claim these as available until the repo has matching validation:

- a packaged Claude Desktop `mcpServers` command that runs the full youaskm3 MCP server through stdio
- a complete end-user chat loop over Traverse-run WASM capabilities
- a live local LLM or model provider path hidden inside youaskm3 app code
- a separate MCP implementation that bypasses the registered Traverse workflow
- production-ready cross-instance federation or search fan-out over MCP

These gaps are tracked by the governing specs, [Traverse MVP requirements](traverse-mvp-requirements.md), and the GitHub milestone tickets.

## Validation

Use these checks when changing the MCP connection story:

```bash
bash scripts/local-runtime-mcp-parity-smoke.sh
bash scripts/traverse-mcp-answer-workflow-smoke.sh
bash scripts/smoke.sh
```

The parity smoke is the focused proof for this guide. Full smoke remains the release-level repo validation path.

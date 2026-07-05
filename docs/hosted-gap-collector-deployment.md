# Hosted Gap Collector Deployment

Status: Reference deployment notes for `hosted-gap-collector`

## Purpose

The hosted gap collector is an optional public write boundary for GitHub Pages
chat. It accepts public gap reports, validates abuse controls, and stores
pending reports for owner review. It does not run inference, mutate local
knowledge, update the graph, create GitHub issues, or mark reports imported.

## Reference Provider

The first reference endpoint is a Cloudflare Worker-shaped module at
`app/hosted-gap-collector/worker.ts`. It is intentionally provider-light: the
core handler is testable without Cloudflare, while the default export expects a
Worker request and a D1 binding.

Required Worker bindings and variables:

| Name | Type | Required | Purpose |
|---|---|---:|---|
| `GAP_REPORTS` | D1 database binding | yes | Pending report storage. |
| `ALLOWED_ORIGINS` | comma-separated origins | yes | Public pages allowed to submit reports. |
| `TURNSTILE_SECRET_KEY` | secret | recommended | Verifies public abuse challenge tokens server-side. |
| `COLLECTOR_ID` | text | no | Stable collector id stored with reports. |
| `MAX_BODY_BYTES` | integer | no | Defaults to `8192`. |
| `RATE_LIMIT_MAX` | integer | no | Defaults to `10`. |
| `RATE_LIMIT_WINDOW_SECONDS` | integer | no | Defaults to `3600`. |

The browser must never receive `TURNSTILE_SECRET_KEY`, D1 credentials, GitHub
tokens, or any other write secret.

## D1 Schema

The reference storage adapter expects a pending-only table:

```sql
CREATE TABLE pending_gap_reports (
  report_id TEXT PRIMARY KEY,
  collector_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status = 'pending'),
  schema_version TEXT NOT NULL,
  validation_version TEXT NOT NULL,
  question TEXT NOT NULL,
  missing_knowledge TEXT NOT NULL,
  published_scope TEXT NOT NULL,
  checked_evidence_json TEXT NOT NULL,
  source_url TEXT NOT NULL,
  submitted_at TEXT NOT NULL,
  reporter_context TEXT,
  received_at TEXT NOT NULL,
  client_key TEXT NOT NULL,
  origin TEXT NOT NULL
);

CREATE INDEX pending_gap_reports_client_window
  ON pending_gap_reports (client_key, received_at);
```

`client_key` is a server-side hash used for rate limiting. It is operational
telemetry, not identity, and should not be shown as reporter metadata.

## Request Shape

The endpoint accepts either a raw public gap report JSON object or an envelope:

```json
{
  "report": {
    "schema_version": "public-gap-report/0.1.0",
    "validation_version": "hosted-gap-collector/0.1.0",
    "question": "What is missing?",
    "missing_knowledge": "No source-backed citation answered the question.",
    "published_scope": "public-demo",
    "checked_evidence": ["search-index:0 results"],
    "source_url": "https://example.com/chat",
    "submitted_at": "2026-07-05T12:00:00.000Z",
    "reporter_context": "Optional visitor context"
  },
  "challenge_token": "public-turnstile-token"
}
```

When `TURNSTILE_SECRET_KEY` is configured, `challenge_token` is required and is
verified server-side. Accepted reports return `202` with
`HOSTED_GAP_REPORT_ACCEPTED`, a report id, and `pending` status.

## Stable Errors

The endpoint maps failures to stable codes:

| Failure | Code |
|---|---|
| Invalid JSON, missing fields, unsupported schema, oversized body | `HOSTED_GAP_REPORT_INVALID` |
| Disallowed origin or failed challenge | `HOSTED_GAP_ABUSE_CHALLENGE_FAILED` |
| Rate limit exceeded | `HOSTED_GAP_RATE_LIMITED` |
| Storage unavailable | `HOSTED_GAP_STORAGE_FAILED` |

## Free-Tier And Cost Assumptions

The default quotas are conservative for an MVP public instance:

- request body limit: `8192` bytes
- rate limit: `10` accepted reports per hashed client key per hour
- storage: one D1 row per accepted pending report
- retention: owner should review and delete, reject, archive, or import reports
  regularly once CLI support is enabled

Before enabling the collector on a public instance, configure provider billing
alerts or hard limits where available. If expected traffic exceeds free-tier
usage, treat that as a release readiness blocker rather than silently raising
limits.

## Owner Review Boundary

Every stored row remains `pending`. Owner import belongs to the local CLI gap
lifecycle and must preserve hosted report id, source URL, published scope,
reporter context, timestamps, schema version, and validation version. The
collector must not mark a report imported without an explicit owner-side
workflow.

The CLI review bridge is `m3 hosted-gaps`:

```bash
./scripts/m3.sh hosted-gaps list --collector-url https://collector.example.com/reports
./scripts/m3.sh hosted-gaps import --collector-url https://collector.example.com/reports --report-id gap_123 --accept
./scripts/m3.sh hosted-gaps reject --collector-url https://collector.example.com/reports --report-id gap_123
```

Use `M3_HOSTED_GAP_COLLECTOR_TOKEN` or `--collector-token` for owner-only read
endpoints. When a collector cannot update remote status, reject and archive
commands record local review state under the knowledge root so ignored reports
do not appear in subsequent local review lists.

# Hosted Gap Collector Architecture

Status: Future scope architecture for `hosted-gap-collector`

## Purpose

The hosted gap collector is an optional, narrow write boundary for public
GitHub Pages chat. It lets a visitor submit a pending knowledge-gap report
without giving the browser write credentials and without turning youaskm3 into a
hosted account, hosted sync, hosted runtime, or hosted inference product.

The local user-owned instance remains the source of truth. Hosted reports are
only pending external input until the owner reviews and imports them through the
local CLI.

## Why Static Browser Code Is Not Enough

GitHub Pages can serve public chat and static artifacts, but it cannot safely
perform authenticated writes by itself:

- Browser WASM runs in the visitor's browser and cannot protect write secrets.
- GitHub Secrets are not available to arbitrary public browser sessions.
- A GitHub token, database token, or service API key embedded in static assets
  would be public.
- Direct browser writes to a repository, database, or graph would bypass owner
  review, provenance, abuse controls, and local validation.

For low-friction public submission, the system needs a trusted hosted boundary
between the static page and pending report storage.

## Minimal Architecture

The recommended first architecture is:

| Layer | Responsibility |
|---|---|
| GitHub Pages chat | Presents public artifacts, detects missing knowledge, discloses what will be sent, and sends a public gap report only when a collector is configured. |
| Trusted collector endpoint | Validates origin, abuse challenge, payload shape, size, rate limits, schema version, and validation version. |
| Pending report storage | Stores accepted reports as pending external gap reports, not local knowledge or graph data. |
| Owner CLI import | Pulls pending reports, shows review metadata, and imports accepted reports through the local knowledge-gap lifecycle. |

The preferred near-zero-cost provider set is Cloudflare Worker, D1, and
Turnstile. Equivalent providers are acceptable only when they preserve the same
boundaries:

- server-side secret custody outside the browser
- public challenge or equivalent abuse prevention
- origin checks
- per-origin and per-client rate limits
- request body size limits
- pending-only durable storage
- owner-readable export or pull path
- owner deletion or cleanup path
- conservative free-tier or cost controls

## Public Gap Report Payload

The portable report payload contains only public gap-submission data:

| Field | Required | Purpose |
|---|---|---|
| `schema_version` | yes | Public gap report schema version accepted by the collector and CLI. |
| `validation_version` | yes | Validation rules version used before storage. |
| `question` | yes | Visitor question that exposed the missing knowledge. |
| `missing_knowledge` | yes | Visitor-visible description of what appears missing. |
| `published_scope` | yes | Public instance, artifact set, persona, or route where the gap was observed. |
| `checked_evidence` | yes | Public evidence, citations, source ids, or empty-result summary checked before submission. |
| `source_url` | yes | Public page URL where the gap was reported. |
| `submitted_at` | yes | Submission timestamp generated or normalized by the collector. |
| `reporter_context` | no | Optional visitor-provided context; no account identity is required. |

The collector may add server-side metadata such as `report_id`,
`collector_id`, `received_at`, validation status, and abuse-control telemetry.
It must not require private local knowledge, local graph nodes, local persona
secrets, hosted account identity, or hidden inference traces.

## Stable Failure Codes

Hosted collector, UI, and CLI flows use stable failure codes so docs and tests
do not depend on provider-specific messages.

| Failure mode | Stable code | Boundary |
|---|---|---|
| Collector not configured | `HOSTED_GAP_COLLECTOR_NOT_CONFIGURED` | Static chat fallback |
| Payload invalid | `HOSTED_GAP_REPORT_INVALID` | Collector validation |
| Abuse challenge failure | `HOSTED_GAP_ABUSE_CHALLENGE_FAILED` | Collector abuse control |
| Rate limit exceeded | `HOSTED_GAP_RATE_LIMITED` | Collector abuse control |
| Pending storage failure | `HOSTED_GAP_STORAGE_FAILED` | Collector storage |
| Owner import failure | `HOSTED_GAP_OWNER_IMPORT_FAILED` | Local CLI import |

Provider-specific failures may include more detail, but user-facing docs and
acceptance checks should map them to these stable codes.

## Owner Review And Import

Hosted reports remain pending until the owner acts locally. The CLI review path
must show:

- report id
- question
- missing knowledge
- source URL
- published scope
- checked evidence
- timestamp
- reporter context when present
- schema version
- validation version
- validation status

Accepted reports enter the same local knowledge-gap lifecycle as locally
detected gaps. Rejected or archived reports remain outside the local knowledge
root unless the owner explicitly records them.

## Explicit Non-Goals

The hosted gap collector is not:

- full hosted youaskm3 accounts
- hosted teams or permissions
- hosted sync
- hosted runtime execution
- hosted inference
- direct graph mutation from public visitors
- automatic local knowledge mutation
- a replacement for local validation, provenance, or conflict handling

If the collector is absent, local chat, local CLI, local MCP, and
Traverse-backed local workflows continue to work. Published chat must offer an
honest fallback such as a GitHub issue draft, copyable markdown, or downloadable
gap package instead of pretending one-click hosted submission is available.

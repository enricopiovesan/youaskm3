# Federation Registry

This document defines the first public contract for joining the `youaskm3` federation. It is the maintainer-facing companion to [openspec/specs/federation/spec.md](../openspec/specs/federation/spec.md) and keeps the M5 registry workflow explicit before the nightly crawl and `/explore` experience land.

## Registry repository

Federation registrations are reviewed in the public registry repository:

- `https://github.com/youaskm3/registry`

That repository is the canonical home for `instances.json`, review discussions, and the future nightly crawl output.

## Required metadata

Every registry entry must provide the minimum metadata needed for discoverability and crawlability:

| Field | Why it is required |
|---|---|
| `name` | Human-readable instance or maintainer name. |
| `url` | Canonical published shell URL for the instance. |
| `search_index_url` | Static search artifact that later federation jobs will fetch. |
| `description` | One-paragraph summary of what the instance covers. |
| `topics` | Searchable tags that help explain the instance's focus. |
| `since` | Join date in `YYYY-MM-DD` format for traceability. |

Optional but recommended metadata:

| Field | Why it helps |
|---|---|
| `author_instance_url` | Points directly at the published author-instance manifest. |
| `repo` | Lets maintainers review the public source behind the instance. |

The canonical schema lives at [`contracts/federation-instances.schema.json`](../contracts/federation-instances.schema.json), and a compliant example lives at [`contracts/federation-instances.example.json`](../contracts/federation-instances.example.json).

## Join workflow

Use this process when registering a new instance:

1. Confirm the shell URL is public and the instance is a real `youaskm3` deployment.
2. Confirm `search-index.json` is published and fetchable from the declared `search_index_url`.
3. Add one object to `instances.json` following the schema and example contract.
4. Open a pull request against `youaskm3/registry` describing the instance, its topics, and the published URLs being added.
5. Wait for maintainer review. The registry stays pull-request-driven; there is no direct database or admin-panel write path.

## Review and removal rules

- The registry maintainer reviews registrations for schema compliance and public accessibility.
- Entries can be updated or removed by pull request.
- The maintainer may remove entries that are persistently offline, malformed, or no longer represent a valid `youaskm3` instance.

## Example entry

```json
{
  "name": "Enrico Piovesan",
  "url": "https://enricopiovesan.github.io/youaskm3/",
  "search_index_url": "https://enricopiovesan.github.io/youaskm3/search-index.json",
  "description": "Author instance covering WASM, UMA, distributed systems, and architecture writing.",
  "topics": ["WASM", "UMA", "distributed systems", "architecture"],
  "since": "2026-04-01"
}
```

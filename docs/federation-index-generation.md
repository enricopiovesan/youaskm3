# Federation Index Generation

This document defines the first deterministic crawl flow for the federation registry. It turns approved registry entries into a shared static index that later `/explore` and cross-instance search work can consume.

## Inputs

The crawl consumes:

| Input | Purpose |
|---|---|
| Registry JSON | Source of approved instance metadata and search index URLs. |
| Instance `search-index.json` files | Source-backed searchable summaries published by each participating instance. |

The canonical registry contract is defined in [`contracts/federation-instances.schema.json`](../contracts/federation-instances.schema.json). Each instance entry must expose a `search_index_url` that resolves to a valid `search-index.json`.

## Outputs

The generator writes these static artifacts:

| Artifact | Purpose |
|---|---|
| `app/site/federation-search-index.json` | Aggregated list of registered instances and their published searchable documents. |
| `app/site/federation-index-manifest.json` | Deterministic crawl manifest, artifact list, and source URLs for debugging. |

Both outputs include a `sourceFingerprint` so maintainers can confirm exactly which registry and instance inputs produced the crawl result.

## Workflow

Use the crawl flow in one of two modes:

1. Local deterministic validation with `bash scripts/federation-index-smoke.sh`
2. Nightly or on-demand generation through `.github/workflows/index.yml`

The scheduled workflow reads the registry URL from `FEDERATION_REGISTRY_URL`. When not overridden, it targets the public `youaskm3/registry` raw `instances.json` path.

## Failure handling

The crawl fails fast when:

- the registry JSON is missing required fields
- an instance search index cannot be fetched
- an instance search index is malformed or missing required searchable metadata

Those failures are intentional. They keep the shared index deterministic and make broken registry entries visible before publish or commit automation runs.

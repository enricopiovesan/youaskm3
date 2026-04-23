# knowledge-search Specification

## Purpose

The knowledge-search capability defines how youaskm3 retrieves relevant information across the local knowledge base using portable, client-runnable search primitives so the same search behavior can be reused in browser, CLI, and other WASM hosts.

## Requirements

### Requirement: Search indexed knowledge locally

The system SHALL provide semantic and keyword-aware retrieval over indexed knowledge without requiring a dedicated hosted database.

#### Scenario: Search authored notes from a local index

- GIVEN an instance has an up-to-date local knowledge index
- WHEN a user submits a search query
- THEN the system returns results derived from the local index rather than a remote database

### Requirement: Return source-aware results

The system SHALL preserve enough source context in search responses to let downstream interfaces explain where a result came from.

#### Scenario: Show a result with source metadata

- GIVEN multiple knowledge files match a query
- WHEN the search capability ranks and returns results
- THEN each result can be associated with a source path or equivalent metadata

### Requirement: Generate a deterministic knowledge index

The system SHALL define a deterministic generation flow for `knowledge/index.md` that derives the master map from processed knowledge content rather than hand-maintained search metadata.

#### Scenario: Refresh the master knowledge map

- GIVEN processed markdown artifacts exist under `knowledge/books/`, `knowledge/papers/`, and `knowledge/blog/`
- WHEN the index generation flow runs
- THEN `knowledge/index.md` is updated from those artifacts with stable ordering, source paths, and category counts

### Requirement: Separate raw captures from searchable artifacts

The system SHALL exclude raw captures under `knowledge/inputs/` from the searchable index until an ingest workflow promotes them into a processed knowledge category.

#### Scenario: Leave captured notes out of search results

- GIVEN a raw transcript is stored under `knowledge/inputs/transcripts/`
- WHEN the knowledge index is regenerated
- THEN the transcript is reported as pending ingest instead of being treated as searchable knowledge

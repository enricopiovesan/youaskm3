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

### Requirement: Retrieve from prepared artifacts through a capability boundary

The system SHALL define retrieval as a Traverse-compatible capability that consumes prepared search, chunk, and markdown artifacts instead of embedding product retrieval logic in the PWA.

#### Scenario: Retrieve evidence for a chat request

- GIVEN a user submits a chat prompt through the PWA
- WHEN retrieval is needed for the answer workflow
- THEN the PWA delegates retrieval to the `knowledge.retrieve` capability and receives source-aware result objects

### Requirement: Preserve chunk-level evidence

The system SHALL include chunk ids, source artifact ids, source paths, excerpts, and score information in retrieval responses.

#### Scenario: Return a cited chunk

- GIVEN an indexed chunk matches a query
- WHEN the retrieval capability returns it
- THEN the response includes the chunk id, artifact id, source path, excerpt, and score needed for citation and validation

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

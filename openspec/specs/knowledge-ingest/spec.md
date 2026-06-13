# knowledge-ingest Specification

## Purpose

The knowledge-ingest capability defines how youaskm3 captures source material such as PDFs, articles, transcripts, and notes into a git-native knowledge workspace so that later indexing and search can operate on traceable markdown artifacts instead of opaque blobs.

## Requirements

### Requirement: Capture source material with traceability

The system SHALL ingest supported source material into the knowledge workspace while preserving enough source metadata to identify where the content came from and how it entered the repository.

#### Scenario: Record an article for later processing

- GIVEN a contributor provides a URL for ingestion
- WHEN the ingest workflow stores the source in the knowledge workspace
- THEN the repository keeps a traceable artifact that can be indexed and reviewed later

### Requirement: Prepare content for chunked knowledge files

The system SHALL organize ingested content into markdown-oriented structures that can later be chunked into efficient context windows for indexing and retrieval.

#### Scenario: Stage a book for chapter processing

- GIVEN a book has been captured for ingestion
- WHEN the ingest pipeline prepares its output
- THEN the resulting structure is compatible with chapter maps, summaries, and derived diagram assets

### Requirement: Use MarkItDown as the default source conversion layer

The system SHALL route supported document conversion through MarkItDown before normalization unless a more specific approved converter is required for a source type.

#### Scenario: Convert an office document into markdown

- GIVEN a user provides a supported office document
- WHEN the CLI add or build workflow converts the source
- THEN the raw conversion output is produced through the MarkItDown-backed path and records the converter name and version in artifact metadata

### Requirement: Produce normalized markdown artifacts

The system SHALL normalize converted content into markdown artifacts that include stable ids, source metadata, conversion metadata, section boundaries, chunk hints, and graph extraction hints.

#### Scenario: Normalize converted content for downstream capabilities

- GIVEN raw converted markdown exists for a source file
- WHEN the normalization workflow writes a processed artifact
- THEN the artifact conforms to `contracts/markdown-artifact.schema.json` and can be chunked, searched, and used for graph extraction

### Requirement: Keep product semantics out of conversion tooling

The system SHALL keep source conversion, normalization, artifact writing, and build orchestration in the CLI while leaving retrieval ranking, graph traversal, context packing, answer validation, and inference selection to Traverse-run capabilities.

#### Scenario: Build artifacts without answering a question

- GIVEN the CLI is preparing a knowledge workspace
- WHEN it converts and normalizes source files
- THEN it writes deterministic artifacts without deciding which chunks answer a user prompt

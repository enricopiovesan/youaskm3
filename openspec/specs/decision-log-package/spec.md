# decision-log-package Specification

Status: Approved by brainstorming on 2026-06-29

## Purpose

The decision-log-package capability defines the portable artifact produced by assistant reasoning sessions and consumed by the youaskm3 CLI to update personal knowledge, gaps, provenance, and the reasoning graph.

## Requirements

### Requirement: Validate package structure

The system SHALL accept a package directory containing `decision-log.md`, `knowledge-note.md`, and `metadata.json`.

#### Scenario: Ingest a package directory

- GIVEN a local package directory exists
- WHEN `m3 ingest-decision-log /path/to/package/` runs
- THEN the CLI validates that all required package files exist
- AND archive files are rejected for the first MVP
- AND the package mode is one of `knowledge_addition`, `gap_resolution`, `direct_fact_resolution`, or `conflict_resolution`

### Requirement: Preserve source package provenance

The system SHALL copy accepted packages into the knowledge store and record the original import path.

#### Scenario: Store an imported package

- GIVEN deterministic validation passes
- WHEN final ingestion proceeds through Traverse-governed validation and graph update
- THEN the package is copied to `knowledge/sources/decision-logs/<package-id>/`
- AND provenance records the original import path, import timestamp, persona id, package id, package mode, and validation evidence

### Requirement: Validate knowledge note consistency

The system SHALL validate `knowledge-note.md` against `decision-log.md` before final ingestion.

#### Scenario: Detect unsupported distilled knowledge

- GIVEN `knowledge-note.md` introduces a claim not supported by the decision log
- WHEN deterministic package validation runs
- THEN ingestion fails with a stable validation error
- AND no final knowledge note or graph update is produced

### Requirement: Use deterministic validation as the required baseline

The system SHALL require deterministic validation and MAY run optional Traverse-governed semantic validation when available.

#### Scenario: Semantic validation unavailable

- GIVEN deterministic validation passes
- AND Traverse semantic validation is unavailable
- WHEN final ingestion runs
- THEN ingestion may continue
- AND metadata records that semantic validation was unavailable

#### Scenario: Semantic validation fails

- GIVEN deterministic validation passes
- AND Traverse semantic validation runs and rejects the package
- WHEN ingestion handles the result
- THEN the whole package is not ingested as final knowledge
- AND a knowledge gap is created or updated for clarification

### Requirement: Support offline staging only

The system SHALL allow offline mode to stage package metadata but not perform final ingestion, graph extraction, or knowledge update.

#### Scenario: Stage while offline

- GIVEN the workspace was initialized with `m3 init --offline`
- WHEN the user stages a decision-log package
- THEN the package is recorded as pending Traverse-backed ingestion
- AND final validation, knowledge update, and graph extraction remain blocked until Traverse is available

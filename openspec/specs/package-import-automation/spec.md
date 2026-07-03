# package-import-automation Specification

Status: Future scope, unknowns pending

## Purpose

The package-import-automation capability defines optional import convenience features beyond first-MVP CLI directory ingestion, including archive package ingestion and inbox/watch-folder processing.

## Requirements

### Requirement: Import decision-log package archives safely

The system SHALL support archive ingestion only after validating archive structure, size limits, paths, and package contents.

#### Scenario: Reject path traversal archive

- GIVEN a zip archive contains a path outside the intended extraction root
- WHEN archive ingestion runs
- THEN ingestion fails before extraction
- AND no knowledge-root files are written

### Requirement: Support inbox processing without silent ingestion

The system SHALL allow an optional inbox or watch-folder flow only when it preserves explicit validation, provenance, sync preflight, and user-visible results.

#### Scenario: Process inbox package

- GIVEN a package appears in a configured inbox
- WHEN the inbox processor runs
- THEN it validates the package through the same path as `m3 ingest-decision-log`
- AND writes a clear ingested, rejected, or staged result
- AND does not bypass Traverse-required final ingestion rules

### Requirement: Preserve the CLI ingestion contract

The system SHALL keep `m3 ingest-decision-log /path/to/package/` as the canonical ingestion behavior even when archives or inbox flows exist.

#### Scenario: Debug an automated import

- GIVEN an inbox import fails
- WHEN the user wants to reproduce the failure
- THEN the same package can be passed to the CLI ingestion command with equivalent validation results

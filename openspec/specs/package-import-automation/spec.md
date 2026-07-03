# package-import-automation Specification

Status: Future scope, planning decisions recorded

## Purpose

The package-import-automation capability defines optional import convenience features beyond first-MVP CLI directory ingestion, including archive package ingestion and inbox/watch-folder processing.

Archive ingestion comes before inbox/watch-folder automation. The first supported archive format is `.zip`; tar formats are future work only if needed.

## Requirements

### Requirement: Import decision-log package archives safely

The system SHALL support `.zip` archive ingestion only after validating archive structure, size limits, paths, and package contents.

#### Scenario: Reject path traversal archive

- GIVEN a zip archive contains a path outside the intended extraction root
- WHEN archive ingestion runs
- THEN ingestion fails before extraction
- AND no knowledge-root files are written

#### Scenario: Reject unsupported archive format

- GIVEN a user passes an unsupported archive format
- WHEN archive ingestion runs
- THEN the command fails with a stable unsupported-format error
- AND the error states that `.zip` is the first supported archive format

### Requirement: Support inbox processing without silent ingestion

The system SHALL allow optional inbox processing only through an explicit command first. Background watch-folder behavior is later scope and must use the same validation path.

#### Scenario: Process inbox package

- GIVEN a package appears in a configured inbox
- WHEN the explicit inbox import command runs
- THEN it validates the package through the same path as `m3 ingest-decision-log`
- AND writes a clear ingested, rejected, or staged result
- AND does not bypass Traverse-required final ingestion rules

#### Scenario: Later watcher uses same path

- GIVEN a future watch-folder mode is enabled
- WHEN the watcher detects a package
- THEN it must produce the same validation and result records as the explicit inbox command

### Requirement: Preserve the CLI ingestion contract

The system SHALL keep `m3 ingest-decision-log /path/to/package/` as the canonical ingestion behavior even when archives or inbox flows exist.

#### Scenario: Debug an automated import

- GIVEN an inbox import fails
- WHEN the user wants to reproduce the failure
- THEN the same package can be passed to the CLI ingestion command with equivalent validation results

# local-runtime-sync Specification

Status: Approved by brainstorming on 2026-06-29

## Purpose

The local-runtime-sync capability defines first-run setup, local serving, Traverse startup/attachment, external knowledge roots, file-system sync-folder support, conflict preflight, and the final expanded MVP acceptance gate.

## Requirements

### Requirement: Initialize workspace and knowledge roots

The system SHALL use `m3 init` as the first-run setup command.

#### Scenario: Initialize with Traverse

- GIVEN the user provides a Traverse checkout or configured Traverse command
- WHEN `m3 init --knowledge-root <path> --traverse-repo <path>` runs
- THEN the CLI creates or validates the knowledge-root marker
- AND writes project configuration
- AND validates the Traverse baseline
- AND initializes local metadata
- AND reports the next command to run

#### Scenario: Initialize offline

- GIVEN Traverse is not available
- WHEN `m3 init --offline --knowledge-root <path>` runs
- THEN the CLI initializes knowledge storage only
- AND marks runtime readiness as unavailable
- AND final decision-log ingestion, graph update, chat runtime, and MVP acceptance remain blocked until Traverse is available

### Requirement: Protect external knowledge roots

The system SHALL require external knowledge roots to contain a youaskm3 marker before writes.

#### Scenario: Reject uninitialized external root

- GIVEN `--knowledge-root` points outside the workspace
- AND the target has no youaskm3 marker
- WHEN a knowledge-writing command runs
- THEN the command fails with a clear setup error directing the user to run `m3 init --knowledge-root <path>`

### Requirement: Serve local chat and MCP runtime

The system SHALL provide `m3 serve` to power the local HTTP JSON chat API and MCP parity surface.

#### Scenario: Start or attach to Traverse

- GIVEN project config or CLI overrides identify Traverse runtime configuration
- WHEN `m3 serve` runs
- THEN it tries to start or attach to Traverse
- AND fails with a clear setup error when Traverse is unavailable
- AND exposes HTTP JSON for the PWA and MCP backed by the same Traverse workflow

### Requirement: Run sync conflict preflight

The system SHALL support file-system sync-folder usage and run sync/conflict checks before knowledge writes.

#### Scenario: Preflight before package ingestion

- GIVEN the knowledge root may be synchronized by iCloud Drive, Dropbox, Syncthing, or a similar file-system sync tool
- WHEN a knowledge-writing command runs
- THEN the command runs conflict preflight
- AND safely auto-merges append-only artifacts when possible
- AND stops and writes conflict reports for semantic conflicts

### Requirement: Provide manual sync inspection

The system SHALL provide `m3 sync check`.

#### Scenario: Inspect sync state

- GIVEN a user wants to inspect sync health
- WHEN `m3 sync check` runs
- THEN it reports clean, auto-merged, open conflict, or blocked states for decision-log packages, knowledge notes, gaps, graph artifacts, and metadata/index state

### Requirement: Provide expanded first-MVP acceptance gate

The system SHALL provide a final acceptance gate for the expanded first MVP.

#### Scenario: Run expanded MVP check

- GIVEN a clean local setup with Traverse available
- WHEN `m3 mvp-check --traverse-repo <path> --knowledge-root <path>` runs
- THEN it validates repo health, Traverse readiness, assistant skill generation drift, decision-log package ingestion, reasoning graph extraction, gap lifecycle, sync preflight, local HTTP JSON chat, MCP parity, evidence/provenance rendering, and no-placeholder acceptance rules
- AND it fails if Browser demo, fake workflow steps, skeleton manifests, placeholder digests, or downstream runtime shortcuts are used as acceptance evidence

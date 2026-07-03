# assistant-distribution Specification

Status: Future scope, planning decisions recorded

## Purpose

The assistant-distribution capability defines how generated reasoning-skill adapters become packaged, installable, and versioned artifacts for ChatGPT, Claude, and future assistant platforms without changing the LLM-agnostic canonical skill source.

The first distribution target is a generated platform artifact bundle, not a marketplace-ready package and not only copy/paste instructions. ChatGPT and Claude are equal golden targets.

## Requirements

### Requirement: Package adapters without changing product logic

The system SHALL treat platform packaging as distribution metadata around generated adapters, not as a new source of product/business behavior.

#### Scenario: Package a ChatGPT adapter

- GIVEN the canonical reasoning skill and generated ChatGPT adapter pass drift checks
- WHEN a ChatGPT package artifact is produced
- THEN it preserves the generated adapter instructions, decision-log package rules, and generic CLI handoff
- AND any platform-specific manifest fields are generated from explicit packaging metadata

#### Scenario: Package both golden targets

- GIVEN the canonical skill source changes
- WHEN package generation runs
- THEN ChatGPT and Claude artifact bundles are generated from the same canonical source
- AND both must pass drift checks
- AND platform-specific limitations are documented separately instead of changing core behavior

### Requirement: Version distributed assistant packages

The system SHALL version packaged assistant artifacts against the canonical skill version and package schema version.

#### Scenario: Detect stale distributed package

- GIVEN a generated adapter or package schema changes
- WHEN the distribution check runs
- THEN stale platform packages fail validation
- AND the failure reports the exact canonical version mismatch

### Requirement: Keep platform limitations explicit

The system SHALL document platform-specific packaging limits such as file export shape, action/tool availability, local file handoff, and marketplace publication constraints.

#### Scenario: Review platform readiness

- GIVEN a platform does not support a required package export or local handoff
- WHEN packaging validation runs
- THEN the artifact is marked blocked for that platform
- AND the canonical skill remains valid for other platforms

### Requirement: Include example package suite

The system SHALL include runnable examples in assistant distribution bundles.

#### Scenario: Validate assistant examples

- GIVEN a generated assistant bundle exists
- WHEN its example suite is checked
- THEN it includes examples for `knowledge_addition`, `gap_resolution`, and `conflict_resolution`
- AND each example includes generated `decision-log.md`, `knowledge-note.md`, `metadata.json`, and expected CLI validation result

### Requirement: Produce files before platform actions

The system SHALL make package file output the first distribution baseline and keep platform action/tool integrations optional future work.

#### Scenario: Use distributed assistant without platform action

- GIVEN a user uses the generated ChatGPT or Claude bundle
- WHEN a reasoning session finalizes
- THEN the assistant produces files for CLI ingestion
- AND no platform action/tool integration is required
- AND future action/tool integrations must not bypass package validation or Traverse-governed ingestion

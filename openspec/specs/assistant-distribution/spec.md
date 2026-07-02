# assistant-distribution Specification

Status: Future scope, unknowns pending

## Purpose

The assistant-distribution capability defines how generated reasoning-skill adapters become packaged, installable, and versioned artifacts for ChatGPT, Claude, and future assistant platforms without changing the LLM-agnostic canonical skill source.

## Requirements

### Requirement: Package adapters without changing product logic

The system SHALL treat platform packaging as distribution metadata around generated adapters, not as a new source of product/business behavior.

#### Scenario: Package a ChatGPT adapter

- GIVEN the canonical reasoning skill and generated ChatGPT adapter pass drift checks
- WHEN a ChatGPT package artifact is produced
- THEN it preserves the generated adapter instructions, decision-log package rules, and generic CLI handoff
- AND any platform-specific manifest fields are generated from explicit packaging metadata

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

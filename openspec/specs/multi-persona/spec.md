# multi-persona Specification

Status: Future scope, unknowns pending

## Purpose

The multi-persona capability defines how more than one persona can maintain isolated or intentionally shared knowledge, gaps, decision logs, graph context, and assistant adapters.

## Requirements

### Requirement: Isolate persona knowledge by default

The system SHALL keep persona knowledge, gaps, conflicts, and reasoning graphs isolated unless sharing is explicitly configured.

#### Scenario: Ask as one persona

- GIVEN two personas exist in the same installation
- WHEN the active persona asks a question
- THEN answer context is selected only from that persona's allowed knowledge scope
- AND provenance records the active persona id

### Requirement: Support explicit shared scopes

The system SHALL support shared knowledge scopes only through explicit metadata and conflict policy.

#### Scenario: Share a decision log

- GIVEN a decision-log package is marked as shared
- WHEN it is ingested
- THEN the package records which personas may use it
- AND conflicts between persona-specific knowledge and shared knowledge are visible

### Requirement: Generate persona-aware assistant packages

The system SHALL allow generated assistant adapters to include persona context without hardcoding private knowledge into the adapter.

#### Scenario: Generate adapter for a persona

- GIVEN a persona profile exists
- WHEN assistant packaging runs
- THEN generated instructions may include allowed persona metadata
- AND do not embed private knowledge content outside the knowledge store

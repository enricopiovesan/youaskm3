# federated-answer Specification

Status: Future scope, unknowns pending

## Purpose

The federated-answer capability extends the existing federation registry and shared index work into cross-instance search and answer flows while preserving local ownership, provenance, and opt-in participation.

## Requirements

### Requirement: Query federated indexes explicitly

The system SHALL use federated indexes only when the user or configured policy explicitly allows cross-instance search.

#### Scenario: Ask with federation disabled

- GIVEN federation search is disabled
- WHEN the user asks a question
- THEN only local knowledge is used
- AND no cross-instance query is performed

### Requirement: Preserve remote provenance

The system SHALL label remote evidence distinctly from local personal knowledge.

#### Scenario: Answer from remote instance evidence

- GIVEN a federated answer uses evidence from another instance
- WHEN the answer is rendered
- THEN provenance identifies the remote instance, source artifact, retrieval path, and confidence
- AND the answer does not imply the remote evidence is part of the user's personal knowledge unless imported

### Requirement: Support import from federated evidence

The system SHALL allow useful federated evidence to become local knowledge only through explicit import or decision-log reasoning.

#### Scenario: Import remote evidence

- GIVEN the user wants to keep remote evidence
- WHEN the import flow runs
- THEN the evidence becomes a local source artifact or reasoning package with provenance back to the remote instance

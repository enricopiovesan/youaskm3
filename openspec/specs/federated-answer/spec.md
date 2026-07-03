# federated-answer Specification

Status: Future scope, planning decisions recorded

## Purpose

The federated-answer capability extends the existing federation registry and shared index work into cross-instance search and answer flows while preserving local ownership, provenance, and opt-in participation.

Federated answers can appear in the same chat only when explicitly enabled per question or session. Remote evidence is lower-trust, evidence-only by default.

## Requirements

### Requirement: Query federated indexes explicitly

The system SHALL use federated indexes only when the user or configured policy explicitly allows cross-instance search for the current question or session.

#### Scenario: Ask with federation disabled

- GIVEN federation search is disabled
- WHEN the user asks a question
- THEN only local knowledge is used
- AND no cross-instance query is performed

#### Scenario: Ask with federation enabled

- GIVEN federation search is explicitly allowed
- WHEN the user asks a question that matches remote index evidence
- THEN the remote query is recorded
- AND returned evidence is labeled as remote

### Requirement: Preserve remote provenance

The system SHALL label remote evidence distinctly from local personal knowledge.

#### Scenario: Answer from remote instance evidence

- GIVEN a federated answer uses evidence from another instance
- WHEN the answer is rendered
- THEN provenance identifies the remote instance, source artifact, retrieval path, and confidence
- AND the answer does not imply the remote evidence is part of the user's personal knowledge unless imported
- AND the evidence is treated as lower-trust evidence-only by default

### Requirement: Support import from federated evidence

The system SHALL allow useful federated evidence to be saved as a source artifact or adopted into personal reasoning through a decision-log package.

#### Scenario: Import remote evidence

- GIVEN the user wants to keep remote evidence as a reference
- WHEN the import flow runs
- THEN the evidence becomes a local source artifact with provenance back to the remote instance
- AND the source artifact is not treated as personal endorsement

#### Scenario: Adopt remote evidence into personal reasoning

- GIVEN the user wants to adopt or endorse remote evidence
- WHEN a decision-log package is created from that evidence
- THEN the package records reasoning and provenance back to the remote instance
- AND answers can distinguish saved remote source from personal decision or knowledge

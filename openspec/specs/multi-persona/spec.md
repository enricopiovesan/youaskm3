# multi-persona Specification

Status: Future scope, planning decisions recorded

## Purpose

The multi-persona capability defines how more than one persona can maintain isolated or intentionally shared knowledge, gaps, decision logs, graph context, and assistant adapters.

A persona is a knowledge identity. It can represent a real person, a role/context, a project, or a domain-specific thinking identity. It is distinct from a hosted account.

## Requirements

### Requirement: Isolate persona knowledge by default

The system SHALL keep persona knowledge, gaps, conflicts, and reasoning graphs isolated unless sharing is explicitly configured.

#### Scenario: Ask as one persona

- GIVEN two personas exist in the same installation
- WHEN the active persona asks a question
- THEN answer context is selected only from that persona's allowed knowledge scope
- AND provenance records the active persona id

### Requirement: Use a hybrid scoped graph model

The system SHALL isolate persona graph views by default and allow explicit shared graph scopes.

#### Scenario: Share scoped reasoning

- GIVEN a package targets a shared scope
- WHEN graph extraction runs
- THEN extracted nodes and edges record the shared scope id
- AND only personas allowed to read that scope can use those graph elements for answers
- AND no cross-persona leakage occurs through default answer context selection

### Requirement: Support explicit shared scopes

The system SHALL support shared knowledge scopes only through explicit metadata and conflict policy. Shared scopes are read-only by default and writable only when an explicit policy allows writes.

#### Scenario: Share a decision log

- GIVEN a decision-log package is marked as shared
- WHEN it is ingested
- THEN the package records which personas may use it
- AND conflicts between persona-specific knowledge and shared knowledge are visible

#### Scenario: Write to shared scope

- GIVEN a shared scope allows writes by explicit policy
- WHEN a package writes to that shared scope
- THEN provenance records writer persona, package id, timestamp, and scope id
- AND no existing shared knowledge is silently overwritten

### Requirement: Select active persona explicitly

The system SHALL use a configured default persona for normal use and require explicit chat or CLI switching for other personas.

#### Scenario: Switch persona in chat

- GIVEN a user has multiple personas
- WHEN the user explicitly switches to another persona
- THEN the runtime records the new active persona id in session state and trace evidence
- AND the system does not silently infer or switch persona from message content

### Requirement: Resolve conflicts according to scope visibility

The system SHALL create shared conflict records only when conflicting scopes are mutually visible.

#### Scenario: Conflict across hidden scopes

- GIVEN two hidden persona scopes contain conflicting knowledge
- WHEN conflict detection runs
- THEN conflict records remain persona-local
- AND hidden scope content is not leaked

#### Scenario: Conflict across visible scopes

- GIVEN both conflicting scopes are mutually visible
- WHEN conflict detection runs
- THEN one shared conflict record may be created
- AND resolution requires a package targeting a scope allowed to see and resolve the conflict

### Requirement: Generate persona-aware assistant packages

The system SHALL allow generated assistant adapters to include persona context without hardcoding private knowledge into the adapter.

#### Scenario: Generate adapter for a persona

- GIVEN a persona profile exists
- WHEN assistant packaging runs
- THEN generated instructions may include allowed persona metadata
- AND do not embed private knowledge content outside the knowledge store

### Requirement: Reserve persona metadata before full multi-persona implementation

The system SHALL keep full multi-persona behavior future-scoped while reserving `persona_id`, `scope_id`, and package target scope fields in current schemas.

#### Scenario: First-MVP package uses one active persona

- GIVEN the first MVP has one active persona
- WHEN package metadata is validated
- THEN reserved persona and scope fields can be present
- AND full persona switching or shared-scope behavior is not required until this future capability is implemented

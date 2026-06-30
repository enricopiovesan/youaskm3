# reasoning-graph Specification

Status: Approved by brainstorming on 2026-06-29

## Purpose

The reasoning-graph capability extends the knowledge graph from source-document relationships into a structured second-brain graph that preserves concepts, questions, options, tradeoffs, assumptions, decisions, claims, gaps, citations, confidence, and validation evidence.

## Requirements

### Requirement: Extract a full reasoning graph from decision-log packages

The system SHALL deterministically extract full reasoning graph elements from structured decision-log packages.

#### Scenario: Build graph from a package

- GIVEN a validated decision-log package contains structured reasoning sections
- WHEN the graph update workflow runs
- THEN the graph contains nodes for `concept`, `question`, `option`, `tradeoff`, `assumption`, `decision`, `claim`, `open_question`, `source_gap`, `knowledge_note`, `citation`, `source_artifact`, `confidence_assessment`, and `validation_result`
- AND edges preserve provenance back to the package, decision log, knowledge note, and source gap when present

### Requirement: Use deterministic extraction as the required baseline

The system SHALL make deterministic extraction sufficient for first-MVP graph correctness and MAY add Traverse-governed agent enrichment when available.

#### Scenario: Agent enrichment unavailable

- GIVEN deterministic extraction succeeds
- AND agent enrichment is unavailable
- WHEN the graph update completes
- THEN the graph is valid for MVP acceptance
- AND metadata records that optional enrichment did not run

### Requirement: Select graph context by answer type

The answer workflow SHALL select reasoning graph context according to the final answer type.

#### Scenario: Answer a decision question

- GIVEN the user asks why a decision was made
- WHEN the answer workflow classifies the answer type as decision-oriented
- THEN context selection prioritizes decisions, rationale, tradeoffs, options, assumptions, citations, and validation results

#### Scenario: Answer an uncertainty question

- GIVEN the user asks what is unknown or risky
- WHEN the answer workflow classifies the answer type as uncertainty-oriented
- THEN context selection prioritizes assumptions, open questions, source gaps, confidence assessments, conflicting claims, and validation results

### Requirement: Classify answer type with traceable evidence

The system SHALL provide deterministic answer-type classification and MAY allow a Traverse-governed agent override when available.

#### Scenario: Record final answer type

- GIVEN a user asks a question
- WHEN the workflow selects graph context
- THEN the trace records deterministic answer type, optional agent-refined answer type, final selected answer type, and graph-context strategy

### Requirement: Handle conflicting graph knowledge transparently

The system SHALL not silently choose one side of conflicting knowledge.

#### Scenario: Conflict affects an answer

- GIVEN the reasoning graph contains conflicting claims or decisions relevant to the question
- WHEN the user asks a related question
- THEN the answer summarizes the conflict with evidence
- AND the workflow creates or updates a knowledge gap for conflict resolution

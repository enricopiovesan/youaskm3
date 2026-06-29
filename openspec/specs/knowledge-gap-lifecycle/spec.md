# knowledge-gap-lifecycle Specification

Status: Approved by brainstorming on 2026-06-29

## Purpose

The knowledge-gap-lifecycle capability defines how youaskm3 records missing, uncertain, ambiguous, or conflicting knowledge so the persona can improve the second brain instead of receiving unsupported answers.

## Requirements

### Requirement: Store gaps as structured markdown

The system SHALL store knowledge gaps as markdown files with structured front matter.

#### Scenario: Create a question-time gap

- GIVEN the answer workflow cannot answer from supported knowledge with sufficient confidence
- WHEN the user asks the question
- THEN the workflow creates or updates `knowledge/gaps/open/<gap-id>.md`
- AND the gap front matter records status, source question, persona id, trace id, confidence reason, timestamps, relevant graph nodes, and allowed resolution path

### Requirement: Create gaps during ingestion and validation

The system SHALL create or update gaps when decision-log package ingestion or validation detects missing, ambiguous, conflicting, or semantically rejected knowledge.

#### Scenario: Package semantic validation fails

- GIVEN optional semantic validation runs and rejects a package
- WHEN ingestion handles the failure
- THEN no final knowledge is ingested
- AND a gap records the validation result, package id, failed reason, and clarification need

### Requirement: Classify gap complexity

The system SHALL classify gaps using a deterministic baseline and MAY use a Traverse-governed agent override when available.

#### Scenario: Select the resolution path

- GIVEN a new or updated gap exists
- WHEN the workflow classifies its complexity
- THEN simple factual gaps allow direct chat resolution
- AND conceptual, strategic, architectural, or reasoning-heavy gaps require a decision-log package
- AND the trace records deterministic complexity, optional agent refinement, final complexity, and allowed resolution path

### Requirement: Resolve simple factual gaps through internal packages

The system SHALL convert direct chat factual resolutions into internal mini decision-log packages.

#### Scenario: Resolve a simple fact in chat

- GIVEN a gap is classified as a simple factual gap
- WHEN the user supplies the answer in chat
- THEN the runtime creates an internal package using the decision-log package schema with mode-specific required sections
- AND that package follows the same validation, provenance, graph extraction, and gap update path as external packages

### Requirement: Track conflicts as structured markdown

The system SHALL store sync and semantic conflict reports as markdown files with structured front matter.

#### Scenario: Detect a semantic conflict

- GIVEN sync or graph validation finds conflicting decisions or claims
- WHEN the conflict cannot be safely merged
- THEN the system writes `knowledge/conflicts/open/<conflict-id>.md`
- AND chat discloses the conflict only when it affects the answer or confidence
- AND resolution requires the `conflict_resolution` package mode

### Requirement: Expose unresolved gaps through CLI and chat

The system SHALL expose unresolved gaps through both `m3 gaps list` and the chat workflow.

#### Scenario: Ask what is missing

- GIVEN unresolved gaps exist
- WHEN the user asks "what do you still need from me?"
- THEN the chat answer summarizes relevant open gaps with provenance and resolution path
- AND the same gap set is available through `m3 gaps list`

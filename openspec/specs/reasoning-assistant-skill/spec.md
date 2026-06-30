# reasoning-assistant-skill Specification

Status: Approved by brainstorming on 2026-06-29

## Purpose

The reasoning-assistant-skill capability defines the LLM-agnostic assistant instructions used to help a persona reason through concepts, challenge assumptions, clarify ambiguity, and produce a decision-log package that youaskm3 can ingest as first-class personal knowledge.

## Requirements

### Requirement: Maintain an LLM-agnostic canonical skill

The system SHALL keep the canonical reasoning skill in provider-neutral source files with machine-readable metadata so generated ChatGPT, Claude, and future adapters stay consistent.

#### Scenario: Generate platform adapters

- GIVEN the canonical reasoning skill source has changed
- WHEN the assistant-skill generator runs
- THEN it renders ChatGPT and Claude adapter artifacts from the same source
- AND generated artifacts preserve the required interview protocol, package schema expectations, and CLI handoff instructions
- AND a drift check fails when generated adapters are stale

### Requirement: Conduct a natural reasoning interview

The skill SHALL behave as a conversational reasoning partner, not as a form or approval gate.

#### Scenario: Clarify a concept

- GIVEN the persona wants to reason through a concept
- WHEN the skill detects ambiguity, missing assumptions, or unresolved tradeoffs
- THEN it asks one question at a time
- AND each question presents options with pros, cons, and a recommendation when options are useful
- AND the skill challenges weak assumptions respectfully
- AND the skill continues until no blocking clarification remains

### Requirement: Produce a decision-log package

The skill SHALL produce a package directory containing `decision-log.md`, `knowledge-note.md`, and `metadata.json`.

#### Scenario: Finalize a reasoning session

- GIVEN the conversation has no open blocking clarifications
- WHEN the skill finalizes the session
- THEN it emits a decision-log package conforming to the decision-log package spec
- AND the package includes the generic next-step command `m3 ingest-decision-log /path/to/decision-log-package/`
- AND the package does not claim approval by a separate approver

### Requirement: Support package modes

The skill SHALL support first-MVP package modes for `knowledge_addition`, `gap_resolution`, `direct_fact_resolution`, and `conflict_resolution`.

#### Scenario: Resolve a reasoning-heavy gap

- GIVEN a gap requires conceptual, strategic, architectural, or reasoning-heavy clarification
- WHEN the skill produces a package
- THEN `metadata.json` records the mode and any linked `source_gap_id`
- AND the decision log records questions, options, tradeoffs, assumptions, decisions, claims, confidence, citations, and remaining non-blocking open questions

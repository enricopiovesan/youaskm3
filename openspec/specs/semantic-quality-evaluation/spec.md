# semantic-quality-evaluation Specification

Status: Future scope, planning decisions recorded

## Purpose

The semantic-quality-evaluation capability defines claim-level semantic validation, partial ingestion, and production-quality answer benchmarking after the deterministic first-MVP path is stable.

Generic benchmarks are required and committed. Persona-specific benchmarks are optional, local/private, and must not leak private content. Release-blocking benchmark gates cover full trust behavior.

## Requirements

### Requirement: Support claim-level partial ingestion

The system SHALL allow semantically accepted claims to be ingested while rejected claims become knowledge gaps only after deterministic claim extraction, optional Traverse-governed semantic refinement, provenance, and conflict semantics are stable.

#### Scenario: Partially ingest a package

- GIVEN a decision-log package contains multiple claims
- AND semantic validation rejects only some claims
- WHEN partial ingestion runs
- THEN accepted claims are ingested with provenance
- AND rejected claims create or update gaps
- AND the package records partial status instead of all-or-nothing success

#### Scenario: Refine extracted claims

- GIVEN deterministic claim extraction has produced claim records
- WHEN optional Traverse-governed semantic refinement is available
- THEN refinement may improve claim classification and validation
- AND trace evidence records extraction, refinement, and final validation results

### Requirement: Benchmark answer quality against fixtures

The system SHALL define production-quality answer evaluation fixtures that test correctness, grounding, provenance, unsupported claims, conflict disclosure, gap creation, citation completeness, and reasoning usefulness.

#### Scenario: Run answer benchmark

- GIVEN a benchmark corpus and expected evidence rules exist
- WHEN the benchmark runs
- THEN it reports correctness, grounded answer quality, unsupported claim rate, conflict disclosure rate, gap behavior, citation completeness, and provenance completeness

#### Scenario: Run persona-specific benchmark locally

- GIVEN a user has private persona-specific benchmark fixtures
- WHEN the local benchmark runs
- THEN results are stored locally
- AND private benchmark content is not required for CI or shared reporting

### Requirement: Keep benchmark output non-authoritative for knowledge

The system SHALL use benchmarks as quality evidence and not as a source of personal knowledge.

#### Scenario: Benchmark produces feedback

- GIVEN a benchmark detects a weak answer
- WHEN the report is generated
- THEN the report does not update the knowledge graph directly
- AND any product issue becomes a traceable ticket or gap

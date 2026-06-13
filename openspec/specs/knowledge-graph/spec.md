# knowledge-graph Specification

## Purpose

The knowledge-graph capability defines how youaskm3 represents graph context derived from normalized knowledge artifacts so chat answers can include source-backed relationships rather than isolated text snippets.

## Requirements

### Requirement: Produce a deterministic graph artifact

The system SHALL define a static graph artifact with deterministic node and edge ordering, stable ids, labels, source artifact references, source chunk references, extraction method, and confidence metadata.

#### Scenario: Build graph context from processed artifacts

- GIVEN normalized markdown artifacts exist with chunk ids and graph hints
- WHEN the graph artifact generation workflow runs
- THEN it produces an artifact conforming to `contracts/knowledge-graph.schema.json`

### Requirement: Preserve source evidence for graph relationships

The system SHALL require every graph edge used for answer context to reference the source artifact and chunk evidence that supports the relationship.

#### Scenario: Explain a relationship in chat

- GIVEN an answer uses a relationship between two concepts
- WHEN the graph evidence is rendered
- THEN the relationship includes source artifact ids, source chunk ids, labels, and confidence metadata

### Requirement: Expand graph context through a capability boundary

The system SHALL expose graph expansion through the `knowledge.graph.expand` capability instead of embedding graph traversal in the PWA.

#### Scenario: Expand context around retrieved chunks

- GIVEN retrieval returned source chunks for a prompt
- WHEN the answer workflow needs nearby graph context
- THEN Traverse executes `knowledge.graph.expand` and returns bounded graph evidence to the workflow

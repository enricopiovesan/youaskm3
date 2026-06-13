# MVP Architecture Handbook

<!--
youaskm3:fixture
source_type: book
source_label: original MVP fixture
artifact_id: fixture.book.mvp-architecture-handbook
-->

Architecture decisions for the first MVP are easiest to test when the repository contains a small handbook-style document. This fixture explains that artifact preparation and runtime execution are separate responsibilities.

## Chapter 1: Artifact Pipeline

The artifact pipeline converts source material into normalized markdown, search records, and graph-ready evidence. Build steps should be deterministic so the same repository state produces the same local index.

## Chapter 2: Runtime Execution

Runtime execution belongs behind Traverse-compatible contracts. Retrieval ranking, graph expansion, context packing, inference, validation, and formatting are business capabilities, not browser shortcuts.

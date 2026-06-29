# Expanded First MVP Decision Log

Status: Approved by brainstorming
Date: 2026-06-29
Owner: youaskm3 product/spec alignment

## Purpose

This decision log records the approved first-MVP expansion from generic chat over documents into a second-brain reasoning product. The decisions below are approved through the user's brainstorming process: one question at a time, options with pros and cons, and a recommendation, ending when no planned product questions remained.

## Product Definition

youaskm3 is not only chat over files. It is a reasoning-and-knowledge-cementing loop.

A persona works with an assistant in natural conversation to reason through a concept, challenge assumptions, clarify ambiguity, register decisions, and turn the resulting reasoning into durable personal knowledge. Future answers are only as good as the reasoning content captured into the knowledge store.

## Approved Decisions

1. The first MVP must use real knowledge artifacts, not placeholders.
2. The acceptance fixture may use a real public/shareable document and may also be manually validated with private user documents.
3. The system must support both supported-answer and human-in-the-loop defer paths.
4. The defer path is part of the core product: unsupported or uncertain answers create or update knowledge gaps.
5. A complete reasoning loop is in scope: the human supplies missing knowledge, the system updates context and graph, and later questions can use the new knowledge.
6. The UI remains chat-only. It must not display rebuild or pipeline internals.
7. Missing knowledge is handled conversationally. The assistant asks in chat when the answer is unavailable or uncertain.
8. Knowledge gaps are markdown files with structured front matter.
9. Gap clarification follows the same brainstorming process: one question at a time, options, pros and cons, and a recommendation.
10. A ChatGPT/Claude-style assistant skill creates decision-log packages from reasoning conversations.
11. The skill is a reasoning/capture surface. youaskm3 owns ingestion, validation, provenance, graph extraction, and answer behavior.
12. The canonical assistant skill definition must be LLM-agnostic.
13. ChatGPT and Claude adapters are generated from the canonical skill source.
14. The canonical skill source uses markdown plus structured manifest/schema.
15. The generated skill outputs a decision-log package, not only one markdown file.
16. The package contains `decision-log.md`, `knowledge-note.md`, and `metadata.json`.
17. Ingestion is CLI-managed only. There is no inbox watcher in the first MVP.
18. The first MVP accepts package directories only, not zip/archive files.
19. The CLI copies the package into the knowledge store and records the original import path as provenance.
20. `knowledge-note.md` is validated against `decision-log.md` before ingestion.
21. Deterministic validation is mandatory.
22. Traverse-governed semantic validation is optional when available.
23. If semantic validation is unavailable, deterministic validation can proceed.
24. If semantic validation runs and fails, the package is not ingested as final knowledge; a knowledge gap is created or updated.
25. For the first MVP, failed semantic validation blocks the whole package. Claim-level partial ingestion is future work.
26. Full concept graph extraction from decision-log packages is mandatory for the first MVP.
27. Graph extraction requires deterministic extraction from structured package sections, with optional Traverse agent enrichment when available.
28. Mandatory graph elements are `concept`, `question`, `option`, `tradeoff`, `assumption`, `decision`, `claim`, `open_question`, `source_gap`, `knowledge_note`, `citation`, `source_artifact`, `confidence_assessment`, and `validation_result`.
29. The reasoning graph requires a minimal formal schema plus executable fixtures with expected graph output.
30. Answer generation uses full graph context with answer-type filtering.
31. Answer-type classification has a deterministic baseline plus optional Traverse-governed agent override.
32. Conflicting knowledge is not silently resolved. The answer summarizes the conflict and creates or updates a knowledge gap.
33. Knowledge gaps can be created or updated during both question-time and ingestion/validation.
34. Unresolved gaps are available through both CLI and chat query.
35. Gap resolution can happen through direct chat for simple factual gaps and through decision-log packages for conceptual, strategic, architectural, or reasoning-heavy gaps.
36. Gap complexity has a deterministic baseline plus optional Traverse-governed agent override.
37. Direct chat gap resolution produces an internal mini decision-log package so every knowledge update follows one validation/provenance/graph path.
38. Internal mini packages use the same package schema with mode-specific required sections.
39. `conflict_resolution` is a first-MVP package mode.
40. The CLI uses one generic ingestion command: `m3 ingest-decision-log /path/to/package/`.
41. Generated skills include a generic CLI command template, not a hardcoded local path.
42. Normal markdown/source document ingestion remains supported as source knowledge. Decision-log packages are first-class reasoning inputs.
43. Answers cite provenance type, such as imported source document, decision log, knowledge note, human-provided direct fact, conflict resolution, or gap resolution.
44. Every supported answer includes concise evidence/provenance by default.
45. The MVP supports one active persona, with `persona_id` reserved in metadata/schema.
46. The workspace `knowledge/` directory is the default knowledge root, with optional `--knowledge-root`.
47. External knowledge roots require `m3 init --knowledge-root <path>` before writes.
48. Built-in multi-machine sync is in scope through a file-system sync folder for the first MVP.
49. youaskm3 does not build a hosted sync service in the first MVP.
50. Sync support must detect/report conflicts in decision-log packages, knowledge notes, gaps, graph artifacts, and metadata/index state.
51. Sync auto-merges safe append-only artifacts but stops and reports semantic conflicts.
52. Knowledge-writing commands run sync/conflict preflight checks; `m3 sync check` exists for manual inspection.
53. Chat discloses sync conflicts only when they affect the answer or confidence.
54. The MVP includes CLI-managed ingestion/setup and a local server/runtime for chat and MCP.
55. `m3 serve` tries to start or attach to Traverse and fails with a clear setup error if unavailable.
56. Runtime configuration lives in project config with CLI overrides.
57. `m3 init` is the first-run setup command.
58. `m3 init` supports full Traverse validation mode and explicit offline mode.
59. Offline mode can stage decision-log packages, but final validation, ingestion, and graph update require Traverse.
60. MVP acceptance includes both real user workflow commands and a final gate: `m3 mvp-check`.
61. The local runtime exposes HTTP JSON for the PWA and MCP backed by the same Traverse workflow.
62. The minimum chat UI supports asking, answering, concise evidence/provenance, defer/gap response, and direct simple fact resolution.
63. MCP parity includes answer question, list unresolved gaps, and resolve simple factual gaps.
64. Sync conflicts are markdown reports with structured front matter.
65. The expanded MVP is split into a new ticket tranche plus one final acceptance ticket.
66. Existing tickets `#120`, `#122`, `#135`, and `#136` remain as the Traverse-backed runtime baseline.
67. A new expanded final gate ticket links to `#136` instead of replacing it.

## Non-Negotiable Acceptance Rules

- No placeholders, fake workflow steps, skeleton manifests, all-zero digests, or browser fallback output can count as first-MVP acceptance.
- Product/business behavior that runs at runtime must run through Traverse-governed WASM microservices or WASM agents.
- The UI is a chat interface. It renders state returned by the runtime and does not own retrieval, graph traversal, context packing, inference selection, answer validation, response formatting, gap lifecycle, sync conflict policy, or graph extraction logic.
- CLI may manage setup, package ingestion, artifact building, sync checks, local server startup, and final acceptance gates, but product semantics must remain Traverse-governed where runtime behavior is involved.
- Missing Traverse public surfaces must become upstream Traverse requirements, not downstream shortcuts.

## Resulting First-MVP Shape

The expanded first MVP is a local-first second-brain product with:

- LLM-agnostic reasoning skill source.
- Generated ChatGPT and Claude skill adapters.
- Decision-log package output from assistant reasoning conversations.
- CLI ingestion of package directories.
- Validated provenance from decision log to knowledge note.
- Full reasoning graph extraction.
- Knowledge gaps and sync conflicts as structured markdown records.
- Chat answers using graph-aware answer-type filtering.
- Direct simple fact resolution through internal mini packages.
- Local HTTP JSON and MCP runtime surfaces backed by the same Traverse workflow.
- File-system sync-folder support with conflict detection.
- One final `m3 mvp-check` acceptance gate.

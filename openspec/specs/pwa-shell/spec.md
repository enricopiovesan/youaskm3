# pwa-shell Specification

## Purpose

The pwa-shell capability defines the installable, offline-capable browser shell that hosts the user-facing chat experience, presents sources and graph evidence, and delegates product/business behavior to Traverse-run WASM capabilities.

## Requirements

### Requirement: Provide an installable browser shell

The system SHALL provide a PWA shell that can be served as static assets and installed in modern browsers.

#### Scenario: Open the static site as an installable app

- GIVEN the youaskm3 site is published through GitHub Pages
- WHEN a user visits it in a supported browser
- THEN the browser can recognize it as an installable PWA shell

### Requirement: Present knowledge conversations with source context

The system SHALL reserve UI surfaces for chat responses and source attribution so the future interface can explain how results were derived.

#### Scenario: Render a source-backed answer shell

- GIVEN the chat interface returns a knowledge answer with sources
- WHEN the PWA shell renders the response
- THEN the UI can display both the answer and its source references

### Requirement: Keep the PWA as a UI-only application

The system SHALL keep retrieval ranking, graph traversal, context packing, inference selection, answer validation, and answer formatting outside the PWA and behind Traverse-compatible capability contracts.

#### Scenario: Submit a chat prompt

- GIVEN a user enters a prompt in the PWA
- WHEN the PWA starts the answer workflow
- THEN it sends the request to the configured Traverse app-facing endpoint or compatible local harness instead of computing the answer in browser UI code

#### Scenario: Keep Browser demo as an explicit fallback

- GIVEN Traverse local is the selected runtime provider
- AND Traverse returns an unavailable or execution failure
- WHEN the PWA renders the result
- THEN the failure remains visible to the user
- AND the PWA does not automatically switch to Browser demo
- AND Browser demo runs only after the user explicitly selects it as the provider

### Requirement: Render graph and trace evidence

The system SHALL provide UI surfaces for graph evidence and execution trace status returned by the runtime.

#### Scenario: Inspect why an answer was produced

- GIVEN a completed answer includes graph evidence and a trace reference
- WHEN the user opens the evidence view
- THEN the PWA can render cited sources, graph nodes or edges, and runtime status without needing private runtime internals

### Requirement: Demonstrate a real imported-document question path

The system SHALL support an acceptance path where a repo-safe fixture document is converted or normalized, included in generated artifacts, queried through the chat surface, and rendered with evidence.

#### Scenario: Ask about an imported fixture document

- GIVEN a fixture source document has been converted or normalized into markdown
- AND search and graph artifacts have been refreshed
- WHEN the user asks a question whose answer is supported by that fixture
- THEN the PWA renders answer text with at least one source reference
- AND the PWA renders graph or context evidence from the generated artifacts
- AND the response includes validation status and trace evidence

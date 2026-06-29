# mcp-interface Specification

## Purpose

The mcp-interface capability defines the portable MCP surface for youaskm3 so any compatible client can discover, call, and reason about the knowledge tools through explicit contracts instead of ad hoc runtime behavior.

## Requirements

### Requirement: Expose contract-defined knowledge tools

The system SHALL expose the initial MCP tool set through explicit contracts that describe each tool's purpose, inputs, and outputs.

#### Scenario: Discover the search tool contract

- GIVEN an MCP client connects to a youaskm3 instance
- WHEN it inspects the available tools
- THEN it can discover a contract-defined search tool with structured input and output expectations

### Requirement: Preserve portability across hosts

The system SHALL keep the MCP interface compatible with a WASM-native execution model so the same module can run in browser, CLI, and other supported hosts.

#### Scenario: Reuse the MCP module in a different host

- GIVEN the MCP module is compiled to the target WASM format
- WHEN a supported host loads it
- THEN the host can expose the same tool contract surface without host-specific behavior changes

### Requirement: Expose the same MVP capabilities through MCP

The system SHALL expose the MVP knowledge capabilities through Traverse MCP using the same contracts used by the app-facing runtime path.

#### Scenario: Call the answer workflow from an MCP client

- GIVEN the application bundle is registered with Traverse
- WHEN an MCP client discovers the available youaskm3 capabilities
- THEN it can inspect and execute the same `knowledge.query.answer` contract used by the PWA

#### Scenario: Use expanded second-brain tools from MCP

- GIVEN the local runtime exposes expanded first-MVP operations
- WHEN an MCP client discovers youaskm3 tools
- THEN it can call the answer workflow, list unresolved gaps, and resolve simple factual gaps through the same Traverse-backed workflow used by HTTP/PWA

### Requirement: Preserve trace and evidence references in MCP responses

The system SHALL return machine-readable trace, source, and graph evidence references through MCP responses when a capability produces an answer.

#### Scenario: Inspect answer evidence from MCP

- GIVEN an MCP client calls the answer workflow
- WHEN the workflow completes
- THEN the response includes answer text, citations, validation status, and trace identifiers equivalent to the app-facing response

#### Scenario: Inspect gap and conflict evidence from MCP

- GIVEN an MCP client calls an answer or gap operation
- WHEN the response includes a gap, direct resolution, or relevant conflict
- THEN the response includes machine-readable gap ids, conflict ids, provenance type, validation status, and trace identifiers equivalent to the app-facing response

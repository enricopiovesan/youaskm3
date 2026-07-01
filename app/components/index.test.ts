import { describe, expect, it } from "vitest";

import {
  authorInstancePath,
  browserComponentModulePath,
  browserRuntimeModulePath,
  chatTagName,
  componentNamespace,
  providerConfigPath,
  renderChatCard,
  renderRuntimeChatResponse,
  renderResultCard,
  renderSourceCard,
  resultTagName,
  searchIndexPath,
  knowledgeGraphPath,
  sourceTagName
} from "./index";

describe("componentNamespace", () => {
  it("returns the expected namespace", () => {
    expect(componentNamespace()).toBe("youaskm3");
  });
});

describe("renderRuntimeChatResponse", () => {
  it("renders supported runtime answers with provenance and evidence", () => {
    const markup = renderRuntimeChatResponse({
      answer: "Portable knowledge stays source-backed.",
      provenance_type: "traverse_runtime",
      citations: [
        {
          citation_id: "cite-1",
          source_path: "knowledge/blog/portable.md",
          excerpt: "source-backed excerpt"
        }
      ],
      graph_evidence: [{ node_ids: ["node-a"], edge_ids: ["edge-a"] }],
      trace_id: "trace-answer",
      validation: { status: "valid", checks: ["grounded"] }
    });

    expect(markup).toContain("Portable knowledge stays source-backed.");
    expect(markup).toContain("traverse_runtime");
    expect(markup).toContain("knowledge/blog/portable.md");
    expect(markup).toContain("node-a");
    expect(markup).toContain("Trace trace-answer");
  });

  it("renders unsupported deferrals and direct fact prompts from runtime gaps", () => {
    const markup = renderRuntimeChatResponse({
      answer: "",
      provenance_type: "traverse_runtime",
      citations: [],
      graph_evidence: [],
      trace_id: "trace-gap",
      validation: { status: "invalid", checks: ["missing-knowledge"] },
      failure: {
        code: "MISSING_KNOWLEDGE",
        message: "I need one simple fact before I can answer.",
        recoverable: true
      },
      gaps: [
        {
          gap_id: "gap-author-name",
          source_question: "What is the author name?",
          allowed_resolution_path: "direct_chat",
          final_complexity: "simple_factual"
        }
      ]
    });

    expect(markup).toContain('data-mode="deferral"');
    expect(markup).toContain("I need one simple fact before I can answer.");
    expect(markup).toContain('class="m3-direct-fact"');
    expect(markup).toContain('data-gap-id="gap-author-name"');
  });

  it("discloses only conflicts that affect the answer", () => {
    const markup = renderRuntimeChatResponse({
      answer: "The runtime boundary is Traverse-owned.",
      provenance_type: "traverse_runtime",
      citations: [],
      graph_evidence: [],
      trace_id: "trace-conflict",
      validation: { status: "partial", checks: ["conflict-disclosed"] },
      conflicts: [
        {
          conflict_id: "conflict-runtime-boundary",
          summary: "Two notes disagree about runtime ownership.",
          affects_answer: true
        },
        {
          conflict_id: "conflict-unrelated",
          summary: "Unrelated conflict.",
          affects_answer: false
        }
      ]
    });

    expect(markup).toContain("conflict-runtime-boundary");
    expect(markup).toContain("Two notes disagree about runtime ownership.");
    expect(markup).not.toContain("conflict-unrelated");
  });

  it("does not treat Browser demo or pipeline internals as acceptance UI", () => {
    const markup = renderRuntimeChatResponse({
      answer: "Answer comes from the runtime response.",
      provenance_type: "traverse_runtime",
      citations: [],
      graph_evidence: [],
      trace_id: "trace-clean",
      validation: { status: "valid", checks: ["formatted"] }
    });

    expect(markup).not.toContain("Browser demo");
    expect(markup).not.toContain("temporary harness");
    expect(markup).not.toContain("retrieval");
    expect(markup).not.toContain("context packing");
  });
});

describe("component tags", () => {
  it("exports the web component tag names", () => {
    expect(chatTagName()).toBe("m3-chat");
    expect(resultTagName()).toBe("m3-result");
    expect(sourceTagName()).toBe("m3-source");
    expect(browserComponentModulePath()).toBe("./components.js");
    expect(browserRuntimeModulePath()).toBe("./runtime.js");
    expect(providerConfigPath()).toBe("./provider-config.json");
    expect(authorInstancePath()).toBe("./author-instance.json");
    expect(searchIndexPath()).toBe("./search-index.json");
    expect(knowledgeGraphPath()).toBe("./knowledge-graph.json");
  });
});

describe("renderSourceCard", () => {
  it("renders source-backed content", () => {
    const markup = renderSourceCard({
      label: "Spec",
      title: "openspec/specs/mcp-interface/spec.md",
      detail: "Defines the contract-shaped MCP surface."
    });

    expect(markup).toContain("m3-source-card");
    expect(markup).toContain("openspec/specs/mcp-interface/spec.md");
    expect(markup).toContain("Defines the contract-shaped MCP surface.");
  });
});

describe("renderResultCard", () => {
  it("renders prompt and paragraphs", () => {
    const markup = renderResultCard({
      prompt: "What did I save about portable MCP clients?",
      paragraphs: [
        "Portable MCP work stays source-aware.",
        "The static shell hosts the future runtime."
      ]
    });

    expect(markup).toContain("m3-result-card");
    expect(markup).toContain("Portable MCP work stays source-aware.");
    expect(markup).toContain("The static shell hosts the future runtime.");
  });
});

describe("renderChatCard", () => {
  it("composes result and source sections", () => {
    const markup = renderChatCard({
      eyebrow: "M3 web components",
      title: "Source-backed shell",
      summary: "The shell reserves composable chat and source surfaces.",
      result: {
        prompt: "How is the shell structured?",
        paragraphs: ["It renders answer and source areas with stable tags."]
      },
      sources: [
        {
          label: "Roadmap",
          title: "SPEC.md, M3 - Chat interface",
          detail: "Requires an installable shell and source-backed display."
        }
      ]
    });

    expect(markup).toContain("m3-chat-shell");
    expect(markup).toContain("m3-result-card");
    expect(markup).toContain("m3-source-card");
    expect(markup).toContain("SPEC.md, M3 - Chat interface");
  });
});

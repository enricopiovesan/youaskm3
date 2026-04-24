import { describe, expect, it } from "vitest";

import {
  browserComponentModulePath,
  chatTagName,
  componentNamespace,
  renderChatCard,
  renderResultCard,
  renderSourceCard,
  resultTagName,
  sourceTagName
} from "./index";

describe("componentNamespace", () => {
  it("returns the expected namespace", () => {
    expect(componentNamespace()).toBe("youaskm3");
  });
});

describe("component tags", () => {
  it("exports the web component tag names", () => {
    expect(chatTagName()).toBe("m3-chat");
    expect(resultTagName()).toBe("m3-result");
    expect(sourceTagName()).toBe("m3-source");
    expect(browserComponentModulePath()).toBe("./components.js");
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

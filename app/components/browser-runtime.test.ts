import { describe, expect, it } from "vitest";

import {
  BROWSER_TOOL_DESCRIPTORS,
  SAMPLE_BROWSER_DOCUMENTS,
  browserToolNames,
  callBrowserTool,
  isBrowserToolName
} from "./browser-runtime";

describe("browser runtime tool descriptors", () => {
  it("exports the initial browser tool surface", () => {
    expect(browserToolNames()).toEqual(["search", "remember", "recall", "connect"]);
    expect(BROWSER_TOOL_DESCRIPTORS).toHaveLength(4);
    expect(isBrowserToolName("search")).toBe(true);
    expect(isBrowserToolName("status")).toBe(false);
  });
});

describe("callBrowserTool", () => {
  it("returns ranked search results", () => {
    const output = callBrowserTool("search", "portable", SAMPLE_BROWSER_DOCUMENTS);

    expect(output.type).toBe("search");
    if (output.type !== "search") {
      throw new Error("expected search output");
    }

    expect(output.results[0]?.id).toBe("portable-mcp");
    expect(output.results[0]?.score).toBeGreaterThan(0);
  });

  it("returns stable remember metadata", () => {
    const output = callBrowserTool("remember", "Portable browser note");

    expect(output).toEqual({
      type: "remember",
      payload: {
        accepted: true,
        entryId: "browser-portable-browser-note",
        storedPath: "knowledge/inputs/portable-browser-note.md"
      }
    });
  });

  it("returns source-aware recall matches", () => {
    const output = callBrowserTool("recall", "interface", SAMPLE_BROWSER_DOCUMENTS);

    expect(output.type).toBe("recall");
    if (output.type !== "recall") {
      throw new Error("expected recall output");
    }

    expect(output.matches[0]).toEqual({
      id: "mcp-interface-spec",
      title: "MCP interface spec",
      sourcePath: "openspec/specs/mcp-interface/spec.md",
      matchedOn: "title"
    });
  });

  it("returns topic connections for matching documents", () => {
    const output = callBrowserTool("connect", "Traverse", SAMPLE_BROWSER_DOCUMENTS);

    expect(output.type).toBe("connect");
    if (output.type !== "connect") {
      throw new Error("expected connect output");
    }

    expect(output.connections[0]).toEqual({
      from: "Traverse",
      to: "Portable MCP",
      relationship: "mentioned-in",
      supportingSourcePath: "knowledge/books/portable-mcp.md"
    });
  });

  it("rejects blank input", () => {
    expect(() => callBrowserTool("search", "   ")).toThrow(
      "missing browser runtime input"
    );
  });
});

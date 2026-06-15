import { describe, expect, it } from "vitest";

import {
  BROWSER_TOOL_DESCRIPTORS,
  browserArtifactState,
  browserToolNames,
  callBrowserTool,
  documentsFromSearchIndex,
  isBrowserToolName
} from "./browser-runtime";

const searchIndexFixture = {
  documents: [
    {
      id: "knowledge-blog-mvp-fixture-article-index",
      title: "Portable Knowledge Article",
      excerpt: "Portable knowledge keeps useful context in files a person can inspect.",
      source_path: "knowledge/blog/mvp-fixture-article/index.md"
    },
    {
      id: "knowledge-books-mvp-fixture-handbook-index",
      title: "MVP Architecture Handbook",
      excerpt: "Architecture decisions separate artifact preparation from runtime execution.",
      source_path: "knowledge/books/mvp-fixture-handbook/index.md"
    },
    {
      id: "knowledge-papers-mvp-fixture-note-index",
      title: "Source Grounding Note",
      excerpt: "Source grounding makes answer evidence visible.",
      source_path: "knowledge/papers/mvp-fixture-note/index.md"
    }
  ]
};

const artifactDocuments = documentsFromSearchIndex(searchIndexFixture);

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
    const output = callBrowserTool("search", "portable", artifactDocuments);

    expect(output.type).toBe("search");
    if (output.type !== "search") {
      throw new Error("expected search output");
    }

    expect(output.results[0]?.id).toBe("knowledge-blog-mvp-fixture-article-index");
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
    const output = callBrowserTool("recall", "grounding", artifactDocuments);

    expect(output.type).toBe("recall");
    if (output.type !== "recall") {
      throw new Error("expected recall output");
    }

    expect(output.matches[0]).toEqual({
      id: "knowledge-papers-mvp-fixture-note-index",
      title: "Source Grounding Note",
      sourcePath: "knowledge/papers/mvp-fixture-note/index.md",
      matchedOn: "title"
    });
  });

  it("returns topic connections for matching documents", () => {
    const output = callBrowserTool("connect", "architecture", artifactDocuments);

    expect(output.type).toBe("connect");
    if (output.type !== "connect") {
      throw new Error("expected connect output");
    }

    expect(output.connections[0]).toEqual({
      from: "architecture",
      to: "MVP Architecture Handbook",
      relationship: "mentioned-in",
      supportingSourcePath: "knowledge/books/mvp-fixture-handbook/index.md"
    });
  });

  it("rejects blank input", () => {
    expect(() => callBrowserTool("search", "   ")).toThrow(
      "missing browser runtime input"
    );
  });
});

describe("browserArtifactState", () => {
  it("loads generated search-index documents", () => {
    const state = browserArtifactState(searchIndexFixture, { graph_id: "fixture" });

    expect(state.status).toBe("ready");
    expect(state.documents).toHaveLength(3);
    expect(state.documents[0]).toEqual({
      id: "knowledge-blog-mvp-fixture-article-index",
      title: "Portable Knowledge Article",
      excerpt: "Portable knowledge keeps useful context in files a person can inspect.",
      sourcePath: "knowledge/blog/mvp-fixture-article/index.md"
    });
    expect(state.message).toBe("Loaded 3 generated knowledge documents.");
  });

  it("reports a missing artifact clearly", () => {
    const state = browserArtifactState(null);

    expect(state.status).toBe("missing");
    expect(state.documents).toEqual([]);
    expect(state.message).toBe("Generated search-index.json is missing or unavailable.");
  });

  it("reports an empty artifact clearly", () => {
    const state = browserArtifactState({ documents: [] });

    expect(state.status).toBe("empty");
    expect(state.documents).toEqual([]);
    expect(state.message).toBe(
      "Generated search-index.json does not contain searchable documents."
    );
  });
});

import { describe, expect, it } from "vitest";

import {
  BROWSER_TOOL_DESCRIPTORS,
  browserArtifactState,
  browserToolNames,
  callBrowserTool,
  documentsFromSearchIndex,
  isBrowserToolName,
  temporaryTraverseChatHarness
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
const graphFixture = {
  graph_id: "fixture",
  nodes: [
    {
      node_id: "document:knowledge-blog-mvp-fixture-article-index"
    },
    {
      node_id: "chunk:knowledge-blog-mvp-fixture-article-index:chunk:0"
    }
  ],
  edges: [
    {
      edge_id: "edge:knowledge-blog-mvp-fixture-article-index:document-source-chunk",
      from_node_id: "document:knowledge-blog-mvp-fixture-article-index",
      to_node_id: "chunk:knowledge-blog-mvp-fixture-article-index:chunk:0",
      source_chunk_ids: ["knowledge-blog-mvp-fixture-article-index:chunk:0"]
    }
  ]
};

describe("browser runtime tool descriptors", () => {
  it("exports the initial browser tool surface", () => {
    expect(browserToolNames()).toEqual(["answer", "search", "remember", "recall", "connect"]);
    expect(BROWSER_TOOL_DESCRIPTORS).toHaveLength(5);
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

  it("routes answer requests through the temporary Traverse-compatible harness", () => {
    const output = callBrowserTool("answer", "portable", artifactDocuments, graphFixture);

    expect(output.type).toBe("answer");
    if (output.type !== "answer") {
      throw new Error("expected answer output");
    }

    expect(output.payload.answer).toContain("Temporary harness answer");
    expect(output.payload.citations[0]).toEqual({
      citation_id: "cite-1",
      artifact_id: "knowledge-blog-mvp-fixture-article-index",
      chunk_id: "knowledge-blog-mvp-fixture-article-index:chunk:0",
      source_path: "knowledge/blog/mvp-fixture-article/index.md",
      excerpt: "Portable knowledge keeps useful context in files a person can inspect."
    });
    expect(output.payload.graph_evidence[0]).toEqual({
      node_ids: [
        "document:knowledge-blog-mvp-fixture-article-index",
        "chunk:knowledge-blog-mvp-fixture-article-index:chunk:0"
      ],
      edge_ids: ["edge:knowledge-blog-mvp-fixture-article-index:document-source-chunk"],
      supporting_chunk_ids: ["knowledge-blog-mvp-fixture-article-index:chunk:0"]
    });
    expect(output.payload.trace_id).toBe("harness:portable");
    expect(output.payload.validation).toEqual({
      status: "valid",
      checks: ["temporary-harness", "citations-present", "graph-evidence-present"]
    });
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

describe("temporaryTraverseChatHarness", () => {
  it("returns only the knowledge.query.answer contract keys", () => {
    const output = temporaryTraverseChatHarness(
      { query: "portable", max_sources: 1 },
      artifactDocuments,
      graphFixture
    );

    expect(Object.keys(output).sort()).toEqual([
      "answer",
      "citations",
      "graph_evidence",
      "trace_id",
      "validation"
    ]);
  });

  it("returns a partial validation when generated artifacts have no matching citation", () => {
    const output = temporaryTraverseChatHarness(
      { query: "not-present" },
      artifactDocuments,
      graphFixture
    );

    expect(output.citations).toEqual([]);
    expect(output.graph_evidence).toEqual([]);
    expect(output.trace_id).toBe("harness:not-present");
    expect(output.validation).toEqual({
      status: "partial",
      checks: ["temporary-harness", "citations-missing", "graph-evidence-unavailable"]
    });
  });

  it("returns a partial validation for an empty generated corpus", () => {
    const output = temporaryTraverseChatHarness({ query: "portable" }, [], graphFixture);

    expect(output.answer).toContain("could not find source-backed citations");
    expect(output.citations).toEqual([]);
    expect(output.validation.status).toBe("partial");
  });

  it("rejects blank answer input for the UI error state", () => {
    expect(() => temporaryTraverseChatHarness({ query: "   " }, artifactDocuments)).toThrow(
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

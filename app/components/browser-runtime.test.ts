import { readFileSync } from "node:fs";
import path from "node:path";

import { describe, expect, it } from "vitest";

import {
  BROWSER_TOOL_DESCRIPTORS,
  browserArtifactState,
  browserToolNames,
  buildPublicGapReport,
  buildTraverseRuntimeRequest,
  callBrowserTool,
  documentsFromSearchIndex,
  executeTraverseAnswerHttp,
  isMissingInferenceDependency,
  isBrowserToolName,
  mapTraverseAnswerFailure,
  submitPublicGapReport,
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

const hostedGapCollectorConfig = {
  enabled: true,
  endpoint: "https://collector.example.test/gaps",
  publicScope: {
    instanceId: "youaskm3-author",
    title: "youaskm3 author instance",
    shellUrl: "https://enricopiovesan.github.io/youaskm3/",
    knowledgeBase: "knowledge/"
  },
  fallbackIssueUrl: "https://github.com/enricopiovesan/youaskm3/issues/new",
  fallbackPackageName: "youaskm3-public-gap.md"
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

describe("Traverse inference dependency failures", () => {
  it("maps missing inference dependency failures into the answer envelope", () => {
    const output = mapTraverseAnswerFailure("portable", {
      code: "MISSING_MODEL_DEPENDENCY",
      message:
        "Inference dependency unavailable. Traverse could not resolve a compatible local or allowed server inference capability for this workspace.",
      recoverable: true,
      trace_id: "trace-missing-model"
    });

    expect(output).toEqual({
      answer:
        "Inference dependency unavailable. Traverse could not resolve a compatible local or allowed server inference capability for this workspace.",
      citations: [],
      graph_evidence: [],
      trace_id: "trace-missing-model",
      validation: {
        status: "invalid",
        checks: [
          "traverse-runtime-failure",
          "missing-inference-dependency",
          "MISSING_MODEL_DEPENDENCY"
        ]
      },
      failure: {
        code: "MISSING_MODEL_DEPENDENCY",
        message:
          "Inference dependency unavailable. Traverse could not resolve a compatible local or allowed server inference capability for this workspace.",
        recoverable: true
      }
    });
  });

  it("keeps generic Traverse execution failures separate from missing inference", () => {
    const output = mapTraverseAnswerFailure("portable", {
      code: "WASM_EXECUTION_FAILED",
      message: "Traverse execution failed before answer completion.",
      recoverable: false
    });

    expect(output.trace_id).toBe("traverse-failure:portable");
    expect(output.validation).toEqual({
      status: "invalid",
      checks: ["traverse-runtime-failure", "execution-failure", "WASM_EXECUTION_FAILED"]
    });
    expect(output.failure?.code).toBe("WASM_EXECUTION_FAILED");
  });

  it("recognizes the first-MVP missing inference failure code set", () => {
    expect(isMissingInferenceDependency("MISSING_MODEL_DEPENDENCY")).toBe(true);
    expect(isMissingInferenceDependency("INFERENCE_PROVIDER_UNAVAILABLE")).toBe(true);
    expect(isMissingInferenceDependency("INFERENCE_PLACEMENT_UNSATISFIED")).toBe(true);
    expect(isMissingInferenceDependency("INFERENCE_DEPENDENCY_REJECTED")).toBe(true);
    expect(isMissingInferenceDependency("WASM_EXECUTION_FAILED")).toBe(false);
  });

  it("keeps provider identifiers out of browser runtime business logic", () => {
    const runtimeSource = readFileSync(
      path.resolve(process.cwd(), "app", "components", "browser-runtime.ts"),
      "utf8"
    );

    expect(runtimeSource).not.toMatch(/\bOllama\b|\bWebLLM\b|llama\.cpp|openai|anthropic/i);
  });

  it("pins the Traverse manifest model dependency evidence fixture", () => {
    const appManifest = JSON.parse(
      readFileSync(
        path.resolve(process.cwd(), "traverse", "youaskm3-app", "manifest.json"),
        "utf8"
      )
    ) as {
      model_dependencies: Array<{
        candidates: Array<{
          candidate_id: string;
          metadata: Record<string, unknown>;
          placement_target: string;
          provider_implementation_id: string;
        }>;
        interface_id: string;
      }>;
    };
    const dependency = appManifest.model_dependencies.find(
      (modelDependency) => modelDependency.interface_id === "traverse.inference.generate"
    );

    expect(dependency).toBeDefined();
    expect(dependency?.candidates[0]).toMatchObject({
      candidate_id: "local-ollama-llama-3-2",
      provider_implementation_id: "ollama.local.generate",
      placement_target: "local",
      metadata: {
        live_conformance: "optional_TRAVERSE_RUN_LOCAL_OLLAMA_CONFORMANCE"
      }
    });
  });

  it("requires knowledge.infer to expose Traverse-owned dependency failure shape", () => {
    const inferContract = JSON.parse(
      readFileSync(
        path.resolve(
          process.cwd(),
          "contracts",
          "capabilities",
          "knowledge.infer.json"
        ),
        "utf8"
      )
    ) as {
      $defs: { failure: { required: string[] } };
      model_dependencies: Array<{ notes: string; required: boolean }>;
    };

    expect(inferContract.model_dependencies[0]?.required).toBe(true);
    expect(inferContract.model_dependencies[0]?.notes).toContain("Traverse resolves");
    expect(inferContract.$defs.failure.required).toEqual([
      "code",
      "message",
      "recoverable"
    ]);
  });
});

describe("Traverse HTTP answer adapter", () => {
  it("builds the public workspace execute runtime request", () => {
    const request = buildTraverseRuntimeRequest(
      { query: "portable", max_sources: 2 },
      {
        baseUrl: "http://127.0.0.1:8787",
        workspaceId: "youaskm3-local",
        requestId: "req-test"
      }
    );

    expect(request).toMatchObject({
      kind: "runtime_request",
      request_id: "req-test",
      intent: {
        capability_id: "knowledge.query.answer",
        capability_version: "0.1.0"
      },
      input: {
        query: "portable",
        max_sources: 2
      },
      context: {
        caller: "youaskm3-pwa",
        requested_target: "local"
      }
    });
  });

  it("maps Traverse HTTP success and public trace evidence into the answer envelope", async () => {
    const calls: Array<{ url: string; body?: string; method?: string }> = [];
    const fetchImpl = async (url: string, init?: { method?: string; body?: string }) => {
      calls.push({
        url,
        ...(init?.body ? { body: init.body } : {}),
        ...(init?.method ? { method: init.method } : {})
      });
      if (url.endsWith("/traces/exec-1")) {
        return {
          ok: true,
          status: 200,
          json: async () => ({ trace_id: "trace-1", public: true })
        };
      }

      return {
        ok: true,
        status: 200,
        json: async () => ({
          status: "succeeded",
          execution_id: "exec-1",
          output: {
            answer: "Traverse answer",
            citations: [
              {
                citation_id: "cite-1",
                artifact_id: "artifact-1",
                chunk_id: "artifact-1:chunk:0",
                source_path: "knowledge/papers/source.md",
                excerpt: "Evidence"
              }
            ],
            graph_evidence: [
              {
                node_ids: ["node-1"],
                edge_ids: ["edge-1"],
                supporting_chunk_ids: ["artifact-1:chunk:0"]
              }
            ],
            trace_id: "trace-1",
            validation: { status: "valid", checks: ["traverse-http-response"] }
          },
          links: {
            trace: "/v1/workspaces/youaskm3-local/traces/exec-1"
          }
        })
      };
    };

    const output = await executeTraverseAnswerHttp(
      { query: "portable" },
      {
        baseUrl: "http://127.0.0.1:8787",
        workspaceId: "youaskm3-local",
        requestId: "req-test"
      },
      fetchImpl
    );

    expect(calls[0]?.url).toBe("http://127.0.0.1:8787/v1/workspaces/youaskm3-local/execute");
    expect(JSON.parse(calls[0]?.body ?? "{}")).toMatchObject({
      request_id: "req-test",
      intent: { capability_id: "knowledge.query.answer" }
    });
    expect(calls[1]?.url).toBe("http://127.0.0.1:8787/v1/workspaces/youaskm3-local/traces/exec-1");
    expect(output.answer).toBe("Traverse answer");
    expect(output.citations[0]?.source_path).toBe("knowledge/papers/source.md");
    expect(output.graph_evidence[0]?.edge_ids).toEqual(["edge-1"]);
    expect(output.validation.checks).toContain("public-trace-fetched");
  });

  it("maps Traverse problem details into a stable UI failure envelope", async () => {
    const fetchImpl = async () => ({
      ok: false,
      status: 503,
      json: async () => ({
        code: "MISSING_MODEL_DEPENDENCY",
        title: "Service Unavailable",
        detail: "No compatible inference provider is available."
      })
    });

    const output = await executeTraverseAnswerHttp(
      { query: "portable" },
      { baseUrl: "http://127.0.0.1:8787" },
      fetchImpl
    );

    expect(output.failure).toEqual({
      code: "MISSING_MODEL_DEPENDENCY",
      message: "No compatible inference provider is available.",
      recoverable: true
    });
    expect(output.validation.checks).toContain("missing-inference-dependency");
  });

  it("does not fall back to the harness when a configured Traverse endpoint fails", async () => {
    const fetchImpl = async () => {
      throw new Error("connection refused");
    };

    const output = await executeTraverseAnswerHttp(
      { query: "portable" },
      { baseUrl: "http://127.0.0.1:8787" },
      fetchImpl
    );

    expect(output.answer).toBe("connection refused");
    expect(output.failure?.code).toBe("TRAVERSE_UNAVAILABLE");
    expect(output.trace_id).toBe("traverse-failure:portable");
    expect(output.validation.checks).toEqual([
      "traverse-runtime-failure",
      "execution-failure",
      "TRAVERSE_UNAVAILABLE"
    ]);
  });

  it("keeps the temporary harness out of the Traverse HTTP adapter", () => {
    const runtimeSource = readFileSync(
      path.resolve(process.cwd(), "app", "components", "browser-runtime.ts"),
      "utf8"
    );
    const httpAdapter = sourceSection(
      runtimeSource,
      "export async function executeTraverseAnswerHttp",
      "export function browserArtifactState"
    );
    const browserToolAdapter = sourceSection(
      runtimeSource,
      "export function callBrowserTool",
      "export function documentsFromSearchIndex"
    );

    expect(httpAdapter).toContain("mapTraverseAnswerFailure");
    expect(httpAdapter).not.toContain("temporaryTraverseChatHarness");
    expect(browserToolAdapter.match(/temporaryTraverseChatHarness/gu)).toHaveLength(1);
  });

  it("reports missing Traverse endpoint configuration separately", async () => {
    const output = await executeTraverseAnswerHttp(
      { query: "portable" },
      { baseUrl: "   " }
    );

    expect(output.failure).toEqual({
      code: "TRAVERSE_ENDPOINT_MISSING",
      message: "Traverse runtime endpoint is not configured.",
      recoverable: true
    });
  });
});

describe("hosted public gap report submission", () => {
  const publicGapInput = {
    question: "What does the public instance know about collector UX?",
    missingKnowledge: "No source-backed citation explains the public collector UX.",
    checkedEvidence: ["No source-backed citations were returned."],
    sourceUrl: "https://enricopiovesan.github.io/youaskm3/",
    reporterContext: "Visitor saw an unanswered public chat question."
  };

  it("builds the portable public gap report payload", () => {
    const report = buildPublicGapReport(
      publicGapInput,
      hostedGapCollectorConfig,
      "2026-07-05T13:00:00.000Z"
    );

    expect(report).toEqual({
      schema_version: "1.0.0",
      validation_version: "hosted-gap-collector/0.1.0",
      question: publicGapInput.question,
      missing_knowledge: publicGapInput.missingKnowledge,
      published_scope: hostedGapCollectorConfig.publicScope,
      checked_evidence: publicGapInput.checkedEvidence,
      source_url: publicGapInput.sourceUrl,
      submitted_at: "2026-07-05T13:00:00.000Z",
      reporter_context: publicGapInput.reporterContext
    });
  });

  it("submits to a configured collector without browser secrets", async () => {
    const requests: Array<{ input: string; body: unknown; headers: Record<string, string> }> = [];
    const output = await submitPublicGapReport(
      publicGapInput,
      hostedGapCollectorConfig,
      async (input, init) => {
        requests.push({
          input,
          body: JSON.parse(init?.body ?? "{}"),
          headers: init?.headers ?? {}
        });
        return {
          ok: true,
          status: 202,
          json: async () => ({ report_id: "gap-report-1" })
        };
      },
      "2026-07-05T13:00:00.000Z"
    );

    expect(output).toEqual({
      status: "submitted",
      reportId: "gap-report-1",
      code: "HOSTED_GAP_REPORT_ACCEPTED"
    });
    expect(requests[0]?.input).toBe("https://collector.example.test/gaps");
    expect(requests[0]?.headers).toEqual({
      accept: "application/json",
      "content-type": "application/json"
    });
    expect(JSON.stringify(requests[0]?.body)).not.toMatch(/token|secret|credential/i);
  });

  it("maps collector unavailable failures to the stable storage code", async () => {
    const output = await submitPublicGapReport(
      publicGapInput,
      hostedGapCollectorConfig,
      async () => {
        throw new Error("collector unavailable");
      },
      "2026-07-05T13:00:00.000Z"
    );

    expect(output).toMatchObject({
      status: "failed",
      code: "HOSTED_GAP_STORAGE_FAILED",
      recoverable: true
    });
  });

  it("rejects invalid public gap reports before posting", async () => {
    let called = false;
    const output = await submitPublicGapReport(
      { ...publicGapInput, missingKnowledge: "   " },
      hostedGapCollectorConfig,
      async () => {
        called = true;
        throw new Error("should not post invalid reports");
      },
      "2026-07-05T13:00:00.000Z"
    );

    expect(output).toMatchObject({
      status: "failed",
      code: "HOSTED_GAP_REPORT_INVALID"
    });
    expect(called).toBe(false);
  });

  it("returns manual fallback data when no collector is configured", async () => {
    const output = await submitPublicGapReport(publicGapInput, {
      ...hostedGapCollectorConfig,
      enabled: false,
      endpoint: null
    });

    expect(output).toMatchObject({
      status: "fallback",
      code: "HOSTED_GAP_COLLECTOR_NOT_CONFIGURED",
      downloadFileName: "youaskm3-public-gap.md"
    });
    if (output.status !== "fallback") {
      throw new Error("expected fallback output");
    }
    expect(output.fallbackMarkdown).toContain(publicGapInput.question);
    expect(output.fallbackMarkdown).toContain(publicGapInput.missingKnowledge);
  });
});

function sourceSection(source: string, startMarker: string, endMarker: string): string {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker);

  expect(start).toBeGreaterThanOrEqual(0);
  expect(end).toBeGreaterThan(start);

  return source.slice(start, end);
}

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

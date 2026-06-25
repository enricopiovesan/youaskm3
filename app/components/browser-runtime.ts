export type BrowserDocument = {
  id: string;
  title: string;
  excerpt: string;
  sourcePath: string;
};

export type SearchIndexDocument = {
  id: string;
  title: string;
  excerpt: string;
  source_path: string;
};

export type SearchIndexArtifact = {
  documents?: SearchIndexDocument[];
};

export type KnowledgeGraphArtifact = {
  graph_id?: string;
  nodes?: KnowledgeGraphNode[];
  edges?: KnowledgeGraphEdge[];
};

export type KnowledgeGraphNode = {
  node_id: string;
  source_chunk_ids?: string[];
};

export type KnowledgeGraphEdge = {
  edge_id: string;
  from_node_id: string;
  to_node_id: string;
  source_chunk_ids?: string[];
};

export type BrowserArtifactState =
  | {
      status: "ready";
      documents: BrowserDocument[];
      graph: KnowledgeGraphArtifact | null;
      message: string;
    }
  | {
      status: "empty" | "missing";
      documents: [];
      graph: KnowledgeGraphArtifact | null;
      message: string;
    };

export type BrowserSearchResult = BrowserDocument & {
  score: number;
};

export type BrowserRecallMatch = {
  id: string;
  title: string;
  sourcePath: string;
  matchedOn: "title" | "excerpt" | "sourcePath";
};

export type BrowserConnection = {
  from: string;
  to: string;
  relationship: string;
  supportingSourcePath: string;
};

export type BrowserRememberResult = {
  accepted: true;
  entryId: string;
  storedPath: string;
};

export type BrowserAnswerInput = {
  query: string;
  conversation_id?: string;
  artifact_scope?: string[];
  max_sources?: number;
};

export type TraverseHttpConfig = {
  baseUrl: string;
  workspaceId?: string;
  capabilityId?: string;
  capabilityVersion?: string;
  requestId?: string;
  requestedTarget?: "local" | "server" | "mcp";
  fetchTrace?: boolean;
};

export type TraverseFetchResponse = {
  ok: boolean;
  status: number;
  json: () => Promise<unknown>;
};

export type TraverseFetch = (
  input: string,
  init?: {
    method?: string;
    headers?: Record<string, string>;
    body?: string;
  }
) => Promise<TraverseFetchResponse>;

export type BrowserCitation = {
  citation_id: string;
  artifact_id: string;
  chunk_id: string;
  source_path: string;
  excerpt: string;
};

export type BrowserGraphEvidence = {
  node_ids: string[];
  edge_ids: string[];
  supporting_chunk_ids: string[];
};

export type BrowserValidation = {
  status: "valid" | "invalid" | "partial";
  checks: string[];
};

export type BrowserFailure = {
  code: string;
  message: string;
  recoverable: boolean;
};

export type BrowserAnswerResponse = {
  answer: string;
  citations: BrowserCitation[];
  graph_evidence: BrowserGraphEvidence[];
  trace_id: string;
  validation: BrowserValidation;
  failure?: BrowserFailure;
};

export type TraverseAnswerFailure = BrowserFailure & {
  trace_id?: string;
};

export type TraverseRuntimeRequest = {
  kind: "runtime_request";
  schema_version: "1.0.0";
  request_id: string;
  intent: {
    capability_id: string;
    capability_version: string;
  };
  input: BrowserAnswerInput;
  lookup: {
    scope: "prefer_private";
    allow_ambiguity: false;
  };
  context: {
    requested_target: "local" | "server" | "mcp";
    caller: "youaskm3-pwa";
  };
  governing_spec: "openspec/specs/traverse-integration/spec.md";
};

export const MISSING_INFERENCE_DEPENDENCY_CODES = [
  "MISSING_MODEL_DEPENDENCY",
  "INFERENCE_PROVIDER_UNAVAILABLE",
  "INFERENCE_PLACEMENT_UNSATISFIED",
  "INFERENCE_DEPENDENCY_REJECTED"
] as const;

export type BrowserRuntimeOutput =
  | { type: "answer"; payload: BrowserAnswerResponse }
  | { type: "search"; results: BrowserSearchResult[] }
  | { type: "remember"; payload: BrowserRememberResult }
  | { type: "recall"; matches: BrowserRecallMatch[] }
  | { type: "connect"; connections: BrowserConnection[] };

export type BrowserToolName = "answer" | "search" | "remember" | "recall" | "connect";

export const BROWSER_TOOL_DESCRIPTORS = [
  {
    name: "answer",
    description: "Temporary Traverse-compatible chat answer harness."
  },
  {
    name: "search",
    description: "Semantic and keyword hybrid search across indexed knowledge."
  },
  {
    name: "remember",
    description: "Ingest and index new content from text, URLs, or files."
  },
  {
    name: "recall",
    description: "Retrieve knowledge by topic, date, source, or tag."
  },
  {
    name: "connect",
    description: "Surface connections between concepts across the knowledge base."
  }
] as const;

export function browserToolNames(): BrowserToolName[] {
  return BROWSER_TOOL_DESCRIPTORS.map((tool) => tool.name);
}

export function isBrowserToolName(value: string): value is BrowserToolName {
  return browserToolNames().includes(value as BrowserToolName);
}

export function callBrowserTool(
  toolName: BrowserToolName,
  input: string,
  documents: BrowserDocument[] = [],
  graph: KnowledgeGraphArtifact | null = null
): BrowserRuntimeOutput {
  switch (toolName) {
    case "answer":
      return {
        type: "answer",
        payload: temporaryTraverseChatHarness({ query: input }, documents, graph)
      };
    case "search":
      return {
        type: "search",
        results: searchDocuments(input, documents)
      };
    case "remember":
      return {
        type: "remember",
        payload: rememberInput(input)
      };
    case "recall":
      return {
        type: "recall",
        matches: recallDocuments(input, documents)
      };
    case "connect":
      return {
        type: "connect",
        connections: connectDocuments(input, documents)
      };
  }
}

export function documentsFromSearchIndex(artifact: SearchIndexArtifact): BrowserDocument[] {
  return (artifact.documents ?? []).map((document) => ({
    id: document.id,
    title: document.title,
    excerpt: document.excerpt,
    sourcePath: document.source_path
  }));
}

export function isMissingInferenceDependency(code: string): boolean {
  return MISSING_INFERENCE_DEPENDENCY_CODES.includes(
    code as (typeof MISSING_INFERENCE_DEPENDENCY_CODES)[number]
  );
}

export function mapTraverseAnswerFailure(
  query: string,
  failure: TraverseAnswerFailure
): BrowserAnswerResponse {
  const missingInference = isMissingInferenceDependency(failure.code);

  return {
    answer: failure.message,
    citations: [],
    graph_evidence: [],
    trace_id: failure.trace_id ?? `traverse-failure:${slugify(query)}`,
    validation: {
      status: "invalid",
      checks: [
        "traverse-runtime-failure",
        missingInference ? "missing-inference-dependency" : "execution-failure",
        failure.code
      ]
    },
    failure: {
      code: failure.code,
      message: failure.message,
      recoverable: failure.recoverable
    }
  };
}

export function buildTraverseRuntimeRequest(
  input: BrowserAnswerInput,
  config: TraverseHttpConfig
): TraverseRuntimeRequest {
  const query = requireInput(input.query);
  const requestId = config.requestId ?? `youaskm3-${slugify(query)}`;

  return {
    kind: "runtime_request",
    schema_version: "1.0.0",
    request_id: requestId,
    intent: {
      capability_id: config.capabilityId ?? "knowledge.query.answer",
      capability_version: config.capabilityVersion ?? "0.1.0"
    },
    input: {
      ...input,
      query
    },
    lookup: {
      scope: "prefer_private",
      allow_ambiguity: false
    },
    context: {
      requested_target: config.requestedTarget ?? "local",
      caller: "youaskm3-pwa"
    },
    governing_spec: "openspec/specs/traverse-integration/spec.md"
  };
}

export async function executeTraverseAnswerHttp(
  input: BrowserAnswerInput,
  config: TraverseHttpConfig,
  fetchImpl: TraverseFetch = globalThis.fetch as TraverseFetch
): Promise<BrowserAnswerResponse> {
  const query = requireInput(input.query);
  if (config.baseUrl.trim().length === 0) {
    return mapTraverseAnswerFailure(query, {
      code: "TRAVERSE_ENDPOINT_MISSING",
      message: "Traverse runtime endpoint is not configured.",
      recoverable: true
    });
  }

  const workspaceId = encodeURIComponent(config.workspaceId ?? "local-default");
  const executeUrl = joinUrl(config.baseUrl, `/v1/workspaces/${workspaceId}/execute`);
  const request = buildTraverseRuntimeRequest({ ...input, query }, config);
  const response = await fetchImpl(executeUrl, {
    method: "POST",
    headers: {
      accept: "application/json",
      "content-type": "application/json"
    },
    body: JSON.stringify(request)
  }).catch((error: unknown) =>
    Promise.resolve({
      ok: false,
      status: 503,
      json: async () => ({
        code: "TRAVERSE_UNAVAILABLE",
        detail:
          error instanceof Error
            ? error.message
            : "Traverse runtime endpoint is unavailable."
      })
    })
  );
  const body = await response.json();

  if (!response.ok) {
    return mapTraverseAnswerFailure(query, problemToFailure(body, response.status));
  }

  const completedBody = await resolveAcceptedExecution(
    body,
    config,
    fetchImpl
  );
  const answer = traverseBodyToAnswer(query, completedBody);
  const traceUrl = traceLink(completedBody);
  if (traceUrl && config.fetchTrace !== false) {
    const trace = await fetchPublicTrace(config.baseUrl, traceUrl, fetchImpl);
    if (trace) {
      answer.validation.checks = [...answer.validation.checks, "public-trace-fetched"];
    }
  }

  return answer;
}

export function browserArtifactState(
  searchIndex: SearchIndexArtifact | null,
  graph: KnowledgeGraphArtifact | null = null
): BrowserArtifactState {
  if (!searchIndex) {
    return {
      status: "missing",
      documents: [],
      graph,
      message: "Generated search-index.json is missing or unavailable."
    };
  }

  const documents = documentsFromSearchIndex(searchIndex);
  if (documents.length === 0) {
    return {
      status: "empty",
      documents: [],
      graph,
      message: "Generated search-index.json does not contain searchable documents."
    };
  }

  return {
    status: "ready",
    documents,
    graph,
    message: `Loaded ${documents.length} generated knowledge documents.`
  };
}

async function resolveAcceptedExecution(
  body: unknown,
  config: TraverseHttpConfig,
  fetchImpl: TraverseFetch
): Promise<unknown> {
  const record = asRecord(body);
  if (record?.status !== "accepted") {
    return body;
  }

  const executionUrl = linkFrom(record, "execution");
  if (!executionUrl) {
    return body;
  }

  const response = await fetchImpl(joinUrl(config.baseUrl, executionUrl), {
    method: "GET",
    headers: {
      accept: "application/json"
    }
  });

  return response.ok ? response.json() : body;
}

async function fetchPublicTrace(
  baseUrl: string,
  tracePath: string,
  fetchImpl: TraverseFetch
): Promise<unknown | null> {
  const response = await fetchImpl(joinUrl(baseUrl, tracePath), {
    method: "GET",
    headers: {
      accept: "application/json"
    }
  });

  if (!response.ok) {
    return null;
  }

  return response.json();
}

function traverseBodyToAnswer(query: string, body: unknown): BrowserAnswerResponse {
  const record = asRecord(body);
  const error = asRecord(record?.error);
  if (error) {
    return mapTraverseAnswerFailure(query, {
      code: stringValue(error.code, "TRAVERSE_EXECUTION_FAILED"),
      message: stringValue(error.message, "Traverse execution failed."),
      recoverable: false,
      trace_id: stringValue(record?.execution_id, `traverse-failure:${slugify(query)}`)
    });
  }

  if (record?.status === "accepted") {
    return mapTraverseAnswerFailure(query, {
      code: "TRAVERSE_EXECUTION_ACCEPTED",
      message: "Traverse accepted the request but did not return a completed answer yet.",
      recoverable: true,
      trace_id: stringValue(record.execution_id, `traverse-pending:${slugify(query)}`)
    });
  }

  const output = asRecord(record?.output) ?? record;
  return {
    answer: stringValue(output?.answer, "Traverse returned an empty answer."),
    citations: arrayValue(output?.citations) as BrowserCitation[],
    graph_evidence: arrayValue(output?.graph_evidence) as BrowserGraphEvidence[],
    trace_id: stringValue(
      output?.trace_id,
      stringValue(record?.execution_id, `traverse:${slugify(query)}`)
    ),
    validation:
      (asRecord(output?.validation) as BrowserValidation | null) ?? {
        status: "partial",
        checks: ["traverse-http-response", "validation-missing"]
      }
  };
}

function problemToFailure(body: unknown, status: number): TraverseAnswerFailure {
  const record = asRecord(body);
  return {
    code: stringValue(record?.code, `HTTP_${status}`),
    message: stringValue(
      record?.detail,
      stringValue(record?.message, stringValue(record?.title, "Traverse request failed."))
    ),
    recoverable: status >= 500
  };
}

function traceLink(body: unknown): string | null {
  const record = asRecord(body);
  return linkFrom(record, "trace");
}

function linkFrom(record: Record<string, unknown> | null, key: string): string | null {
  const links = asRecord(record?.links);
  const value = links?.[key];
  return typeof value === "string" && value.length > 0 ? value : null;
}

function joinUrl(baseUrl: string, path: string): string {
  return `${baseUrl.replace(/\/+$/u, "")}/${path.replace(/^\/+/u, "")}`;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function stringValue(value: unknown, fallback: string): string {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}

function arrayValue(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

export function temporaryTraverseChatHarness(
  input: BrowserAnswerInput,
  documents: BrowserDocument[],
  graph: KnowledgeGraphArtifact | null = null
): BrowserAnswerResponse {
  const query = requireInput(input.query);
  const limit = Math.min(Math.max(input.max_sources ?? 3, 1), 20);
  const scopedDocuments =
    input.artifact_scope && input.artifact_scope.length > 0
      ? documents.filter((document) => input.artifact_scope?.includes(document.id))
      : documents;
  const results = searchDocuments(query, scopedDocuments).slice(0, limit);
  const citations = results.map((result, index) => ({
    citation_id: `cite-${index + 1}`,
    artifact_id: result.id,
    chunk_id: chunkIdForDocument(result.id),
    source_path: result.sourcePath,
    excerpt: result.excerpt
  }));
  const graphEvidence = graphEvidenceForCitations(citations, graph);

  return {
    answer:
      citations.length > 0
        ? `Temporary harness answer for "${query}" using ${citations.length} source-backed citation${citations.length === 1 ? "" : "s"}.`
        : `Temporary harness answer for "${query}" could not find source-backed citations in the generated artifacts.`,
    citations,
    graph_evidence: graphEvidence,
    trace_id: `harness:${slugify(query)}`,
    validation: {
      status: citations.length > 0 ? "valid" : "partial",
      checks: [
        "temporary-harness",
        citations.length > 0 ? "citations-present" : "citations-missing",
        graphEvidence.length > 0 ? "graph-evidence-present" : "graph-evidence-unavailable"
      ]
    }
  };
}

function searchDocuments(
  input: string,
  documents: BrowserDocument[]
): BrowserSearchResult[] {
  const terms = normalizeTerms(input);

  return documents
    .map((document) => {
      const title = document.title.toLowerCase();
      const excerpt = document.excerpt.toLowerCase();
      const score = terms.reduce((total, term) => {
        return (
          total +
          (title.includes(term) ? 3 : 0) +
          (excerpt.includes(term) ? 1 : 0)
        );
      }, 0);

      return {
        ...document,
        score
      };
    })
    .filter((result) => result.score > 0)
    .sort((left, right) => right.score - left.score || left.title.localeCompare(right.title));
}

function rememberInput(input: string): BrowserRememberResult {
  const normalized = requireInput(input);
  const slug = slugify(normalized);

  return {
    accepted: true,
    entryId: `browser-${slug}`,
    storedPath: `knowledge/inputs/${slug}.md`
  };
}

function recallDocuments(
  input: string,
  documents: BrowserDocument[]
): BrowserRecallMatch[] {
  const terms = normalizeTerms(input);

  return documents.flatMap((document) => {
    const matchedOn = findMatchedField(document, terms);
    if (!matchedOn) {
      return [];
    }

    return [
      {
        id: document.id,
        title: document.title,
        sourcePath: document.sourcePath,
        matchedOn
      }
    ];
  });
}

function connectDocuments(
  input: string,
  documents: BrowserDocument[]
): BrowserConnection[] {
  const topic = requireInput(input);
  const terms = normalizeTerms(topic);

  return documents
    .filter((document) => findMatchedField(document, terms) !== null)
    .map((document) => ({
      from: topic,
      to: document.title,
      relationship: "mentioned-in",
      supportingSourcePath: document.sourcePath
    }));
}

function graphEvidenceForCitations(
  citations: BrowserCitation[],
  graph: KnowledgeGraphArtifact | null
): BrowserGraphEvidence[] {
  if (!graph?.edges || citations.length === 0) {
    return [];
  }

  const citedChunks = new Set(citations.map((citation) => citation.chunk_id));
  const edges = graph.edges.filter((edge) =>
    (edge.source_chunk_ids ?? []).some((chunkId) => citedChunks.has(chunkId))
  );

  if (edges.length === 0) {
    return [];
  }

  return [
    {
      node_ids: unique(edges.flatMap((edge) => [edge.from_node_id, edge.to_node_id])),
      edge_ids: unique(edges.map((edge) => edge.edge_id)),
      supporting_chunk_ids: unique(
        edges.flatMap((edge) =>
          (edge.source_chunk_ids ?? []).filter((chunkId) => citedChunks.has(chunkId))
        )
      )
    }
  ];
}

function chunkIdForDocument(documentId: string): string {
  return `${documentId}:chunk:0`;
}

function findMatchedField(
  document: BrowserDocument,
  terms: string[]
): BrowserRecallMatch["matchedOn"] | null {
  if (containsAllTerms(document.title, terms)) {
    return "title";
  }

  if (containsAllTerms(document.excerpt, terms)) {
    return "excerpt";
  }

  if (containsAllTerms(document.sourcePath, terms)) {
    return "sourcePath";
  }

  return null;
}

function containsAllTerms(value: string, terms: string[]): boolean {
  const haystack = value.toLowerCase();
  return terms.every((term) => haystack.includes(term));
}

function normalizeTerms(input: string): string[] {
  return requireInput(input)
    .toLowerCase()
    .split(/\s+/)
    .filter(Boolean);
}

function requireInput(input: string): string {
  const normalized = input.trim();
  if (!normalized) {
    throw new Error("missing browser runtime input");
  }

  return normalized;
}

function slugify(value: string): string {
  const slug = value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

  return slug || "entry";
}

function unique(values: string[]): string[] {
  return Array.from(new Set(values));
}

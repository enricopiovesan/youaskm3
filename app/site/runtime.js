export const TOOL_DESCRIPTORS = [
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
];

export function callBrowserTool(toolName, input, documents = [], graph = null) {
  switch (toolName) {
    case "answer":
      return {
        type: "answer",
        payload: temporaryTraverseChatHarness({ query: input }, documents, graph)
      };
    case "search":
      return { type: "search", results: searchDocuments(input, documents) };
    case "remember":
      return { type: "remember", payload: rememberInput(input) };
    case "recall":
      return { type: "recall", matches: recallDocuments(input, documents) };
    case "connect":
      return { type: "connect", connections: connectDocuments(input, documents) };
    default:
      throw new Error(`unknown browser tool: ${toolName}`);
  }
}

export function buildTraverseRuntimeRequest(input, config) {
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
    input: { ...input, query },
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

export async function executeTraverseAnswerHttp(input, config, fetchImpl = globalThis.fetch) {
  const query = requireInput(input.query);
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
  });
  const body = await response.json();

  if (!response.ok) {
    return mapTraverseAnswerFailure(query, problemToFailure(body, response.status));
  }

  const completedBody = await resolveAcceptedExecution(body, config, fetchImpl);
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

export function isMissingInferenceDependency(code) {
  return [
    "MISSING_MODEL_DEPENDENCY",
    "INFERENCE_PROVIDER_UNAVAILABLE",
    "INFERENCE_PLACEMENT_UNSATISFIED",
    "INFERENCE_DEPENDENCY_REJECTED"
  ].includes(code);
}

export function mapTraverseAnswerFailure(query, failure) {
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

export function temporaryTraverseChatHarness(input, documents, graph = null) {
  const query = requireInput(input.query);
  const limit = Math.min(Math.max(input.max_sources ?? 3, 1), 20);
  const scopedDocuments =
    input.artifact_scope && input.artifact_scope.length > 0
      ? documents.filter((document) => input.artifact_scope.includes(document.id))
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

export function documentsFromSearchIndex(artifact) {
  return (artifact.documents ?? []).map((document) => ({
    id: document.id,
    title: document.title,
    excerpt: document.excerpt,
    sourcePath: document.source_path
  }));
}

export function browserArtifactState(searchIndex, graph = null) {
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

export async function loadBrowserArtifacts() {
  const searchIndex = await fetchJson("./search-index.json", true);
  const graph = await fetchJson("./knowledge-graph.json", false);
  return browserArtifactState(searchIndex, graph);
}

async function resolveAcceptedExecution(body, config, fetchImpl) {
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
    headers: { accept: "application/json" }
  });

  return response.ok ? response.json() : body;
}

async function fetchPublicTrace(baseUrl, tracePath, fetchImpl) {
  const response = await fetchImpl(joinUrl(baseUrl, tracePath), {
    method: "GET",
    headers: { accept: "application/json" }
  });

  return response.ok ? response.json() : null;
}

function traverseBodyToAnswer(query, body) {
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
    citations: arrayValue(output?.citations),
    graph_evidence: arrayValue(output?.graph_evidence),
    trace_id: stringValue(
      output?.trace_id,
      stringValue(record?.execution_id, `traverse:${slugify(query)}`)
    ),
    validation: asRecord(output?.validation) ?? {
      status: "partial",
      checks: ["traverse-http-response", "validation-missing"]
    }
  };
}

function problemToFailure(body, status) {
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

function traceLink(body) {
  return linkFrom(asRecord(body), "trace");
}

function linkFrom(record, key) {
  const links = asRecord(record?.links);
  const value = links?.[key];
  return typeof value === "string" && value.length > 0 ? value : null;
}

function joinUrl(baseUrl, path) {
  return `${baseUrl.replace(/\/+$/u, "")}/${path.replace(/^\/+/u, "")}`;
}

function asRecord(value) {
  return value && typeof value === "object" && !Array.isArray(value) ? value : null;
}

function stringValue(value, fallback) {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}

function arrayValue(value) {
  return Array.isArray(value) ? value : [];
}

async function fetchJson(path, required) {
  const response = await fetch(path);
  if (!response.ok) {
    if (required) {
      throw new Error(`failed to load ${path}`);
    }
    return null;
  }

  return response.json();
}

function searchDocuments(input, documents) {
  const terms = normalizeTerms(input);

  return documents
    .map((document) => {
      const title = document.title.toLowerCase();
      const excerpt = document.excerpt.toLowerCase();
      const score = terms.reduce(
        (total, term) =>
          total + (title.includes(term) ? 3 : 0) + (excerpt.includes(term) ? 1 : 0),
        0
      );

      return { ...document, score };
    })
    .filter((document) => document.score > 0)
    .sort((left, right) => right.score - left.score || left.title.localeCompare(right.title));
}

function rememberInput(input) {
  const normalized = requireInput(input);
  const slug = slugify(normalized);

  return {
    accepted: true,
    entryId: `browser-${slug}`,
    storedPath: `knowledge/inputs/${slug}.md`
  };
}

function recallDocuments(input, documents) {
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

function connectDocuments(input, documents) {
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

function graphEvidenceForCitations(citations, graph) {
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

function chunkIdForDocument(documentId) {
  return `${documentId}:chunk:0`;
}

function findMatchedField(document, terms) {
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

function containsAllTerms(value, terms) {
  const haystack = value.toLowerCase();
  return terms.every((term) => haystack.includes(term));
}

function normalizeTerms(input) {
  return requireInput(input)
    .toLowerCase()
    .split(/\s+/)
    .filter(Boolean);
}

function requireInput(input) {
  const normalized = input.trim();
  if (!normalized) {
    throw new Error("missing browser runtime input");
  }

  return normalized;
}

function slugify(value) {
  const slug = value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

  return slug || "entry";
}

function unique(values) {
  return Array.from(new Set(values));
}

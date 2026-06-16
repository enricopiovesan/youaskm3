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

export type BrowserAnswerResponse = {
  answer: string;
  citations: BrowserCitation[];
  graph_evidence: BrowserGraphEvidence[];
  trace_id: string;
  validation: BrowserValidation;
};

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

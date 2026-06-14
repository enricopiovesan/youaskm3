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
  nodes?: unknown[];
  edges?: unknown[];
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

export type BrowserRuntimeOutput =
  | { type: "search"; results: BrowserSearchResult[] }
  | { type: "remember"; payload: BrowserRememberResult }
  | { type: "recall"; matches: BrowserRecallMatch[] }
  | { type: "connect"; connections: BrowserConnection[] };

export type BrowserToolName = "search" | "remember" | "recall" | "connect";

export const BROWSER_TOOL_DESCRIPTORS = [
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
  documents: BrowserDocument[] = []
): BrowserRuntimeOutput {
  switch (toolName) {
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

export type BrowserDocument = {
  id: string;
  title: string;
  excerpt: string;
  sourcePath: string;
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

export const SAMPLE_BROWSER_DOCUMENTS: BrowserDocument[] = [
  {
    id: "portable-mcp",
    title: "Portable MCP",
    excerpt: "Traverse-compatible clients can discover and call contract-defined tools.",
    sourcePath: "knowledge/books/portable-mcp.md"
  },
  {
    id: "pwa-shell",
    title: "PWA shell roadmap",
    excerpt: "The browser shell should stay static, installable, and source-aware.",
    sourcePath: "SPEC.md#8-milestones"
  },
  {
    id: "mcp-interface-spec",
    title: "MCP interface spec",
    excerpt: "The interface defines discoverable search, remember, recall, and connect tools.",
    sourcePath: "openspec/specs/mcp-interface/spec.md"
  }
];

export function browserToolNames(): BrowserToolName[] {
  return BROWSER_TOOL_DESCRIPTORS.map((tool) => tool.name);
}

export function isBrowserToolName(value: string): value is BrowserToolName {
  return browserToolNames().includes(value as BrowserToolName);
}

export function callBrowserTool(
  toolName: BrowserToolName,
  input: string,
  documents: BrowserDocument[] = SAMPLE_BROWSER_DOCUMENTS
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

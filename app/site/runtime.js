export const TOOL_DESCRIPTORS = [
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

export function callBrowserTool(toolName, input, documents = []) {
  switch (toolName) {
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

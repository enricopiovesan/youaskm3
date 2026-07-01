export const COMPONENT_NAMESPACE = "youaskm3";
export const COMPONENT_TAGS = {
  chat: "m3-chat",
  result: "m3-result",
  source: "m3-source"
} as const;

export type SourceCard = {
  label: string;
  title: string;
  detail: string;
};

export type ResultCard = {
  prompt: string;
  paragraphs: string[];
};

export type ChatCard = {
  eyebrow: string;
  title: string;
  summary: string;
  result: ResultCard;
  sources: SourceCard[];
};

export type RuntimeCitation = {
  citation_id: string;
  source_path: string;
  excerpt: string;
};

export type RuntimeGraphEvidence = {
  node_ids: string[];
  edge_ids: string[];
};

export type RuntimeGap = {
  gap_id: string;
  source_question: string;
  allowed_resolution_path: string;
  final_complexity: string;
};

export type RuntimeConflict = {
  conflict_id: string;
  summary: string;
  affects_answer: boolean;
};

export type RuntimeChatResponse = {
  answer: string;
  provenance_type: string;
  citations: RuntimeCitation[];
  graph_evidence: RuntimeGraphEvidence[];
  trace_id: string;
  validation: {
    status: "valid" | "invalid" | "partial";
    checks: string[];
  };
  gaps?: RuntimeGap[];
  conflicts?: RuntimeConflict[];
  failure?: {
    code: string;
    message: string;
    recoverable: boolean;
  };
};

export function componentNamespace(): string {
  return COMPONENT_NAMESPACE;
}

export function sourceTagName(): string {
  return COMPONENT_TAGS.source;
}

export function resultTagName(): string {
  return COMPONENT_TAGS.result;
}

export function chatTagName(): string {
  return COMPONENT_TAGS.chat;
}

export function renderSourceCard(source: SourceCard): string {
  return [
    `<article class="m3-source-card">`,
    `<span class="m3-source-label">${escapeHtml(source.label)}</span>`,
    `<strong>${escapeHtml(source.title)}</strong>`,
    `<div>${escapeHtml(source.detail)}</div>`,
    `</article>`
  ].join("");
}

export function renderResultCard(result: ResultCard): string {
  const paragraphs = result.paragraphs
    .map((paragraph) => `<p>${escapeHtml(paragraph)}</p>`)
    .join("");

  return [
    `<section class="m3-result-card">`,
    `<p class="m3-prompt">${escapeHtml(result.prompt)}</p>`,
    `<div class="m3-answer">${paragraphs}</div>`,
    `</section>`
  ].join("");
}

export function renderChatCard(chat: ChatCard): string {
  const sources = chat.sources.map(renderSourceCard).join("");

  return [
    `<section class="m3-chat-shell">`,
    `<div class="m3-chat-copy">`,
    `<span class="m3-chat-eyebrow">${escapeHtml(chat.eyebrow)}</span>`,
    `<h2>${escapeHtml(chat.title)}</h2>`,
    `<p class="m3-chat-summary">${escapeHtml(chat.summary)}</p>`,
    renderResultCard(chat.result),
    `</div>`,
    `<aside class="m3-chat-sources">${sources}</aside>`,
    `</section>`
  ].join("");
}

export function renderRuntimeChatResponse(response: RuntimeChatResponse): string {
  const directFactGaps = (response.gaps ?? []).filter(
    (gap) => gap.allowed_resolution_path === "direct_chat"
  );
  const relevantConflicts = (response.conflicts ?? []).filter(
    (conflict) => conflict.affects_answer
  );
  const mode = response.failure ? "deferral" : "answer";

  return [
    `<article class="m3-runtime-chat" data-mode="${mode}">`,
    `<section class="m3-runtime-answer">`,
    `<p class="m3-runtime-validation">${escapeHtml(response.validation.status)}</p>`,
    `<p class="m3-runtime-provenance">${escapeHtml(response.provenance_type)}</p>`,
    `<p class="m3-runtime-trace">Trace ${escapeHtml(response.trace_id)}</p>`,
    response.failure
      ? `<p class="m3-runtime-deferral">${escapeHtml(response.failure.message)}</p>`
      : `<p>${escapeHtml(response.answer)}</p>`,
    `</section>`,
    renderRuntimeCitations(response.citations),
    renderRuntimeGraphEvidence(response.graph_evidence),
    renderRuntimeGaps(directFactGaps),
    renderRuntimeConflicts(relevantConflicts),
    `</article>`
  ].join("");
}

export function browserComponentModulePath(): string {
  return "./components.js";
}

export function browserRuntimeModulePath(): string {
  return "./runtime.js";
}

export function providerConfigPath(): string {
  return "./provider-config.json";
}

export function authorInstancePath(): string {
  return "./author-instance.json";
}

export function searchIndexPath(): string {
  return "./search-index.json";
}

export function knowledgeGraphPath(): string {
  return "./knowledge-graph.json";
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function renderRuntimeCitations(citations: RuntimeCitation[]): string {
  if (citations.length === 0) {
    return "";
  }

  const items = citations
    .map(
      (citation) =>
        `<li><strong>${escapeHtml(citation.citation_id)}</strong> ${escapeHtml(citation.source_path)} <span>${escapeHtml(citation.excerpt)}</span></li>`
    )
    .join("");

  return `<section class="m3-runtime-evidence" aria-label="Citations"><h3>Citations</h3><ul>${items}</ul></section>`;
}

function renderRuntimeGraphEvidence(evidence: RuntimeGraphEvidence[]): string {
  if (evidence.length === 0) {
    return "";
  }

  const items = evidence
    .map(
      (entry) =>
        `<li>Nodes ${escapeHtml(entry.node_ids.join(", "))}; edges ${escapeHtml(entry.edge_ids.join(", "))}</li>`
    )
    .join("");

  return `<section class="m3-runtime-graph" aria-label="Graph evidence"><h3>Graph evidence</h3><ul>${items}</ul></section>`;
}

function renderRuntimeGaps(gaps: RuntimeGap[]): string {
  if (gaps.length === 0) {
    return "";
  }

  const forms = gaps
    .map(
      (gap) =>
        `<form class="m3-direct-fact" data-gap-id="${escapeHtml(gap.gap_id)}"><label>${escapeHtml(gap.source_question)}<input name="answer" autocomplete="off" /></label><button type="submit">Resolve fact</button></form>`
    )
    .join("");

  return `<section class="m3-runtime-gaps" aria-label="Knowledge gaps">${forms}</section>`;
}

function renderRuntimeConflicts(conflicts: RuntimeConflict[]): string {
  if (conflicts.length === 0) {
    return "";
  }

  const items = conflicts
    .map(
      (conflict) =>
        `<li><strong>${escapeHtml(conflict.conflict_id)}</strong> ${escapeHtml(conflict.summary)}</li>`
    )
    .join("");

  return `<section class="m3-runtime-conflicts" aria-label="Relevant conflicts"><h3>Relevant conflicts</h3><ul>${items}</ul></section>`;
}

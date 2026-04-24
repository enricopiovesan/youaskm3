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

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

import { callBrowserTool, TOOL_DESCRIPTORS } from "./runtime.js";

const PROVIDER_STORAGE_KEY = "youaskm3.provider-config";

const styles = `
  :host {
    display: block;
  }

  .eyebrow,
  .source-label,
  .tool-chip {
    display: inline-flex;
    align-items: center;
    gap: 10px;
    padding: 8px 12px;
    border-radius: 999px;
    background: rgba(189, 139, 57, 0.15);
    color: #17352f;
    font-size: 0.8rem;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    border: 0;
  }

  .chat-shell {
    display: grid;
    grid-template-columns: 1.45fr 0.95fr;
    gap: 18px;
  }

  .panel {
    backdrop-filter: blur(18px);
    background: rgba(255, 252, 246, 0.9);
    border: 1px solid rgba(23, 53, 47, 0.14);
    border-radius: 28px;
    box-shadow: 0 24px 80px rgba(23, 53, 47, 0.12);
    padding: 24px;
  }

  h2 {
    margin: 18px 0 12px;
    font-size: clamp(1.8rem, 4vw, 2.7rem);
    line-height: 1;
    letter-spacing: -0.04em;
    color: #17352f;
  }

  p,
  div,
  li,
  strong,
  label {
    color: #17352f;
  }

  .summary,
  .detail,
  .answer p,
  .tool-description {
    color: #587168;
    line-height: 1.6;
  }

  .controls {
    display: grid;
    gap: 14px;
    margin-top: 18px;
  }

  .tool-list {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
  }

  .tool-chip[aria-pressed="true"] {
    background: #17352f;
    color: #f7f0e3;
  }

  .tool-copy {
    display: grid;
    gap: 4px;
  }

  .provider-shell {
    display: grid;
    gap: 12px;
    padding: 14px 16px;
    border-radius: 18px;
    background: rgba(23, 53, 47, 0.04);
    border: 1px solid rgba(23, 53, 47, 0.08);
  }

  .provider-grid {
    display: grid;
    gap: 10px;
  }

  select,
  input[type="password"] {
    width: 100%;
    padding: 12px 14px;
    border-radius: 14px;
    border: 1px solid rgba(23, 53, 47, 0.14);
    background: rgba(255, 252, 246, 0.9);
    font: inherit;
  }

  .provider-meta,
  .instance-meta {
    color: #587168;
    line-height: 1.6;
  }

  textarea {
    width: 100%;
    min-height: 110px;
    padding: 14px 16px;
    border-radius: 18px;
    border: 1px solid rgba(23, 53, 47, 0.14);
    background: rgba(255, 252, 246, 0.9);
    resize: vertical;
    font: inherit;
  }

  .result-card {
    margin-top: 18px;
  }

  .prompt {
    margin: 0 0 16px;
    padding: 16px 18px;
    border-radius: 20px;
    background: #efe7d8;
    font-size: 1rem;
  }

  .answer {
    padding: 18px 18px 0;
    border-top: 1px solid rgba(23, 53, 47, 0.14);
  }

  .sources {
    display: grid;
    gap: 12px;
  }

  .source-card {
    padding: 16px;
    border-radius: 20px;
    background: rgba(23, 53, 47, 0.04);
    border: 1px solid rgba(23, 53, 47, 0.08);
  }

  .source-card strong {
    display: block;
    margin: 8px 0 6px;
  }

  .runtime-note {
    margin-top: 14px;
    padding: 12px 14px;
    border-radius: 16px;
    background: rgba(23, 53, 47, 0.06);
    color: #587168;
  }

  @media (max-width: 860px) {
    .chat-shell {
      grid-template-columns: 1fr;
    }

    .panel {
      padding: 20px;
    }
  }
`;

function template(content) {
  return `<style>${styles}</style>${content}`;
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function toolToSummary(toolName, output) {
  switch (toolName) {
    case "search":
      return {
        prompt: "Browser runtime tool: search",
        paragraphs:
          output.results.length > 0
            ? output.results.map(
                (result) => `${result.title} (${result.sourcePath}) scored ${result.score.toFixed(1)}.`
              )
            : ["No browser-side matches were found for this query."]
      };
    case "remember":
      return {
        prompt: "Browser runtime tool: remember",
        paragraphs: [
          `Accepted browser-side source as ${output.payload.entryId}.`,
          `Planned storage path: ${output.payload.storedPath}.`
        ]
      };
    case "recall":
      return {
        prompt: "Browser runtime tool: recall",
        paragraphs:
          output.matches.length > 0
            ? output.matches.map(
                (match) => `${match.title} matched on ${match.matchedOn} (${match.sourcePath}).`
              )
            : ["No recall matches were found for this filter."]
      };
    case "connect":
      return {
        prompt: "Browser runtime tool: connect",
        paragraphs:
          output.connections.length > 0
            ? output.connections.map(
                (connection) =>
                  `${connection.from} is ${connection.relationship} ${connection.to} via ${connection.supportingSourcePath}.`
              )
            : ["No topic connections were found for this input."]
      };
  }
}

function toolToSources(toolName, output) {
  switch (toolName) {
    case "search":
      return output.results.map((result) => ({
        label: "Search result",
        title: result.title,
        detail: result.sourcePath
      }));
    case "remember":
      return [
        {
          label: "Planned storage",
          title: output.payload.entryId,
          detail: output.payload.storedPath
        }
      ];
    case "recall":
      return output.matches.map((match) => ({
        label: `Matched on ${match.matchedOn}`,
        title: match.title,
        detail: match.sourcePath
      }));
    case "connect":
      return output.connections.map((connection) => ({
        label: connection.relationship,
        title: connection.to,
        detail: connection.supportingSourcePath
      }));
  }
}

class M3Source extends HTMLElement {
  connectedCallback() {
    this.render();
  }

  render() {
    const root = this.attachShadow({ mode: "open" });
    root.innerHTML = template(`
      <article class="source-card">
        <span class="source-label">${escapeHtml(this.getAttribute("label") ?? "")}</span>
        <strong>${escapeHtml(this.getAttribute("title") ?? "")}</strong>
        <div class="detail">${escapeHtml(this.getAttribute("detail") ?? "")}</div>
      </article>
    `);
  }
}

class M3Result extends HTMLElement {
  connectedCallback() {
    this.render();
  }

  render() {
    const root = this.attachShadow({ mode: "open" });
    const prompt = this.getAttribute("prompt") ?? "";
    const paragraphs = this.querySelectorAll("p");
    const body = Array.from(paragraphs)
      .map((paragraph) => `<p>${escapeHtml(paragraph.textContent ?? "")}</p>`)
      .join("");

    root.innerHTML = template(`
      <section class="result-card">
        <p class="prompt">${escapeHtml(prompt)}</p>
        <div class="answer">${body}</div>
      </section>
    `);
  }
}

class M3Chat extends HTMLElement {
  connectedCallback() {
    this.render();
  }

  render() {
    const root = this.attachShadow({ mode: "open" });
    const eyebrow = this.getAttribute("eyebrow") ?? "";
    const title = this.getAttribute("title") ?? "";
    const summary = this.getAttribute("summary") ?? "";
    const result = this.querySelector("m3-result");
    const sources = this.querySelectorAll("m3-source");
    const toolName = this.getAttribute("tool") ?? "search";
    const toolDescription =
      TOOL_DESCRIPTORS.find((tool) => tool.name === toolName)?.description ?? "";
    const providerLabel = this.getAttribute("provider-label") ?? "Browser demo";
    const providerSummary = this.getAttribute("provider-summary") ?? "";
    const providerOptions = JSON.parse(
      this.getAttribute("provider-options") ?? "[]"
    );
    const providerAuth = this.getAttribute("provider-auth") ?? "none";
    const instanceTitle =
      this.getAttribute("instance-title") ?? "youaskm3 author instance";
    const instanceUrl = this.getAttribute("instance-url") ?? "";

    root.innerHTML = template(`
      <section class="chat-shell">
        <article class="panel">
          <span class="eyebrow">${escapeHtml(eyebrow)}</span>
          <h2>${escapeHtml(title)}</h2>
          <p class="summary">${escapeHtml(summary)}</p>
          <div class="controls">
            <div class="tool-list">
              ${TOOL_DESCRIPTORS.map(
                (tool) => `
                  <button class="tool-chip" data-tool="${tool.name}" aria-pressed="${tool.name === toolName}">
                    ${escapeHtml(tool.name)}
                  </button>
                `
              ).join("")}
            </div>
            <div class="tool-copy">
              <strong>Client-side MCP adapter</strong>
              <div class="tool-description">${escapeHtml(toolDescription)}</div>
            </div>
            <label>
              Tool input
              <textarea id="runtime-input">${escapeHtml(this.getAttribute("input") ?? "")}</textarea>
            </label>
            <section class="provider-shell">
              <strong>Provider configuration</strong>
              <div class="provider-grid">
                <label>
                  Active provider
                  <select id="provider-select">
                    ${providerOptions
                      .map(
                        (provider) => `
                          <option value="${escapeHtml(provider.id)}" ${provider.label === providerLabel ? "selected" : ""}>
                            ${escapeHtml(provider.label)}
                          </option>
                        `
                      )
                      .join("")}
                  </select>
                </label>
                <div class="provider-meta">${escapeHtml(providerSummary)}</div>
                <label ${providerAuth === "api-key" ? "" : 'style="display:none"'}>
                  Provider API key
                  <input
                    id="provider-key"
                    type="password"
                    autocomplete="off"
                    placeholder="stored only in this browser session"
                  />
                </label>
              </div>
            </section>
          </div>
          <slot name="result"></slot>
          <div class="runtime-note">
            Browser shell runtime is executing locally through the contract-shaped tool adapter in <code>runtime.js</code>.
          </div>
        </article>
        <aside class="panel">
          <div class="sources">
            <slot name="sources"></slot>
          </div>
          <div class="runtime-note">
            <strong>Published author instance</strong>
            <div class="instance-meta">
              ${escapeHtml(instanceTitle)} is configured to publish from
              ${escapeHtml(instanceUrl || "the current static shell URL")}.
            </div>
          </div>
        </aside>
      </section>
    `);

    if (result) {
      result.setAttribute("slot", "result");
    }

    for (const source of sources) {
      source.setAttribute("slot", "sources");
    }

    for (const button of root.querySelectorAll(".tool-chip")) {
      button.addEventListener("click", () => {
        this.dispatchEvent(
          new CustomEvent("toolchange", {
            detail: { tool: button.dataset.tool ?? "search" },
            bubbles: true
          })
        );
      });
    }

    root.querySelector("#runtime-input")?.addEventListener("input", (event) => {
      const value = event.target instanceof HTMLTextAreaElement ? event.target.value : "";
      this.dispatchEvent(
        new CustomEvent("runtimeinput", {
          detail: { value },
          bubbles: true
        })
      );
    });

    root.querySelector("#provider-select")?.addEventListener("change", (event) => {
      const value = event.target instanceof HTMLSelectElement ? event.target.value : "";
      this.dispatchEvent(
        new CustomEvent("providerchange", {
          detail: { providerId: value },
          bubbles: true
        })
      );
    });
  }
}

const registrations = [
  ["m3-source", M3Source],
  ["m3-result", M3Result],
  ["m3-chat", M3Chat]
];

for (const [name, element] of registrations) {
  if (!customElements.get(name)) {
    customElements.define(name, element);
  }
}

const shell = document.querySelector("m3-chat");
let providerConfig = null;
let authorInstance = null;

async function loadProviderConfig() {
  const response = await fetch("./provider-config.json");
  if (!response.ok) {
    throw new Error("failed to load provider-config.json");
  }

  const config = await response.json();
  const persisted = window.localStorage.getItem(PROVIDER_STORAGE_KEY);
  if (!persisted) {
    return config;
  }

  try {
    const parsed = JSON.parse(persisted);
    return {
      ...config,
      activeProviderId: parsed.activeProviderId ?? config.activeProviderId
    };
  } catch {
    return config;
  }
}

async function loadAuthorInstance() {
  const response = await fetch("./author-instance.json");
  if (!response.ok) {
    throw new Error("failed to load author-instance.json");
  }

  return response.json();
}

function activeProvider(config) {
  return (
    config.profiles.find((profile) => profile.id === config.activeProviderId) ??
    config.profiles[0]
  );
}

function providerSummary(profile) {
  const authCopy =
    profile.auth === "api-key"
      ? "expects a user-supplied API key"
      : "runs without a remote API key";

  return `${profile.label} uses ${profile.endpoint}, ${authCopy}, and hints ${profile.modelHint}.`;
}

function syncShell(toolName, input) {
  if (!(shell instanceof HTMLElement)) {
    return;
  }

  let output;
  try {
    output = callBrowserTool(toolName, input);
  } catch (error) {
    output = {
      type: "search",
      results: [
        {
          id: "runtime-error",
          title: "Browser runtime input error",
          excerpt: error instanceof Error ? error.message : "Unknown runtime error",
          sourcePath: "app/site/runtime.js",
          score: 1
        }
      ]
    };
    toolName = "search";
  }

  const summary = toolToSummary(toolName, output);
  const sources = toolToSources(toolName, output);
  const result = shell.querySelector("m3-result");
  const provider = providerConfig ? activeProvider(providerConfig) : null;

  shell.setAttribute("tool", toolName);
  shell.setAttribute("input", input);
  shell.setAttribute("provider-label", provider?.label ?? "Browser demo");
  shell.setAttribute("provider-summary", provider ? providerSummary(provider) : "");
  shell.setAttribute("provider-auth", provider?.auth ?? "none");
  shell.setAttribute(
    "provider-options",
    JSON.stringify(providerConfig?.profiles ?? [])
  );
  shell.setAttribute(
    "instance-title",
    authorInstance?.title ?? "youaskm3 author instance"
  );
  shell.setAttribute("instance-url", authorInstance?.shellUrl ?? window.location.href);

  if (result instanceof HTMLElement) {
    result.setAttribute("prompt", summary.prompt);
    result.innerHTML = summary.paragraphs.map((paragraph) => `<p>${escapeHtml(paragraph)}</p>`).join("");
    result.render?.();
  }

  for (const existing of shell.querySelectorAll("m3-source")) {
    existing.remove();
  }

  for (const source of sources) {
    const node = document.createElement("m3-source");
    node.setAttribute("label", source.label);
    node.setAttribute("title", source.title);
    node.setAttribute("detail", source.detail);
    shell.appendChild(node);
  }

  shell.render?.();
}

if (shell instanceof HTMLElement) {
  let currentTool = shell.getAttribute("tool") ?? "search";
  let currentInput = shell.getAttribute("input") ?? "portable MCP clients";

  Promise.all([loadProviderConfig(), loadAuthorInstance()])
    .then(([config, manifest]) => {
      providerConfig = config;
      authorInstance = manifest;
      syncShell(currentTool, currentInput);
    })
    .catch((error) => {
      console.error("Failed to load browser shell config", error);
      syncShell(currentTool, currentInput);
    });

  shell.addEventListener("toolchange", (event) => {
    const detail = event instanceof CustomEvent ? event.detail : null;
    currentTool = detail?.tool ?? currentTool;
    syncShell(currentTool, currentInput);
  });

  shell.addEventListener("runtimeinput", (event) => {
    const detail = event instanceof CustomEvent ? event.detail : null;
    currentInput = detail?.value ?? currentInput;
    syncShell(currentTool, currentInput);
  });

  shell.addEventListener("providerchange", (event) => {
    const detail = event instanceof CustomEvent ? event.detail : null;
    if (providerConfig && detail?.providerId) {
      providerConfig = {
        ...providerConfig,
        activeProviderId: detail.providerId
      };
      window.localStorage.setItem(
        PROVIDER_STORAGE_KEY,
        JSON.stringify({ activeProviderId: detail.providerId })
      );
    }
    syncShell(currentTool, currentInput);
  });
}

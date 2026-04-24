const styles = `
  :host {
    display: block;
  }

  .eyebrow,
  .source-label {
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
  strong {
    color: #17352f;
  }

  .summary,
  .detail,
  .answer p {
    color: #587168;
    line-height: 1.6;
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

class M3Source extends HTMLElement {
  connectedCallback() {
    const root = this.attachShadow({ mode: "open" });
    root.innerHTML = template(`
      <article class="source-card">
        <span class="source-label">${this.getAttribute("label") ?? ""}</span>
        <strong>${this.getAttribute("title") ?? ""}</strong>
        <div class="detail">${this.getAttribute("detail") ?? ""}</div>
      </article>
    `);
  }
}

class M3Result extends HTMLElement {
  connectedCallback() {
    const root = this.attachShadow({ mode: "open" });
    const prompt = this.getAttribute("prompt") ?? "";
    const paragraphs = this.querySelectorAll("p");
    const body = Array.from(paragraphs)
      .map((paragraph) => `<p>${paragraph.textContent ?? ""}</p>`)
      .join("");

    root.innerHTML = template(`
      <section class="result-card">
        <p class="prompt">${prompt}</p>
        <div class="answer">${body}</div>
      </section>
    `);
  }
}

class M3Chat extends HTMLElement {
  connectedCallback() {
    const root = this.attachShadow({ mode: "open" });
    const eyebrow = this.getAttribute("eyebrow") ?? "";
    const title = this.getAttribute("title") ?? "";
    const summary = this.getAttribute("summary") ?? "";
    const result = this.querySelector("m3-result");
    const sources = this.querySelectorAll("m3-source");

    root.innerHTML = template(`
      <section class="chat-shell">
        <article class="panel">
          <span class="eyebrow">${eyebrow}</span>
          <h2>${title}</h2>
          <p class="summary">${summary}</p>
          <slot name="result"></slot>
        </article>
        <aside class="panel">
          <div class="sources">
            <slot name="sources"></slot>
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

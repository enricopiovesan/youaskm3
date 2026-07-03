# Supported Use Cases and Compatibility Matrix

Status: Current repository capability map

## Purpose

This matrix gives developers, end users, and agent-assisted workflows a fast answer to: what can I do today?

It is intentionally conservative. A row is marked usable today only when the repository has commands, docs, contracts, or validation that support it now. In-progress and not-yet-supported rows link back to the governing milestones, specs, or GitHub issues.

## Status Legend

| Status | Meaning |
|---|---|
| Usable today | Supported by current repo commands, contracts, docs, or validation. |
| In progress | Partly represented in specs, contracts, harnesses, or scripts, but not complete enough to claim as product support. |
| Not yet supported | Planned or future-scope; do not claim this behavior in docs, demos, releases, or acceptance reports. |
| Blocked | The youaskm3 side is waiting on a dependency, upstream surface, or explicit project decision. |

## Developer Matrix

| Use case | Status | Current command or entry point | Validation | Known gaps |
|---|---|---|---|---|
| Run the full repo gate | Usable today | `bash scripts/smoke.sh` | CI runs Rust quality, business logic coverage, WASM build, TypeScript quality, and spec reference checks. | Requires local toolchain setup from [local-development-toolchain.md](local-development-toolchain.md). |
| Initialize a local checkout | Usable today | `./scripts/m3.sh init` | Covered by smoke. | This scaffolds local metadata; it is not a complete end-user onboarding wizard. |
| Add supported source files or URLs | Usable today | `./scripts/m3.sh add <file-or-url> [title]` | MarkItDown and add-route smoke checks. | Supported extensions are limited by current routing and MarkItDown coverage. |
| Build static artifacts and WASM packages | Usable today | `./scripts/m3.sh build` | Build smoke plus CI WASM build. | Real Traverse runtime acceptance still requires registered app execution. |
| Refresh generated site artifacts | Usable today | `./scripts/m3.sh sync` | Sync and artifact generation smoke checks. | Sync conflict policy is still being expanded through [local-runtime-sync](../openspec/specs/local-runtime-sync/spec.md). |
| Query the generated local search index | Usable today | `./scripts/m3.sh search <query>` | Search crate tests and smoke. | This is local deterministic search, not a finished chat answer loop. |
| Serve the static PWA shell | Usable today | `./scripts/m3.sh serve [port]` | PWA shell smoke. | UI is a shell and renderer; product logic must stay outside the browser. |
| Inspect MCP contracts and local MCP routes | Usable today | [mcp-connection-flows.md](mcp-connection-flows.md), `contracts/mcp-tools.json` | `bash scripts/local-runtime-mcp-parity-smoke.sh` | Packaged Claude Desktop-style stdio support is not complete. |
| Validate Traverse readiness | In progress | `bash scripts/traverse-readiness.sh` | Downstream app conformance wrapper. | Final MVP acceptance remains blocked by real registered workflow and inference evidence; see [#135](https://github.com/enricopiovesan/youaskm3/issues/135) and [#136](https://github.com/enricopiovesan/youaskm3/issues/136). |
| Register and run the full Traverse-backed app workflow | Blocked | `scripts/register-traverse-app.sh`, `./scripts/m3.sh serve --runtime ...` | Readiness scripts and local runtime parity checks. | Blocked until `knowledge.infer` and final acceptance evidence are complete; see [#135](https://github.com/enricopiovesan/youaskm3/issues/135), [#120](https://github.com/enricopiovesan/youaskm3/issues/120), and [#122](https://github.com/enricopiovesan/youaskm3/issues/122). |

## End-User Matrix

| Use case | Status | How to try it today | What to expect | Known gaps |
|---|---|---|---|---|
| Clone the repo and inspect the project | Usable today | Read [README.md](../README.md), [SPEC.md](../SPEC.md), and this matrix. | A spec-governed open source project with strict validation and local-first direction. | The finished consumer product is still under construction. |
| Prepare a local knowledge folder | Usable today | `./scripts/m3.sh init` then add supported files with `./scripts/m3.sh add`. | Git-tracked markdown and generated site artifacts. | No polished one-command first-run experience yet. |
| Search prepared knowledge from the CLI | Usable today | `./scripts/m3.sh search <query>` | Local search-index results with source paths and excerpts. | This is not the final conversational answer experience. |
| View the local PWA shell | Usable today | `./scripts/m3.sh build && ./scripts/m3.sh serve 4173` | Static UI shell and generated site assets. | The full Traverse-backed chat loop is not ready for end-user acceptance. |
| Ask questions in a finished local chat product | In progress | Follow the runtime docs and MVP issues. | Current runtime paths can produce governed setup failures and request shapes. | Final happy path is tracked by [#120](https://github.com/enricopiovesan/youaskm3/issues/120) and [#136](https://github.com/enricopiovesan/youaskm3/issues/136). |
| Use a local LLM through youaskm3 | Blocked | None for product acceptance. | Missing inference must fail as a Traverse dependency failure, not hidden app fallback. | Real governed inference is tracked by [#135](https://github.com/enricopiovesan/youaskm3/issues/135); the caveat is documented in [mvp-local-inference-policy.md](mvp-local-inference-policy.md). |
| Fork and run a personal public instance in under 15 minutes | Not yet supported | Follow developer setup manually. | You can fork and build, but onboarding is not polished. | Later milestone work; see [SPEC.md Later milestone](../SPEC.md#later--fork-federation-and-network-effects). |
| Explore other public instances or federated answers | Not yet supported | Review [federation](../openspec/specs/federation/spec.md) and [federated-answer](../openspec/specs/federated-answer/spec.md). | Specs and tooling exist for planning and future validation. | Explore UI, cross-instance fan-out, and federated answer product support remain future scope. |

## Agent-Assisted Workflow Matrix

| Use case | Status | Start here | Validation | Known gaps |
|---|---|---|---|---|
| Run the repository ops workflow | Usable today | [youaskm3-ops.md](youaskm3-ops.md) | Final audit: open PRs, Ready issues, Blocked issues, and git status. | Requires GitHub access for issue, PR, and Project state. |
| Pick a Ready ticket and implement it | Usable today | Issue body, governing spec, and [CONTRIBUTING.md](../CONTRIBUTING.md). | PR CI plus local smoke. | Agents must avoid tickets owned by another active agent. |
| Work against specs and contracts | Usable today | `openspec/specs/`, `contracts/`, [SPEC.md](../SPEC.md). | Smoke validates OpenSpec files and contracts. | Material behavior changes still need spec updates before code. |
| Generate and ingest reasoning decision-log packages | Usable today | [reasoning-assistant-skill](../openspec/specs/reasoning-assistant-skill/spec.md), [decision-log-package](../openspec/specs/decision-log-package/spec.md), `./scripts/m3.sh import-decision-log`. | Decision-log package smoke and import validation. | Assistant distribution polish is future-scope; see [assistant-distribution](../openspec/specs/assistant-distribution/spec.md). |
| Resolve simple factual gaps | Usable today | `./scripts/m3.sh gaps list` and `./scripts/m3.sh gaps resolve-fact ...` | Direct fact resolution smoke. | Complex conceptual gaps should use decision-log packages, not forced one-line answers. |
| Claim that the first MVP is complete | Blocked | [#136](https://github.com/enricopiovesan/youaskm3/issues/136) | Final first-MVP acceptance and release gate. | Requires real local Traverse-backed chat, imported-document acceptance, governed inference, traces, and MCP parity evidence. |

## Current Commands

The stable command entrypoint is:

```bash
./scripts/m3.sh {init|add|ingest-decision-log|import-decision-log|semantic-quality|federated-answer|wasm-native-model-evidence|build|sync|search|serve|mvp-check|test|lint|smoke|status}
```

Additional implemented subcommands include:

```bash
./scripts/m3.sh sync check
./scripts/m3.sh gaps list
./scripts/m3.sh gaps resolve-fact
./scripts/m3.sh serve --runtime [port] [--traverse-endpoint URL] [--workspace-id ID]
```

If a command is not listed here or in `./scripts/m3.sh --help`, treat it as unsupported until a spec, script, and validation path exist.

## Major Gaps and Owners

| Gap | Status | Governing reference |
|---|---|---|
| Real local Traverse-backed chat happy path | Blocked | [#120](https://github.com/enricopiovesan/youaskm3/issues/120), [traverse-integration spec](../openspec/specs/traverse-integration/spec.md) |
| Imported-document question acceptance | Blocked | [#122](https://github.com/enricopiovesan/youaskm3/issues/122) |
| Real Traverse-governed inference capability | Blocked | [#135](https://github.com/enricopiovesan/youaskm3/issues/135), [mvp-local-inference-policy.md](mvp-local-inference-policy.md) |
| Final first-MVP acceptance and release gate | Blocked | [#136](https://github.com/enricopiovesan/youaskm3/issues/136) |
| Claude/Desktop packaged assistant distribution | Future scope | [assistant-distribution](../openspec/specs/assistant-distribution/spec.md) |
| Package inbox/watch automation | Future scope | [package-import-automation](../openspec/specs/package-import-automation/spec.md) |
| Production answer quality benchmarks | Future scope | [semantic-quality-evaluation](../openspec/specs/semantic-quality-evaluation/spec.md) |
| Multi-persona isolation and shared scopes | Future scope | [multi-persona](../openspec/specs/multi-persona/spec.md) |
| Hosted teams and accounts | Future scope | [hosted-service](../openspec/specs/hosted-service/spec.md) |
| Cross-instance federated answers | Future scope | [federated-answer](../openspec/specs/federated-answer/spec.md) |
| WASM-native model-engine proof | Future scope | [wasm-native-model-evidence](../openspec/specs/wasm-native-model-evidence/spec.md) |

## Validation

When this matrix changes, run:

```bash
bash scripts/smoke.sh
```

For focused checks around specific rows, use the command named in that row and then run full smoke before opening a release-facing PR.

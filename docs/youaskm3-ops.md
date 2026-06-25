# youaskm3 Ops

Status: Active operating model

## Metadata

name: youaskm3-ops

description: Start or resume the standard youaskm3 operating model when the user says YOUASKM3 OPS, asks to start youaskm3 ops/dev work, asks for the ready-ticket worker, PR finisher, backlog gardener, spec/contracts gardener, or wants Codex to pick ready GitHub Project 3 MVP work and run the youaskm3 coordination process.

## Canonical Trigger

```text
YOUASKM3 OPS
```

## When To Use

Use this operating model when the user wants Codex to:

- resume youaskm3 project work
- pick the next Ready MVP ticket
- finish an open PR
- audit Project 3
- align tickets with specs and contracts
- check whether a task is blocked by Traverse requirements

## Workflow

1. Read `SPEC.md` before implementation work.
2. Read `README.md`, `CONTRIBUTING.md`, `docs/mvp-ticket-backlog.md`, and `docs/traverse-mvp-requirements.md` when they are relevant to the lane.
3. Inspect current GitHub issues, PRs, and Project 3 state.
4. Prefer finishing existing open PRs before claiming new Ready work.
5. If no active PR needs attention, pick one Ready Project 3 issue.
6. Before work on an issue, run ownership pre-flight checks:
   - issue must not have `agent:claude`
   - no remote `claude/issue-NNN-*` branch may exist
   - issue must not already be owned by another active agent
7. If pre-flight passes, claim the issue:
   - add `agent:codex`
   - set Project 3 Agent to `Codex` when project write access is available
   - set Project 3 Status to `In Progress` when project write access is available
   - if project write access is unavailable, report the limitation before coding
8. Use a dedicated `codex/issue-NNN-*` branch.
9. Keep work scoped to the claimed issue, governing OpenSpec spec, and MVP contract boundary.
10. Open a dedicated PR with validation evidence.
11. After a PR merges or an issue is otherwise completed, loop back to step 3 while Project 3 still has Ready work or open PRs needing attention.

## Continuous Ops Rule

`YOUASKM3 OPS` is a continuous operating mode, not a one-ticket command. Agents should not stop after finishing a single ticket when actionable backlog remains.

Keep cycling through PR finisher and Ready-ticket worker lanes until one of these stopping conditions is true:

- Project 3 has no Ready issues and no open PRs needing attention.
- All remaining actionable work is blocked, already owned by another agent, or fails ownership pre-flight.
- The user explicitly says to stop, pause, or switch tasks.
- A real blocker prevents safe progress, such as missing credentials, unavailable GitHub access, failing required tooling, or an unresolved merge conflict.
- Context/tool limits require handing off; in that case, leave exact current state, branch, PR, validation, and next issue recommendation.

Between tickets, keep the transition lean: sync `main`, verify clean status, inspect open PRs, inspect Ready Project 3 items, run ownership pre-flight, claim the next issue, and continue.

## Operating Lanes

### Ready-ticket worker

Claim one Ready Project 3 issue and implement it end to end.

Use this lane when there is no open PR needing attention and Project 3 has Ready work.

### PR finisher

Inspect open PRs, fix CI or review issues, update stale branches, and merge when green if explicitly allowed.

Use this lane before claiming new work.

### Backlog gardener

Audit Project 3 statuses, labels, blockers, notes, missing tickets, and stale ownership.

Use this lane when the board may be out of sync with the repo.

### Spec/contracts gardener

Align `README.md`, `SPEC.md`, `openspec/specs/`, `contracts/`, and smoke validation with the approved MVP direction.

Use this lane when tickets, specs, contracts, or roadmap disagree.

### Traverse dependency checker

Verify whether blocked youaskm3 tickets depend on Traverse runtime requirements in `docs/traverse-mvp-requirements.md`.

Use this lane when a ticket needs application bundle registration, real Traverse execution, inference dependency resolution, MCP parity, runtime placement, or public traces.

For release-pinned Traverse evidence, use the checklist in
`docs/traverse-mvp-requirements.md#release-pinned-evidence-checklist`. Do not
rely on release prose alone when `scripts/traverse-readiness.sh` can run against
a local Traverse checkout.

## Guardrails

- Do not mark work `In Progress` unless a real dev thread has started it.
- Do not use labels as status; Project 3 status is the actionability source of truth.
- Do not claim work already owned by Claude Code or another active agent.
- Do not broaden scope beyond the issue and governing spec.
- Create future tickets for non-blocking improvements instead of expanding an active slice.
- Keep all product/business logic portable and Traverse/WASM-bound.
- Keep the PWA UI-only and the CLI artifact/build-focused.
- Temporary harnesses are allowed only when they mirror the future Traverse contract and are clearly replaceable.
- If GitHub Project write scope is unavailable, report that clearly and avoid pretending the board was updated.

## Token Discipline

The operating model should stay autonomous without making the transcript carry every byte of evidence. Agents should fetch enough data to decide, patch, and validate, then report concise summaries with links, file paths, or check names that let a human drill in.

### Default Rules

- Start broad with counts and names, then narrow only where something is actionable.
- Prefer filtered issue, PR, and Project 3 queries for the active lane before full board dumps or full issue exports.
- Prefer structured filters over raw dumps: `--json`, `--jq`, `jq`, `rg`, exact line ranges, and summary flags.
- Bound command output whenever the tool supports it. Increase the bound only after a specific failure requires more context.
- Never paste full passing logs, full generated JSON, full lockfiles, full board exports, or full CI transcripts into chat.
- Use `git diff --stat` and `git diff --name-only` before reading hunks. Read full diffs only for the files and ranges being reviewed.
- Progress updates should say: current action, blocker if any, next action. Skip updates that merely restate unchanged state.
- Final answers should cover PR/branch state, validation results, merged or open PR links, residual risks, and the next recommended action.

### Lean Command Patterns

Use these shapes as the default for common ops work:

```bash
git status --short --branch
git diff --stat
git diff --name-only
git diff -- path/to/file
rg -n "pattern" path/to/focused/tree
sed -n '120,190p' path/to/file
gh pr checks <pr> --json name,state,conclusion,workflow,detailsUrl --jq '.[] | {name,state,conclusion,workflow,detailsUrl}'
gh run view <run-id> --json status,conclusion,url,jobs --jq '{status,conclusion,url,jobs:[.jobs[] | {name,status,conclusion}]}'
gh run view <run-id> --log-failed
gh project item-list 3 --owner enricopiovesan --format json --limit 100 --jq '[.items[] | {content:.content.title,status:.status,labels:.labels,item:.id}]'
```

### What To Report

- Project board audits: number of Ready/In Progress/Blocked items, stale ownership conflicts, and the exact issue numbers that need action.
- PR checks: count by status, failing check names, and the next failing line or URL. Do not paste watch output loops.
- CI/test failures: failing command, failing test/check name, first actionable error line, and affected file if known.
- Coverage: package/crate, measured status, threshold, and any uncovered file/function names if the gate fails.
- Diffs: changed files, risk level, and narrow references to the hunks that matter.

### Exceptions

Large output is acceptable when the output itself is the deliverable, when a schema/log format is being debugged, or when the user explicitly asks for raw logs. Even then, prefer a saved artifact or a focused excerpt first.

## Minimality Ladder

Before adding code or creating a new abstraction, agents must apply this ladder in order:

1. Does this change need to exist for the active issue or request?
2. Can existing project code, contracts, docs, configs, or tests already satisfy it?
3. Can the standard library, platform feature, or existing dependency do it?
4. Can a schema, config, test, or doc change solve it without a new abstraction?
5. Can one focused function, command branch, or validation rule solve it?
6. Only then add the minimum new structure needed.

Minimality is a cost-control tool, not permission to cut corners. It must never weaken:

- correctness
- security
- accessibility
- stable errors and failure modes
- validation and test coverage
- traceability and source evidence
- OpenSpec, contract, PR, issue, or Project 3 governance

When the smallest visible change would weaken any of those, choose the next-smallest correct change and call out the tradeoff in the PR.

## Future-Agent Checklist

### Before

- Identify the active issue or request and the governing spec or contract.
- Check open PRs before claiming new work.
- Use lean issue/PR/project queries to find only actionable work.
- Run ownership pre-flight before marking work In Progress.
- Apply the Minimality Ladder before adding code.

### During

- Read focused file ranges and narrow diffs.
- Keep status updates to current action, blocker, and next action.
- Add tests or validation at the smallest level that proves the behavior.
- Create future tickets for adjacent improvements instead of widening the active slice.

### After

- Report validation as pass/fail counts and named gates.
- Include PR link/state, issue/project state, branch/status, and residual risk.
- Quote only actionable failing lines if something failed.
- Recommend the next Ready issue or PR-finisher action.

## Output Reduction Risks

Lean output can hide important information if used carelessly. Do not reduce output when:

- a failure line is ambiguous without nearby context
- a schema or generated artifact shape is the thing being reviewed
- a security, privacy, accessibility, or data-loss risk is present
- a Project field or GitHub API shape appears to have drifted
- the user explicitly asks for raw logs, full diffs, or complete generated output

In those cases, fetch the larger evidence, but summarize it first and keep raw excerpts focused.

## Current MVP Boundary

The first MVP is:

> A local-first PWA chat experience that answers from user-owned knowledge artifacts, with source attribution and graph context, while preparing the product to hand runtime business logic to Traverse as governed WASM capabilities.

youaskm3 owns:

- MarkItDown-backed conversion
- normalized markdown artifacts
- chunk/search/graph artifacts
- PWA UI
- product contracts
- temporary Traverse-compatible harnesses where needed

Traverse owns:

- governed WASM capability execution
- app bundle registration
- evented workflow composition
- model/inference dependency resolution
- local/server placement
- MCP exposure
- public traces

## Validation

Default validation for implementation work:

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

Focused validation may be used for docs/spec-only work, but the final report must say exactly what did and did not run.

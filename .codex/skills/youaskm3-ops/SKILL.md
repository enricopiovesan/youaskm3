---
name: youaskm3-ops
description: Start or resume the standard youaskm3 operating model when the user says YOUASKM3 OPS, asks to start youaskm3 ops/dev work, asks for the ready-ticket worker, PR finisher, backlog gardener, spec/contracts gardener, or wants Codex to pick ready GitHub Project 3 MVP work and run the youaskm3 coordination process.
---

# youaskm3 Ops

Use this skill when the user wants Codex to start or resume the standard youaskm3 operating model.

Canonical trigger:

```text
YOUASKM3 OPS
```

## Workflow

1. Read `SPEC.md` before implementation work.
2. Read `README.md`, `CONTRIBUTING.md`, `docs/mvp-ticket-backlog.md`, and `docs/traverse-mvp-requirements.md` when they are relevant to the requested lane.
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

`YOUASKM3 OPS` is a continuous operating mode, not a one-ticket command. Do not stop after finishing a single ticket when actionable backlog remains.

Continue cycling through PR finisher and Ready-ticket worker lanes until one of these stopping conditions is true:

- Project 3 has no Ready issues and no open PRs needing attention.
- All remaining actionable work is blocked, already owned by another agent, or fails ownership pre-flight.
- The user explicitly says to stop, pause, or switch tasks.
- A real blocker prevents safe progress, such as missing credentials, unavailable GitHub access, failing required tooling, or an unresolved merge conflict.
- Context/tool limits require handing off; in that case, leave exact current state, branch, PR, validation, and next issue recommendation.

Between tickets, keep the transition lean: sync `main`, verify clean status, inspect open PRs, inspect Ready Project 3 items, run ownership pre-flight, claim the next issue, and continue.

## Operating Lanes

- **Ready-ticket worker:** claim one Ready Project 3 issue and implement it end to end.
- **PR finisher:** inspect open PRs, fix CI/review issues, update stale branches, and merge when green if allowed.
- **Backlog gardener:** audit Project 3 statuses, labels, blockers, notes, missing tickets, and ticket/spec mismatches.
- **Spec/contracts gardener:** align `README.md`, `SPEC.md`, `openspec/specs/`, `contracts/`, and smoke validation with the approved MVP direction.
- **Traverse dependency checker:** verify whether blocked youaskm3 tickets depend on Traverse runtime requirements in `docs/traverse-mvp-requirements.md`.

## Project Guardrails

- Do not mark work `In Progress` unless a real dev thread has started it.
- Do not use labels as status; Project 3 status is the actionability source of truth.
- Do not claim work already owned by Claude Code or another active agent.
- Do not broaden scope beyond the issue and governing spec.
- Create future tickets for non-blocking improvements instead of expanding an active slice.
- Keep all product/business logic portable and Traverse/WASM-bound.
- Keep the PWA UI-only and the CLI artifact/build-focused.
- Temporary harnesses are allowed only when they mirror the future Traverse contract and are clearly replaceable.

## Token Discipline

Default to lean, filtered operations. Preserve autonomy and correctness by fetching enough evidence to decide, but do not paste large raw outputs into chat.

- Issue/PR discovery: prefer filtered `gh issue list` / `gh pr list` queries for the active lane before any full board export. Pull a single issue, PR, or project item in detail only after it becomes actionable.
- Project boards: use `--jq` or `jq` filters that return only issue number, title, labels, status, agent/owner, blocker, and item id. Avoid full Project item JSON unless debugging schema drift.
- PR checks: prefer `gh pr checks --json name,state,conclusion,workflow,detailsUrl --jq ...` or a one-shot status query. Avoid repeated `gh pr checks --watch` transcripts; report only status changes and failing check names.
- CI logs: start with check/run summaries. Fetch logs only for failed jobs, and quote only actionable failure lines plus a small amount of surrounding context.
- Tests and coverage: run the normal commands, but summarize pass/fail counts, failing test names, coverage gate result, and first actionable error. Do not paste full passing test, clippy, coverage, or build logs.
- Diffs: inspect `git diff --stat` and `git diff --name-only` before any larger diff. Read narrow hunks for files under review instead of dumping full diffs.
- File reads: use focused `rg` queries and exact `sed -n` ranges. Avoid broad recursive reads, full generated JSON, full lockfiles, and full build artifacts unless the whole file is the artifact being edited.
- Progress updates: keep updates to current action, blocker if any, and next action. Do not restate unchanged CI, board, or test state.
- Final reports: include merged/open PR, validation results, current branch/status, and the next recommended action. Keep detailed logs out of the final answer unless the user explicitly asks.

Useful lean command shapes:

```bash
git diff --stat
git diff --name-only
gh pr checks <pr> --json name,state,conclusion,workflow,detailsUrl --jq '.[] | {name,state,conclusion,workflow,detailsUrl}'
gh run view <run-id> --log-failed
gh project item-list 3 --owner enricopiovesan --format json --limit 100 --jq '[.items[] | {content:.content.title,status:.status,labels:.labels,item:.id}]'
```

## Minimality Ladder

Before adding code, apply this ladder in order:

1. Does this change need to exist for the active issue or user request?
2. Can existing project code, contracts, docs, configs, or tests already satisfy it?
3. Can the standard library, platform feature, or existing dependency do it?
4. Can a schema, config, test, or doc change solve it without a new abstraction?
5. Can one focused function, command branch, or validation rule solve it?
6. Only then add the minimum new structure needed.

Minimality must never weaken correctness, security, accessibility, stable errors, validation, traceability, required tests, or project governance. If the smallest change would weaken any of those, choose the next-smallest correct change and explain the tradeoff briefly.

## Validation

Default validation for implementation work:

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

For docs/spec-only changes, at minimum run the relevant focused smoke script and explain why full smoke was skipped.

For the full operating model, see `docs/youaskm3-ops.md`.

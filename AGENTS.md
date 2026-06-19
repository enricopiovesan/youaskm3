# Agent Workflow

This repository uses the youaskm3 ops model for agent and dev coordination.

Start here before implementation work:

1. Read `SPEC.md`.
2. Read `docs/youaskm3-ops.md` for workflow, guardrails, Token Discipline, and the Minimality Ladder.
3. If running Codex, use `.codex/skills/youaskm3-ops/SKILL.md` when the user says `YOUASKM3 OPS` or asks for ready-ticket, PR-finisher, backlog-gardener, or spec/contracts work.

## Lean Ops Default

Agents should stay autonomous and evidence-driven, but keep command output bounded:

- Prefer filtered issue, PR, and Project 3 queries before full board exports.
- Use `git diff --stat` and `git diff --name-only` before reading large diffs.
- Read focused file ranges with `rg` and `sed -n`; avoid full generated files, lockfiles, and logs unless they are the artifact under review.
- Summarize passing tests, lint, clippy, coverage, and CI as statuses and counts.
- Fetch failed CI logs only for failed jobs, and quote only actionable failing lines.
- Poll CI by reporting status changes, not repeated unchanged watch output.
- Keep final reports focused on PR state, validation, branch/status, residual risk, and next recommendation.

## Minimality Ladder

Before adding code, apply this ladder:

1. Does this change need to exist for the active issue or request?
2. Can existing project code, contracts, docs, configs, or tests already satisfy it?
3. Can the standard library, platform feature, or existing dependency do it?
4. Can a schema, config, test, or doc change solve it without a new abstraction?
5. Can one focused function, command branch, or validation rule solve it?
6. Only then add the minimum new structure needed.

Minimality must never weaken correctness, security, accessibility, stable errors, validation, traceability, required tests, or project governance.

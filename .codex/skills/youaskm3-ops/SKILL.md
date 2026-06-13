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

## Validation

Default validation for implementation work:

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

For docs/spec-only changes, at minimum run the relevant focused smoke script and explain why full smoke was skipped.

For the full operating model, see `docs/youaskm3-ops.md`.

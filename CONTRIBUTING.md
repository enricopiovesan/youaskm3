# Contributing

Thanks for contributing to youaskm3.

This repository is organized around the idea that approved specs come first, contracts drive implementation, and the validation flow should stay honest for a first-time contributor.

## Before you start

Read these documents before proposing or implementing a change:

- [SPEC.md](SPEC.md)
- [ref/SPEC.md](ref/SPEC.md)
- [ref/codex-prompt.md](ref/codex-prompt.md)
- the reference documents in `ref/`, including the author's book and white paper, when they are relevant to the capability you are changing

## Core rules

The project follows the seven design principles from [SPEC.md](SPEC.md#2-design-principles):

1. Specs are the source of truth.
2. WASM-first portability is the default.
3. Contracts come before code.
4. Business logic keeps 100% automated coverage.
5. Production quality starts on day one.
6. The repo stays open by default.
7. Git is infrastructure, not an afterthought.

## Spec-first workflow

Every material change starts with the governing spec:

1. Confirm whether an issue already exists or open a new one.
2. For a new capability or material behavior change, start an OpenSpec proposal.
3. Capture the proposal, design, tasks, and spec delta under `openspec/changes/`.
4. Get the spec reviewed before writing implementation code.
5. Implement only against the approved spec.
6. Open a PR that references the exact spec path and requirement.

If code and spec disagree, update the spec first. The spec wins.

## PR requirements

Every PR must pass these ten gates before merge:

1. `cargo fmt --check`
2. `cargo clippy --workspace --all-targets -- -D warnings`
3. `cargo test --locked`
4. `cargo llvm-cov --fail-under-lines 100` for the business logic crates
5. `cargo build --locked --workspace`
6. `cargo build --locked --workspace --target wasm32-wasip1`
7. `npm run lint`
8. `npm run typecheck`
9. `npm test`
10. PR body references an implemented spec path under `openspec/specs/`

If the change updates a spec, the PR must also include the spec delta in the description.

## PR template

Use this structure when writing a pull request:

```markdown
## What this changes
[One paragraph]

## Spec reference
openspec/specs/[capability]/spec.md — [requirement name]

## Spec delta (if spec changed)
[paste the spec diff here]

## Test coverage
[confirm: 100% maintained / new tests added for new behaviour]

## Breaking changes
[none / describe]
```

## Coverage

The business logic bar is intentionally strict:

- `youaskm3-core` must maintain 100% line coverage.
- New deterministic domain logic should meet the same bar.
- Coverage is enforced through `cargo-llvm-cov` and checked in CI and local scripts.

The point is not vanity metrics. The point is to keep the portable core explainable, reviewable, and safe to evolve.

## Workflow

Follow this path from start to finish:

1. Pick or open an issue.
2. Link the work to the project board milestone.
3. Prepare the OpenSpec proposal if the change is new or material.
4. Review and approve the spec work.
5. Implement with tests, docs, and contract updates.
6. Run `./scripts/smoke.sh`.
7. Open the PR using the template.
8. Merge only when the implementation, docs, and specs tell the same story.

## Issues

Use the issue templates when possible so work lands with enough context to route cleanly through the project board and milestone workflow.

Every capability or milestone ticket should include:

- the target milestone
- the governing spec reference under `openspec/specs/` or the relevant `SPEC.md` section
- a concrete definition of done that can be used to decide whether the issue is actually complete

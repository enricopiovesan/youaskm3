# Gap Resolution Decision Log

## Package ID
decision-log-20260629-gap-resolution

## Persona ID
default

## Package Mode
gap_resolution

## Gap Resolution
Resolved source gap `gap-runtime-policy`.

## Conversation Goal
Clarify whether missing runtime capability should create a downstream workaround.

## Questions Asked
- Should a missing Traverse surface be bypassed downstream?

## Options Considered
- Add a downstream shortcut
- Keep the downstream issue blocked and raise an upstream requirement

## Pros and Cons
- Downstream shortcut: faster demo; violates runtime boundary.
- Upstream requirement: slower; preserves governed execution.

## Recommendation
Keep the downstream issue blocked and raise an upstream requirement.

## Assumptions
- Runtime business behavior belongs in Traverse-governed WASM.

## Challenged Assumptions
- A local shortcut can count as MVP acceptance.

## Decisions
- Missing Traverse public surfaces become upstream requirements.

## Claims
- Missing Traverse public surfaces must not be hidden by downstream shortcuts.

## Confidence Assessment
High; this follows the blocker escalation rule.

## Citations
- docs/traverse-blocker-escalation.md

## Remaining Non-Blocking Open Questions
- Exact upstream release placement can be decided later.

## Blocking Clarifications
None.

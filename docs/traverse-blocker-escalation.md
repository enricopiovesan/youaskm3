# Traverse Blocker Escalation

Status: MVP operating process

## Purpose

Use this process when a youaskm3 MVP ticket cannot satisfy its definition of
done through current Traverse public surfaces.

The goal is to keep youaskm3 product-led without hiding Traverse gaps behind
downstream runtime shortcuts, provider-specific code, Browser demo acceptance,
contract stubs, fake workflow steps, skeleton manifests, or placeholder
evidence.

## Decision Checklist

Before opening or linking a Traverse blocker, classify the failure.

### youaskm3 bug

Treat the issue as a youaskm3 bug when the required Traverse public surface
exists and the local repo misuses it.

Examples:

- invalid youaskm3 app manifest shape
- missing or stale component digest after a successful WASM build
- PWA request body does not match the configured Traverse HTTP/JSON contract
- local smoke fixture is incomplete or points at the wrong artifact

Action: fix the youaskm3 code, docs, contract, fixture, or script in the active
ticket.

### Traverse blocker

Treat the issue as a Traverse blocker when a focused command proves that
youaskm3 has valid downstream evidence but Traverse lacks a required public
surface or governed runtime behavior.

Examples:

- no public app-register command exists for a valid downstream app manifest
- a documented HTTP/JSON execution path cannot execute a registered workflow
- a public trace omits required source, graph, dependency, or validation evidence
- MCP parity cannot call the same registered workflow through public Traverse
  surfaces

Action: keep the youaskm3 ticket Blocked in Project 3, open or link a Traverse
requirement, and do not add downstream runtime/provider shortcuts.

### Environment or setup failure

Treat the issue as environment/setup when the required public surface exists but
the local machine lacks a prerequisite.

Examples:

- missing `TRAVERSE_REPO`
- Traverse checkout older than the required release tag
- optional local model provider unavailable while live model conformance is
  explicitly opt-in
- missing Rust target, local tool, or credentials

Action: report the setup failure with the missing prerequisite. Do not open an
upstream Traverse blocker unless the setup step itself exposes a missing public
surface.

## Required Evidence

Every Traverse blocker must include:

- affected youaskm3 issue or PR
- affected capability, workflow, or contract
- expected Traverse public surface
- observed failure code and short error excerpt
- focused reproduction command
- Traverse version, tag, or commit
- youaskm3 branch or commit
- downstream impact and why Browser demo, temporary harnesses, skeleton
  manifests, stubs, or fake workflow steps cannot satisfy the ticket

If no focused reproduction command can exist, explain why and include the
smallest available validation path.

## Linking and Board State

When a blocker belongs upstream:

1. Comment on the blocked youaskm3 issue with the focused evidence.
2. Link the upstream Traverse issue or requirement from that comment.
3. Set the youaskm3 Project 3 Status to `Blocked`.
4. Do not keep the issue `In Progress` unless active downstream work remains.
5. Resume the ticket only after the linked Traverse requirement is available
   through a public surface.

## Current Example

`scripts/register-traverse-app.sh --json` consumes Traverse v0.5.0 public
`traverse-cli app validate` and `traverse-cli app register` surfaces. If a
valid youaskm3 bundle with real component evidence validates/registers and then
fails because Traverse cannot execute the registered real workflow, real WASM
microservice, or real WASM agent capability through public surfaces, the
remaining gap is a Traverse blocker.

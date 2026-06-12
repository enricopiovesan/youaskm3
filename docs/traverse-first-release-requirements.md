# Traverse Requirements for the First youaskm3 Release

This document defines what `youaskm3` still needs from **Traverse** for the first real `youaskm3` release.

It is not a wishlist.
It is the minimum release-integration contract that lets `youaskm3` honestly claim it is built on Traverse for runtime and MCP.

Current Traverse baseline under review:

- [Traverse v0.3.0](https://github.com/enricopiovesan/Traverse/releases/tag/v0.3.0)

## Goal

For the first `youaskm3` release, Traverse must provide a stable enough runtime and MCP integration baseline so `youaskm3` can:

- expose its contract-defined knowledge tools through a real Traverse-backed path
- connect to at least one real MCP client flow
- connect to at least one real app-consumable integration flow
- document that integration honestly, without depending on private repo knowledge or unreleased internals

## What Traverse Already Gives Us

As of Traverse `v0.3.0`, the baseline is strong enough in these areas:

- published GitHub Release artifact baseline
- HTTP/JSON application API surface
- discovery, registration, and execution paths for downstream apps
- workspace identity, auth, grants, isolation, and audit evidence
- OpenTelemetry-compatible trace export
- WASI Host ABI v1 insulation
- supply-chain evidence and artifact verification

That means `youaskm3` is **not blocked on core runtime theory**.
The remaining needs are mostly about integration clarity, packaging, and supported consumer paths.

## Required from Traverse

### 1. Canonical MCP consumer path

Traverse must provide one clear, released MCP-facing integration path that `youaskm3` can document as canonical.

Minimum requirement:

- a released MCP surface with a documented startup path
- a clear statement of what client types are supported
- enough documentation to connect a real client without reading Traverse source code

Why this matters:

`youaskm3` cannot claim easy Claude or app connection until the Traverse MCP entry path is explicit and stable enough to reference.

### 2. Canonical app-consumable path

Traverse must provide one clear app-facing integration path that `youaskm3` can treat as the supported downstream application baseline.

Minimum requirement:

- documented HTTP/JSON app API usage
- clear local serve / discovery / execution flow
- one minimal end-to-end example suitable for a downstream consumer

Why this matters:

The first `youaskm3` release should not guess how to consume Traverse.
It should point to one released and documented app path.

### 3. Compatibility statement for the public surfaces

Traverse must make it clear which public surfaces are intended for downstream consumers at `v0.3.0`.

Minimum requirement:

- explicit release-facing compatibility notes for MCP-facing and app-facing consumers
- clear distinction between governed public surfaces and internal implementation details
- a documented release baseline that `youaskm3` can pin to

Why this matters:

`youaskm3` needs to know what it can safely depend on without following `main` or private repo knowledge.

### 4. Consumer packaging expectations

Traverse must be clear about how a downstream project is expected to consume it.

Minimum requirement:

- source-build path is documented and supported
- if no binary/package distribution exists, that limitation is stated clearly
- startup commands and runtime assumptions are written down

Why this matters:

The first `youaskm3` release needs a reproducible setup story.
If Traverse is source-build only, `youaskm3` can work with that, but it must be explicit.

### 5. Minimal downstream validation story

Traverse must provide a validation path that `youaskm3` can use as evidence for compatibility claims.

Minimum requirement:

- one deterministic validation path for MCP-facing integration or app-facing integration
- one documented command sequence or validation document that downstream projects can follow

Why this matters:

The first `youaskm3` release should be able to say:
"this integration is supported because it passes this released Traverse validation path."

## Not Required from Traverse Before First Release

`youaskm3` does **not** need Traverse to complete these items before the first `youaskm3` release:

- every future connector/plugin idea
- polished cross-platform binary distribution
- complete federation support
- every possible MCP client walkthrough
- a final `1.0` compatibility promise

Those would help, but they are not the minimum blocker set.

## What Still Belongs to youaskm3

Even if Traverse satisfies everything above, `youaskm3` still owns:

- integrating Traverse into the `youaskm3` runtime path
- documenting Claude and app connection steps for `youaskm3`
- deciding the canonical user-facing integration path
- expanding ingest support such as `markitdown`
- publishing a supported use-case matrix

In other words:

- Traverse must give us the released baseline
- `youaskm3` must turn that baseline into a usable product story

## First-Release Readiness Test

We can treat Traverse as “good enough for first youaskm3 release” when all of the following are true:

- `youaskm3` can point to a released Traverse version, not repo head
- `youaskm3` can document one MCP client connection path honestly
- `youaskm3` can document one app-consumable connection path honestly
- `youaskm3` does not rely on private Traverse internals
- `youaskm3` can validate the supported path using released Traverse documentation or commands

## Practical Conclusion

For the first `youaskm3` release, what we still need from Traverse is not more architecture.

We need:

- one canonical MCP path
- one canonical app API path
- release-level compatibility clarity
- reproducible consumer setup expectations
- one downstream validation path

Once those are clear, the remaining work is primarily inside `youaskm3`.

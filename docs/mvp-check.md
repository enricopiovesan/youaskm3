# Expanded First-MVP Acceptance Gate

`m3 mvp-check` is the final expanded first-MVP gate for the second-brain product loop.
It is acceptance evidence, not a development shortcut.

Run it with an explicit knowledge root:

```bash
bash scripts/m3.sh mvp-check --knowledge-root /path/to/knowledge-root
```

Run it with live Traverse readiness when a local Traverse checkout is available:

```bash
bash scripts/m3.sh mvp-check \
  --traverse-repo /path/to/Traverse \
  --knowledge-root /path/to/knowledge-root
```

The gate validates first-run setup, real Traverse app bundle evidence, reasoning skill adapter drift, decision-log package validation and ingestion, reasoning graph extraction, knowledge gaps and conflicts, sync preflight, local runtime serve orchestration, PWA chat rendering, HTTP/MCP parity, Traverse MCP workflow parity, and direct fact resolution.

The gate must fail if acceptance depends on Browser demo output, temporary harnesses, fake workflow steps, skeleton manifests, placeholder digests, all-zero evidence, or downstream shortcuts.

Remaining caveats are printed at the end of every successful run:

- Semantic validation availability depends on the configured Traverse/provider environment.
- WASM-native model execution remains a Traverse/provider capability even though youaskm3 declares and validates the model dependency route.

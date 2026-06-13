# Normalized Markdown Artifact Contract

Status: MVP contract

Normalized markdown artifacts are the CLI-owned handoff between source conversion and runtime knowledge capabilities.

The CLI may discover files, call MarkItDown, normalize text, write artifacts, and build indexes. Runtime product behavior starts after these artifacts exist.

Required properties:

- stable `artifact_id`
- human-readable `title`
- source type and source path or URL
- conversion tool metadata
- one or more sections
- chunk ids suitable for retrieval and citation
- optional graph extraction hints

Validation source: `contracts/markdown-artifact.schema.json`.

Example: `contracts/examples/markdown-artifact.example.json`.

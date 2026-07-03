# Optional Hosted Service Architecture

## Purpose

Hosted youaskm3 is an optional layer for accounts, teams, permissions, hosted sync, and future hosted runtime operations. The local CLI, local knowledge root, local PWA shell, and Traverse-backed runtime remain valid when hosted service configuration is absent, expired, or unavailable.

## Local-First Boundary

- Hosted configuration is optional.
- Local commands must not require hosted identity to read or write a local knowledge root.
- Hosted outages must not block local package validation, local sync preflight, local answer context selection, or local assistant package generation.
- Hosted features may add remote collaboration and backup, but they must not become the source of truth for local acceptance gates.

## Identity Model

Hosted identity and local persona identity are separate records:

- Hosted account id: authenticates a user to optional hosted infrastructure.
- Hosted team id: groups hosted accounts for collaboration.
- Hosted permission grants: authorize hosted account access to team-owned or shared hosted scopes.
- Local persona id: selects local knowledge, gaps, conflicts, graph context, and assistant metadata.

A hosted account may operate as more than one local persona. A local persona may be used without any hosted account. Hosted permissions can grant access to hosted scopes, but they do not rewrite local persona metadata.

## Teams And Permissions

Hosted teams may contain:

- accounts
- roles
- permission grants
- hosted shared scopes
- audit records

Permissions are evaluated before hosted data is read or written. Local shared scopes still require explicit local metadata, even when a hosted team grants access. Hosted role names are not local persona ids.

## Hosted Sync

Hosted sync follows the same safety principles as local file-system sync:

- Append-only artifacts may auto-merge when metadata proves the merge is safe.
- Semantic conflicts become conflict records.
- Existing knowledge is not silently overwritten.
- Sync provenance records source device, hosted account id, team id when present, local persona id when selected, and conflict/preflight result.

Hosted sync may stage remote changes before local acceptance. Final local knowledge writes still pass local validation and sync preflight.

## Security And Privacy Risks

Hosted operation introduces risks that local-only operation avoids:

- hosted account compromise
- team permission misconfiguration
- accidental upload of private local persona knowledge
- retention mismatch between local deletion and hosted backups
- remote operator access to hosted data
- cross-persona data exposure through incorrectly scoped shared knowledge

Mitigations required before release:

- explicit opt-in before any data leaves the local machine
- least-privilege hosted permission grants
- audit records for hosted sync and team access
- clear local-vs-hosted provenance on synced records
- conflict records for semantic disagreement
- no silent promotion of private persona knowledge into hosted shared scopes

## Validation Rules

Hosted service work is valid only when:

- local-first operation remains possible with no hosted config
- hosted account ids remain distinct from local persona ids
- hosted teams and permissions are modeled separately from persona metadata
- hosted sync uses validation, provenance, preflight, and conflict records
- security and privacy risks are documented for release decisions

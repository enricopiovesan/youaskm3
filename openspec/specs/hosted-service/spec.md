# hosted-service Specification

Status: Future scope, planning decisions recorded

## Purpose

The hosted-service capability defines an optional hosted convenience layer for youaskm3, including account management, teams, permissions, hosted sync, and hosted runtime operations, without weakening the local-first product.

Hosted service support is an opt-in layer. It must not turn local persona metadata into hosted identity, and it must not replace local validation, local sync preflight, or Traverse-governed runtime acceptance.

Nothing leaves the user's machine by default. Hosted features require explicit setup and consent. Personal hosted sync defaults to end-to-end encrypted blobs; raw/shared/team modes require explicit policy.

## Requirements

### Requirement: Preserve local-first operation

The system SHALL keep local-first operation valid when hosted services are unavailable or unused.

#### Scenario: Hosted service unavailable

- GIVEN the user has a local knowledge root
- WHEN hosted service configuration is absent or unavailable
- THEN local CLI, local runtime, and local Traverse-backed workflows continue to work
- AND hosted account, team, and permission checks are skipped because no hosted scope is being accessed

### Requirement: Require explicit opt-in before data leaves the machine

The system SHALL require explicit hosted feature configuration before content, metadata, runtime requests, or sync state leave the local machine.

#### Scenario: Hosted features absent

- GIVEN no hosted service is configured
- WHEN local commands or runtime workflows run
- THEN no content, metadata, hosted sync state, or hosted runtime request is sent to a hosted service

#### Scenario: Enable hosted feature

- GIVEN the user enables a hosted feature
- WHEN setup runs
- THEN the system states what data leaves the machine
- AND the feature records explicit consent and configuration

### Requirement: Separate hosted identity from local persona

The system SHALL define hosted accounts, teams, and permissions separately from local persona metadata.

#### Scenario: Join a team workspace

- GIVEN a hosted account joins a team
- WHEN the user accesses team knowledge
- THEN access is governed by hosted permissions
- AND local persona id remains distinct from hosted account id
- AND hosted team role names do not become local persona ids

### Requirement: Model hosted teams and permissions explicitly

The system SHALL model hosted teams, roles, and permission grants as hosted records that authorize hosted scopes without rewriting local knowledge metadata.

#### Scenario: Access hosted shared scope

- GIVEN a hosted team grants a hosted account access to a shared scope
- WHEN the user syncs that scope locally
- THEN hosted permission metadata is recorded separately from local persona metadata
- AND local shared-scope metadata remains explicit

### Requirement: Sync without silent conflict loss

The system SHALL preserve the local sync conflict model when hosted sync exists.

#### Scenario: Hosted sync detects conflict

- GIVEN two devices update the same semantic knowledge
- WHEN hosted sync reconciles changes
- THEN safe append-only changes may merge
- AND semantic conflicts become conflict records instead of silent overwrite
- AND sync provenance records hosted account, team, device, local persona when selected, and preflight result

### Requirement: Support hosted sync modes

The system SHALL support sync modes that distinguish encrypted personal sync from explicit readable shared/team modes.

#### Scenario: Personal hosted sync

- GIVEN a user enables personal hosted sync
- WHEN content is uploaded
- THEN the default uploaded form is end-to-end encrypted blobs
- AND the hosted service cannot read raw knowledge content by default

#### Scenario: Explicit raw or team sync

- GIVEN a user enables a raw readable or team/shared mode
- WHEN setup runs
- THEN policy and consent explicitly state that the server or team may access readable content according to that mode
- AND there is no silent downgrade from encrypted to raw sync

### Requirement: Allow hosted runtime only by capability policy

The system SHALL allow hosted runtime execution only when explicit capability placement policy permits it.

#### Scenario: Hosted capability execution

- GIVEN a capability policy permits hosted execution
- WHEN Traverse places that capability on a hosted runtime
- THEN the trace records hosted execution, placement target, capability id, and policy decision
- AND the hosted runtime executes the same WASM/business-logic contracts as local runtime

#### Scenario: Local-only capability

- GIVEN a capability policy is local-only
- WHEN hosted runtime is available
- THEN Traverse does not place that capability on hosted runtime

### Requirement: Document hosted security and privacy risk

The system SHALL document hosted-specific security and privacy risks before hosted service release decisions.

#### Scenario: Review hosted readiness

- GIVEN a release proposes hosted sync or hosted team access
- WHEN hosted readiness is reviewed
- THEN account compromise, permission mistakes, accidental private knowledge upload, retention, operator access, and cross-persona exposure risks are documented
- AND mitigations require explicit opt-in before local data leaves the machine

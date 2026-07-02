# hosted-service Specification

Status: Future scope, unknowns pending

## Purpose

The hosted-service capability defines optional hosted youaskm3 services, including account management, teams, permissions, hosted sync, and hosted runtime operations, without weakening the local-first product.

## Requirements

### Requirement: Preserve local-first operation

The system SHALL keep local-first operation valid when hosted services are unavailable or unused.

#### Scenario: Hosted service unavailable

- GIVEN the user has a local knowledge root
- WHEN hosted service configuration is absent or unavailable
- THEN local CLI, local runtime, and local Traverse-backed workflows continue to work

### Requirement: Separate hosted identity from local persona

The system SHALL define hosted accounts, teams, and permissions separately from local persona metadata.

#### Scenario: Join a team workspace

- GIVEN a hosted account joins a team
- WHEN the user accesses team knowledge
- THEN access is governed by hosted permissions
- AND local persona id remains distinct from hosted account id

### Requirement: Sync without silent conflict loss

The system SHALL preserve the local sync conflict model when hosted sync exists.

#### Scenario: Hosted sync detects conflict

- GIVEN two devices update the same semantic knowledge
- WHEN hosted sync reconciles changes
- THEN safe append-only changes may merge
- AND semantic conflicts become conflict records instead of silent overwrite

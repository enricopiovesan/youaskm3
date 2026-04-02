# federation Specification

## Purpose

The federation capability defines how independent youaskm3 instances become discoverable through a shared registry and cross-instance index while keeping each participant in control of its own repository, hosting, and content.

## Requirements

### Requirement: Register public instances through git workflows

The system SHALL let an instance join the federation through a pull-request-driven registry process instead of a centralized runtime service.

#### Scenario: Add an instance to the registry

- GIVEN an instance is publicly accessible and ready to join the network
- WHEN its maintainer submits the required registry metadata by pull request
- THEN the registry can review and include that instance without direct database writes

### Requirement: Build a shared discoverability index

The system SHALL support a generated cross-instance index that aggregates published instance metadata and searchable summaries.

#### Scenario: Refresh the federation index nightly

- GIVEN the registry has multiple approved instances
- WHEN the scheduled federation job runs
- THEN it produces an updated static index that clients can load to explore the network

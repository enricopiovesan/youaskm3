# federation Specification

## Purpose

The federation capability defines how independent youaskm3 instances become discoverable through a shared registry and cross-instance index while keeping each participant in control of its own repository, hosting, and content.

## Requirements

### Requirement: Register public instances through git workflows

The system SHALL let an instance join the federation through a pull-request-driven registry process against the public `youaskm3/registry` repository instead of a centralized runtime service.

#### Scenario: Add an instance to the registry

- GIVEN an instance is publicly accessible and ready to join the network
- WHEN its maintainer submits the required registry metadata to `instances.json` by pull request
- THEN the registry can review and include that instance without direct database writes

### Requirement: Capture minimum federation metadata

The registry SHALL require enough metadata to identify an instance, explain what it covers, and discover its published search surface.

#### Scenario: Review a registration entry

- GIVEN a maintainer prepares a new federation registration
- WHEN the registry validates the entry
- THEN the entry includes the instance name, published URL, description, topics, join date, and search index location

### Requirement: Document registry participation rules

The system SHALL document the join workflow, review expectations, and removal conditions for federation participation.

#### Scenario: Prepare a compliant join request

- GIVEN a contributor wants to join the federation for the first time
- WHEN they read the registry guidance
- THEN they can prepare a valid `instances.json` entry and understand how approval happens

### Requirement: Build a shared discoverability index

The system SHALL support a generated cross-instance index that aggregates published instance metadata and searchable summaries.

#### Scenario: Refresh the federation index nightly

- GIVEN the registry has multiple approved instances
- WHEN the scheduled federation job runs
- THEN it produces an updated static index that clients can load to explore the network

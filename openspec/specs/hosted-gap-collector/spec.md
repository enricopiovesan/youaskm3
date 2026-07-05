# hosted-gap-collector Specification

Status: Future scope, planning approved

## Purpose

The hosted-gap-collector capability defines the smallest optional hosted surface
needed to make public GitHub Pages chat gap capture low-friction without turning
youaskm3 into a full hosted product.

The collector is a narrow gap inbox. It accepts gap reports from a published
static chat client, validates and rate-limits them, stores them as pending
reports, and exposes them for owner review/import through the youaskm3 CLI. It
does not answer questions, run inference, mutate the local knowledge graph, or
replace the local Traverse-backed runtime.

The recommended first architecture is GitHub Pages plus Cloudflare Worker, D1,
and Turnstile or equivalent zero/near-zero-cost managed primitives. Equivalent
providers are allowed only if they preserve the same trust boundary, cost
controls, portability, and owner-review semantics.

The architecture is documented in
`docs/hosted-gap-collector-architecture.md`.

The reference endpoint and deployment boundary are documented in
`docs/hosted-gap-collector-deployment.md`.

## Requirements

### Requirement: Preserve local-first source of truth

The system SHALL keep the local user-owned instance as the source of truth for
knowledge gaps and graph updates.

#### Scenario: Public gap is submitted

- GIVEN a public visitor submits a gap from a published chat client
- WHEN the hosted collector accepts the report
- THEN the collector stores it as a pending external gap report
- AND the local knowledge instance is not mutated
- AND the knowledge graph is not updated until the owner imports or rejects the report locally

### Requirement: Avoid browser secrets

The system SHALL NOT expose write credentials, GitHub tokens, database tokens,
or hosted service secrets to the GitHub Pages browser client.

#### Scenario: Static chat submits a gap

- GIVEN the chat client runs from static hosting
- WHEN it sends a gap report
- THEN it sends the report to a trusted collector endpoint
- AND the browser bundle contains no write credentials
- AND the collector owns any required server-side secrets

### Requirement: Validate portable gap payloads

The system SHALL define a portable public gap report payload that can be
validated before storage and imported later through the CLI.

#### Scenario: Valid report

- GIVEN a report includes schema version, validation version, question, missing knowledge, published scope, checked evidence, source URL, timestamp, and optional reporter-provided context
- WHEN validation runs
- THEN the collector accepts the report
- AND records a stable report id
- AND records validation version and schema version

#### Scenario: Invalid report

- GIVEN a report omits required fields or exceeds configured limits
- WHEN validation runs
- THEN the collector rejects the report with `HOSTED_GAP_REPORT_INVALID`
- AND no pending gap report is stored

### Requirement: Define provider-equivalent architecture

The system SHALL define the trust, abuse-control, storage, cost, and owner-review
requirements that an equivalent hosted provider must satisfy.

#### Scenario: Equivalent provider selected

- GIVEN the implementation does not use Cloudflare Worker, D1, and Turnstile
- WHEN hosted collector readiness is reviewed
- THEN the provider proves server-side secret custody, challenge or equivalent abuse prevention, origin checks, rate limits, request body limits, pending-only durable storage, owner-readable export or pull path, owner deletion or cleanup path, and conservative cost controls
- AND the provider does not require full hosted accounts, hosted sync, hosted runtime, or hosted inference

### Requirement: Require abuse controls

The system SHALL protect the public collector from unauthenticated abuse before
accepting external writes.

#### Scenario: Abuse checks pass

- GIVEN a visitor submits a gap report
- WHEN Turnstile or equivalent challenge verification, origin checks, size limits, and rate limits pass
- THEN the collector may store the pending report

#### Scenario: Abuse checks fail

- GIVEN challenge verification, origin checks, size limits, or rate limits fail
- WHEN the collector receives the report
- THEN the collector rejects the report with a stable error code
- AND records only the minimum operational telemetry needed for abuse analysis

### Requirement: Use stable hosted gap error codes

The system SHALL expose stable failure codes for collector configuration,
payload validation, abuse checks, rate limits, storage, and owner import.

#### Scenario: Collector missing

- GIVEN the public chat has no hosted collector endpoint configured
- WHEN a visitor tries to submit a hosted gap report
- THEN the UI reports `HOSTED_GAP_COLLECTOR_NOT_CONFIGURED`
- AND offers an honest manual fallback

#### Scenario: Collector rejects or cannot store a report

- GIVEN a hosted gap report reaches the collector
- WHEN payload validation, challenge verification, rate limiting, or storage fails
- THEN the collector maps the failure to one of `HOSTED_GAP_REPORT_INVALID`, `HOSTED_GAP_ABUSE_CHALLENGE_FAILED`, `HOSTED_GAP_RATE_LIMITED`, or `HOSTED_GAP_STORAGE_FAILED`
- AND does not mutate local knowledge or graph artifacts

#### Scenario: Owner import fails

- GIVEN the owner reviews a pending hosted report
- WHEN local CLI import fails
- THEN the CLI reports `HOSTED_GAP_OWNER_IMPORT_FAILED`
- AND preserves the pending hosted report for later review when the provider supports that state

### Requirement: Keep reports pending until owner review

The system SHALL keep hosted reports in a pending/review state until the owner
explicitly imports, rejects, or archives them.

#### Scenario: Owner pulls reports

- GIVEN pending hosted reports exist
- WHEN the owner runs the CLI pull/review command
- THEN the CLI fetches pending reports
- AND shows report id, question, missing knowledge, source URL, published scope, evidence checked, timestamp, and validation status
- AND does not import any report without an explicit owner action

#### Scenario: Owner rejects or archives report

- GIVEN a pending hosted report exists
- WHEN the owner rejects or archives it through the CLI
- THEN the CLI records the owner review action locally when the collector cannot update remote status
- AND the report is not imported into local knowledge

### Requirement: Import through the existing gap lifecycle

The system SHALL import accepted hosted reports through the same local knowledge
gap lifecycle used by local chat.

#### Scenario: Owner imports report

- GIVEN the owner accepts a hosted report
- WHEN the CLI imports it into a local instance
- THEN the CLI creates or updates a local structured knowledge gap
- AND preserves hosted report id, source URL, published scope, reporter context, timestamp, and validation version
- AND marks the hosted report as imported when the provider supports status updates
- AND no report bypasses local validation, provenance, or conflict policy

### Requirement: Support no-account fallback

The system SHALL keep a non-hosted fallback for public gap capture when the
hosted collector is not configured.

#### Scenario: Collector absent

- GIVEN the published chat has no collector endpoint configured
- WHEN a gap is detected
- THEN the UI offers a GitHub issue draft, copy markdown, or download gap package fallback
- AND it clearly states any GitHub account or manual sharing requirement

### Requirement: Bound operating cost

The system SHALL document free-tier assumptions and enforce limits that prevent
unexpected cost growth.

#### Scenario: Collector is configured

- GIVEN an instance enables hosted gap collection
- WHEN setup completes
- THEN the docs list expected provider resources, free-tier assumptions, rate limits, body limits, retention policy, and owner cleanup path
- AND the implementation defaults to conservative quotas suitable for MVP use

### Requirement: Provide a pending-only reference endpoint

The system SHALL provide a minimal reference endpoint that accepts public gap
reports, validates abuse controls, and stores pending reports for owner review.

#### Scenario: Reference endpoint accepts report

- GIVEN a configured hosted gap collector receives a valid public gap report
- WHEN origin, challenge, body size, schema, and rate-limit checks pass
- THEN it returns `HOSTED_GAP_REPORT_ACCEPTED`
- AND stores the report with `pending` status, stable report id, validation version, source URL, published scope, checked evidence, missing knowledge, and reporter context when present
- AND no local knowledge, graph artifact, inference path, GitHub issue, or import status is mutated

### Requirement: Preserve privacy and consent

The system SHALL disclose that public gap submissions leave the static page and
are stored in the configured hosted collector.

#### Scenario: Visitor submits report

- GIVEN a visitor is about to submit a gap
- WHEN the UI presents the submit action
- THEN it states what will be sent and where it will be stored
- AND it does not request or store more personal data than needed for the gap report

### Requirement: Gate hosted collector readiness

The system SHALL fail hosted collector readiness when required abuse controls,
privacy disclosure, or cost limits are missing.

#### Scenario: Enabled collector lacks readiness controls

- GIVEN a public hosted gap collector is enabled
- WHEN readiness validation runs
- THEN it fails unless privacy disclosure, challenge or equivalent abuse control, origin policy, body limit, rate limit, and retention/cost documentation are present
- AND this gate does not require full hosted accounts, hosted sync, hosted teams, or hosted runtime

#### Scenario: Fallback-only deployment is honest

- GIVEN the hosted collector is disabled
- WHEN readiness validation runs
- THEN manual fallback configuration is accepted
- AND docs must not claim automatic or painless public hosted gap submission

### Requirement: Keep hosted collector optional

The system SHALL keep the hosted collector optional and independent from local
runtime, local MCP, local inference, hosted sync, and full hosted accounts.

#### Scenario: Collector disabled

- GIVEN the hosted collector is disabled or unavailable
- WHEN local chat, local CLI, local MCP, or local Traverse-backed workflows run
- THEN they continue to work without hosted collector configuration

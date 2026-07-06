#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT_DIR"

cat >"$TEMP_DIR/readiness-doc.md" <<'EOF'
# Hosted Gap Collector Readiness

## Public Gap Data

The collector receives question, missing knowledge, checked evidence, source URL, published scope, submitted timestamp, and optional reporter context.

## Storage And Access

Reports are stored as pending collector records. The instance owner can read them through the configured owner review endpoint.

## Retention

Pending reports should be reviewed and removed on a short owner-defined schedule.

## Owner Deletion And Export

The owner can export pending reports through the CLI review source and delete, reject, archive, or import them according to collector support.

## Free-Tier And Cost Assumptions

The collector uses conservative request body and rate limits suitable for free-tier MVP operation.
EOF

cat >"$TEMP_DIR/fallback-config.json" <<'JSON'
{
  "hostedGapCollector": {
    "enabled": false,
    "endpoint": null,
    "fallbackIssueUrl": "https://github.com/example/youaskm3/issues/new",
    "fallbackPackageName": "youaskm3-public-gap.md"
  }
}
JSON

ruby ./scripts/hosted-gap-collector-readiness.rb --config "$TEMP_DIR/fallback-config.json" --docs "$TEMP_DIR/readiness-doc.md" >/tmp/hosted-gap-readiness-fallback.json
grep -q '"collector_enabled": false' /tmp/hosted-gap-readiness-fallback.json
grep -q '"hosted_runtime_required": false' /tmp/hosted-gap-readiness-fallback.json

cat >"$TEMP_DIR/enabled-config.json" <<'JSON'
{
  "hostedGapCollector": {
    "enabled": true,
    "endpoint": "https://collector.example.test/gaps",
    "max_body_bytes": 8192,
    "rate_limit_max": 10,
    "rate_limit_window_seconds": 3600,
    "abuseControl": {
      "challenge": true,
      "originPolicy": ["https://example.test"]
    },
    "privacyDisclosure": {
      "public_gap_data": "question, missing knowledge, checked evidence, source URL, scope, timestamp, optional reporter context",
      "storage_location": "configured hosted gap collector pending storage",
      "readable_by": "instance owner and collector operator according to provider policy",
      "retention_expectation": "short owner-reviewed pending retention",
      "owner_deletion_export_path": "m3 hosted-gaps review plus provider deletion/export controls"
    }
  }
}
JSON

ruby ./scripts/hosted-gap-collector-readiness.rb --config "$TEMP_DIR/enabled-config.json" --docs "$TEMP_DIR/readiness-doc.md" >/tmp/hosted-gap-readiness-enabled.json
grep -q '"collector_enabled": true' /tmp/hosted-gap-readiness-enabled.json

ruby -rjson -e 'config=JSON.parse(File.read(ARGV[0])); config["hostedGapCollector"].delete("privacyDisclosure"); File.write(ARGV[1], JSON.pretty_generate(config))' "$TEMP_DIR/enabled-config.json" "$TEMP_DIR/missing-disclosure.json"
if ruby ./scripts/hosted-gap-collector-readiness.rb --config "$TEMP_DIR/missing-disclosure.json" --docs "$TEMP_DIR/readiness-doc.md" >/tmp/missing-disclosure.out 2>/tmp/missing-disclosure.err; then
  echo "Expected missing disclosure to fail." >&2
  exit 1
fi
grep -q 'HOSTED_GAP_DISCLOSURE_MISSING' /tmp/missing-disclosure.err

ruby -rjson -e 'config=JSON.parse(File.read(ARGV[0])); config["hostedGapCollector"].delete("abuseControl"); File.write(ARGV[1], JSON.pretty_generate(config))' "$TEMP_DIR/enabled-config.json" "$TEMP_DIR/missing-abuse.json"
if ruby ./scripts/hosted-gap-collector-readiness.rb --config "$TEMP_DIR/missing-abuse.json" --docs "$TEMP_DIR/readiness-doc.md" >/tmp/missing-abuse.out 2>/tmp/missing-abuse.err; then
  echo "Expected missing abuse control to fail." >&2
  exit 1
fi
grep -q 'HOSTED_GAP_ABUSE_CONTROL_MISSING' /tmp/missing-abuse.err

ruby -rjson -e 'config=JSON.parse(File.read(ARGV[0])); config["hostedGapCollector"].delete("rate_limit_max"); File.write(ARGV[1], JSON.pretty_generate(config))' "$TEMP_DIR/enabled-config.json" "$TEMP_DIR/missing-limits.json"
if ruby ./scripts/hosted-gap-collector-readiness.rb --config "$TEMP_DIR/missing-limits.json" --docs "$TEMP_DIR/readiness-doc.md" >/tmp/missing-limits.out 2>/tmp/missing-limits.err; then
  echo "Expected missing limits to fail." >&2
  exit 1
fi
grep -q 'HOSTED_GAP_LIMIT_MISSING' /tmp/missing-limits.err

cat >"$TEMP_DIR/bad-claim-doc.md" <<'EOF'
# Hosted Gap Collector Readiness

## Public Gap Data
The page offers painless public gap submission for every static deployment.

## Storage And Access
Pending reports are stored by a collector.

## Retention
Reports are reviewed later.

## Owner Deletion And Export
The owner can export reports.

## Free-Tier And Cost Assumptions
Limits are conservative.
EOF

if ruby ./scripts/hosted-gap-collector-readiness.rb --config "$TEMP_DIR/fallback-config.json" --docs "$TEMP_DIR/bad-claim-doc.md" >/tmp/bad-claim.out 2>/tmp/bad-claim.err; then
  echo "Expected automatic fallback claim to fail." >&2
  exit 1
fi
grep -q 'HOSTED_GAP_FALLBACK_CLAIM_INVALID' /tmp/bad-claim.err

echo "Hosted gap collector readiness smoke passed."

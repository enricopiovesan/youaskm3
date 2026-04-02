# Security Policy

## Supported scope

This repository is the source for the youaskm3 foundation, toolchain, CI, and future published site.

Please report security concerns that affect:

- repository code in `crates/`, `app/`, `tools/`, `contracts/`, or `scripts/`
- GitHub Actions workflows and Pages deployment
- published artifacts or static content served by the project
- supply-chain or dependency issues that create a realistic exploit path

## How to report

Do not open a public issue for a suspected security problem.

Instead, report it privately to the maintainer with:

- a short description of the issue
- the affected path or component
- reproduction steps
- impact assessment, if known
- suggested mitigation, if you have one

Use the repository security reporting channel if it is available. Otherwise,
email enrico.piovesan10@gmail.com.

## Response expectations

The goal is to:

- acknowledge credible reports promptly
- reproduce and assess the impact
- fix or mitigate the issue
- disclose publicly only after the issue is understood and addressed

## Out of scope

The following are generally out of scope unless they create a real exploit path:

- issues that depend on a compromised local developer machine
- purely theoretical hardening suggestions with no demonstrated risk
- limitations in future, unimplemented milestones

If you are unsure whether something is in scope, report it privately anyway.

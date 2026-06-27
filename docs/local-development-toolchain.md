# Local Development Toolchain

This page documents the local tools needed to run the full youaskm3 smoke path
from a developer machine. It is intentionally setup guidance only; it does not
install tools automatically or change CI.

## Required Tools

- Rust through `rustup`
- Rust toolchain `1.94.0`, as pinned by `rust-toolchain.toml`
- Rust target `wasm32-wasip1`
- `cargo-llvm-cov`
- Node.js and npm
- npm dependencies from `npm install`
- Python 3.10 or newer for MarkItDown-backed conversion tests

On this machine, the known-good Python is:

```bash
/opt/homebrew/bin/python3.14
```

## Setup Commands

```bash
rustup toolchain install 1.94.0
rustup target add wasm32-wasip1 --toolchain 1.94.0
rustup component add clippy rustfmt llvm-tools-preview --toolchain 1.94.0
cargo install cargo-llvm-cov --locked
npm install
```

If this machine has both Homebrew Rust and rustup Rust installed, prefer the
rustup-managed toolchain when running repository validation:

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH
```

## Full Smoke Command

Use this exact command for the current local setup:

```bash
PATH=/Users/enricopiovesan/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH \
PYTHON=/opt/homebrew/bin/python3.14 \
bash scripts/smoke.sh
```

The smoke path validates CLI setup, MarkItDown routing, PWA assets, Rust lint,
native and `wasm32-wasip1` builds, MVP contracts, Traverse app skeleton checks,
runtime readiness gates, business-logic coverage, TypeScript typecheck, frontend
tests, workflow YAML, and OpenSpec structure.

## Common Failures

| Symptom | Likely cause | Fix |
|---|---|---|
| `Missing required command: cargo` | Rust is not installed or not on `PATH`. | Install rustup and use the `PATH` prefix above. |
| `can't find crate for std` on `wasm32-wasip1` | The WASI target is missing for the active toolchain. | Run `rustup target add wasm32-wasip1 --toolchain 1.94.0`. |
| `MarkItDown requires Python 3.10 or higher` | The active `python3` is too old. | Set `PYTHON=/opt/homebrew/bin/python3.14` or another Python 3.10+ path. |
| `eslint: command not found` or missing TypeScript packages | npm dependencies are not installed. | Run `npm install` from the repo root. |
| `Missing required command: cargo-llvm-cov` | Coverage tool is not installed for the active Cargo path. | Run `cargo install cargo-llvm-cov --locked`. |

## Traverse Readiness

The normal smoke path does not require a live Traverse checkout. When validating
the first-MVP Traverse pairing, use:

```bash
TRAVERSE_REPO=/path/to/Traverse bash scripts/traverse-readiness.sh
```

See [traverse-mvp-requirements.md](traverse-mvp-requirements.md) for the
release-pinned Traverse `v0.5.0` evidence checklist.

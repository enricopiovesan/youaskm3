# wasm-native-model-evidence Specification

Status: Future scope, planning decisions recorded

## Purpose

The wasm-native-model-evidence capability defines how youaskm3 will prove, when Traverse supports it, that model-engine execution itself is WASM-native instead of only Traverse-governed through dependency resolution and placement.

Normal releases may claim Traverse-governed inference. Only releases that claim fully WASM-native inference must pass this evidence gate.

## Requirements

### Requirement: Distinguish governed inference from WASM-native model engine execution

The system SHALL keep the first-MVP caveat explicit until Traverse exposes stable evidence that the model runtime engine executes as a WASM module and model assets are digest-traceable.

#### Scenario: Report current inference mode

- GIVEN Traverse resolves a local or server inference dependency
- WHEN youaskm3 records runtime evidence
- THEN it reports whether the inference dependency was Traverse-governed
- AND separately reports whether the model engine itself was WASM-native when that evidence exists

### Requirement: Define required Traverse evidence

The system SHALL document the Traverse evidence needed before claiming fully WASM-native inference.

#### Scenario: Verify model engine evidence

- GIVEN Traverse exposes model-engine execution evidence
- WHEN youaskm3 readiness validation runs
- THEN validation checks WASM engine/module identity, engine/module digest, model/weights asset id, model/weights digest, placement target, execution trace id, model dependency id, selected provider or candidate id, and failure mode

### Requirement: Fail closed on unsupported claims

The system SHALL fail readiness if docs or release notes claim fully WASM-native inference without matching Traverse evidence.

#### Scenario: Unsupported claim detected

- GIVEN a release note claims fully WASM-native inference
- AND readiness evidence does not prove it
- WHEN validation runs
- THEN the gate fails with a stable unsupported-claim error

#### Scenario: Positive evidence passes

- GIVEN Traverse evidence includes WASM engine/module identity, engine/module digest, model/weights asset id, model/weights digest, placement target, execution trace id, model dependency id, selected provider or candidate id, and null failure mode
- AND readiness explicitly claims fully WASM-native inference
- WHEN validation runs
- THEN the gate passes the positive WASM-native model-engine claim

### Requirement: Allow Traverse-governed inference releases

The system SHALL allow releases that claim Traverse-governed inference without claiming fully WASM-native inference.

#### Scenario: Traverse-governed inference release

- GIVEN a release claims Traverse-governed inference but not fully WASM-native inference
- WHEN readiness validation runs
- THEN WASM-native model-engine evidence is not required
- AND docs preserve the distinction between governed inference and fully WASM-native inference

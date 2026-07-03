#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

REQUIRED_POSITIVE_FIELDS = [
  "traverse_version",
  "inference_dependency_id",
  "selected_candidate_id",
  "model_dependency_id",
  "module_identity",
  "module_sha256",
  "model_asset_id",
  "model_asset_sha256",
  "runtime_placement",
  "execution_trace_id",
  "failure_mode"
].freeze

def usage
  abort "Usage: ruby scripts/wasm-native-model-evidence.rb validate --evidence PATH --claim-wasm-native true|false"
end

def parse_flags(argv)
  flags = {}
  until argv.empty?
    key = argv.shift
    usage unless key.start_with?("--")
    flags[key.delete_prefix("--").tr("-", "_")] = argv.shift || usage
  end
  flags
end

def stable_failure(code, message)
  puts JSON.pretty_generate(
    {
      "status" => "failed",
      "code" => code,
      "message" => message
    }
  )
  exit 1
end

def read_json(path)
  JSON.parse(Pathname.new(path).read)
rescue JSON::ParserError => error
  stable_failure("INVALID_EVIDENCE_JSON", "Evidence JSON is invalid: #{error.message}")
end

def valid_digest?(value)
  value.to_s.match?(/\A[a-f0-9]{64}\z/)
end

def validate_positive_claim!(evidence)
  unless evidence["traverse_governed_inference"] == true
    stable_failure("UNSUPPORTED_WASM_NATIVE_MODEL_CLAIM", "Traverse-governed inference evidence is required before claiming WASM-native model execution.")
  end
  unless evidence["model_engine_wasm_native"] == true
    stable_failure("UNSUPPORTED_WASM_NATIVE_MODEL_CLAIM", "Model engine evidence does not prove WASM-native execution.")
  end

  missing = REQUIRED_POSITIVE_FIELDS.reject { |field| evidence.key?(field) }
  stable_failure("WASM_NATIVE_MODEL_EVIDENCE_MISSING", "Missing required evidence fields: #{missing.join(", ")}") unless missing.empty?

  unless evidence["runtime_placement"] == "wasm"
    stable_failure("UNSUPPORTED_WASM_NATIVE_MODEL_CLAIM", "Runtime placement must be wasm for WASM-native model-engine claims.")
  end
  stable_failure("WASM_NATIVE_MODEL_DIGEST_INVALID", "module_sha256 must be a lowercase SHA-256 digest.") unless valid_digest?(evidence["module_sha256"])
  stable_failure("WASM_NATIVE_MODEL_DIGEST_INVALID", "model_asset_sha256 must be a lowercase SHA-256 digest.") unless valid_digest?(evidence["model_asset_sha256"])
  unless evidence["failure_mode"].nil?
    stable_failure("UNSUPPORTED_WASM_NATIVE_MODEL_CLAIM", "Successful WASM-native model-engine claims require failure_mode to be null.")
  end
end

command = ARGV.shift || usage
usage unless command == "validate"
flags = parse_flags(ARGV)
usage unless flags["evidence"] && ["true", "false"].include?(flags["claim_wasm_native"])

evidence = read_json(flags.fetch("evidence"))
unless evidence["schema_version"] == "1.0.0"
  stable_failure("UNSUPPORTED_EVIDENCE_SCHEMA", "Evidence schema_version must be 1.0.0.")
end

claim_wasm_native = flags.fetch("claim_wasm_native") == "true"
if claim_wasm_native
  validate_positive_claim!(evidence)
  status = "wasm_native_model_engine_proven"
else
  status = evidence["traverse_governed_inference"] ? "traverse_governed_with_wasm_native_caveat" : "inference_not_governed"
end

puts JSON.pretty_generate(
  {
    "status" => status,
    "claim_wasm_native" => claim_wasm_native,
    "traverse_governed_inference" => evidence["traverse_governed_inference"] == true,
    "model_engine_wasm_native" => evidence["model_engine_wasm_native"] == true,
    "required_positive_fields" => REQUIRED_POSITIVE_FIELDS
  }
)

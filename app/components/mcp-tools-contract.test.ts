import { readFileSync } from "node:fs";
import path from "node:path";

import { describe, expect, it } from "vitest";

type JsonSchema = {
  additionalProperties?: boolean;
  properties?: Record<string, unknown>;
  required?: string[];
  type: string | string[];
};

type ToolContract = {
  description: string;
  error_schema: JsonSchema;
  input_schema: JsonSchema;
  name: string;
  output_schema: JsonSchema;
};

type ContractDocument = {
  tools: ToolContract[];
};

function readContracts(): ContractDocument {
  const contractPath = path.resolve(
    process.cwd(),
    "contracts",
    "mcp-tools.json"
  );
  const raw = readFileSync(contractPath, "utf8");

  return JSON.parse(raw) as ContractDocument;
}

describe("mcp-tools contracts", () => {
  it("defines the expected initial tool set", () => {
    const contracts = readContracts();

    expect(contracts.tools.map((tool) => tool.name)).toEqual([
      "search",
      "remember",
      "recall",
      "connect",
      "list_sources",
      "status"
    ]);
  });

  it("requires structured input, output, and error schemas for each tool", () => {
    const contracts = readContracts();

    for (const tool of contracts.tools) {
      expect(tool.description.length).toBeGreaterThan(0);
      expect(tool.input_schema.type).toBe("object");
      expect(tool.output_schema.type).toBe("object");
      expect(tool.error_schema.type).toBe("object");
      expect(tool.input_schema.additionalProperties).toBe(false);
      expect(tool.output_schema.additionalProperties).toBe(false);
      expect(tool.error_schema.additionalProperties).toBe(false);
      expect(tool.error_schema.required).toEqual(["code", "message"]);
      expect(tool.error_schema.properties).toMatchObject({
        code: { type: "string" },
        message: { type: "string" }
      });
    }
  });

  it("pins the richer contract details for the first execution slice", () => {
    const contracts = readContracts();
    const searchContract = contracts.tools.find((tool) => tool.name === "search");
    const rememberContract = contracts.tools.find(
      (tool) => tool.name === "remember"
    );
    const statusContract = contracts.tools.find((tool) => tool.name === "status");

    expect(searchContract).toBeDefined();
    expect(searchContract?.output_schema.properties).toHaveProperty("results");
    expect(rememberContract?.input_schema.required).toEqual([
      "source",
      "source_type"
    ]);
    expect(rememberContract?.output_schema.required).toEqual([
      "accepted",
      "entry_id",
      "stored_path"
    ]);
    expect(statusContract?.output_schema.required).toEqual([
      "status",
      "last_sync_at",
      "indexed_sources"
    ]);
  });
});

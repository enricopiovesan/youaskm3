import { readFileSync } from "node:fs";
import path from "node:path";

import { describe, expect, it } from "vitest";

type FederationInstance = {
  author_instance_url?: string;
  description: string;
  name: string;
  repo?: string;
  search_index_url: string;
  since: string;
  topics: string[];
  url: string;
};

type FederationRegistryDocument = {
  instances: FederationInstance[];
  registry_repository: string;
};

type JsonSchema = {
  properties?: Record<string, unknown>;
  required?: string[];
};

function readRegistrySchema(): JsonSchema {
  const schemaPath = path.resolve(
    process.cwd(),
    "contracts",
    "federation-instances.schema.json"
  );

  return JSON.parse(readFileSync(schemaPath, "utf8")) as JsonSchema;
}

function readRegistryExample(): FederationRegistryDocument {
  const examplePath = path.resolve(
    process.cwd(),
    "contracts",
    "federation-instances.example.json"
  );

  return JSON.parse(readFileSync(examplePath, "utf8")) as FederationRegistryDocument;
}

describe("federation registry contract", () => {
  it("pins the canonical registry repository and required fields", () => {
    const schema = readRegistrySchema();
    const instanceSchema = schema.properties?.instances as { items: JsonSchema };

    expect(schema.required).toEqual(["registry_repository", "instances"]);
    expect(instanceSchema.items.required).toEqual([
      "name",
      "url",
      "search_index_url",
      "description",
      "topics",
      "since"
    ]);
  });

  it("provides a compliant example entry for join requests", () => {
    const example = readRegistryExample();
    const [entry] = example.instances;

    expect(example.registry_repository).toBe("https://github.com/youaskm3/registry");
    expect(example.instances).toHaveLength(1);
    expect(entry.name.length).toBeGreaterThan(0);
    expect(entry.url).toMatch(/^https:\/\/.+\/$/u);
    expect(entry.search_index_url).toMatch(/^https:\/\/.+\/search-index\.json$/u);
    expect(entry.description.length).toBeGreaterThan(0);
    expect(entry.topics.length).toBeGreaterThan(0);
    expect(entry.since).toMatch(/^\d{4}-\d{2}-\d{2}$/u);
  });
});

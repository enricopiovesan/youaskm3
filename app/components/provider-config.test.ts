import { describe, expect, it } from "vitest";

import {
  DEFAULT_AUTHOR_INSTANCE,
  DEFAULT_PROVIDER_CONFIG,
  activeProvider,
  providerOptionLabels,
  providerSummary,
  updateActiveProvider
} from "./provider-config";

describe("provider config", () => {
  it("exposes a default publishable provider set", () => {
    expect(DEFAULT_PROVIDER_CONFIG.activeProviderId).toBe("traverse-local");
    expect(providerOptionLabels(DEFAULT_PROVIDER_CONFIG)).toEqual([
      "Browser demo",
      "Traverse local",
      "Claude API",
      "OpenAI API"
    ]);
    expect(activeProvider(DEFAULT_PROVIDER_CONFIG)).toMatchObject({
      id: "traverse-local",
      runtime: "traverse-http"
    });
  });

  it("updates the active provider when the profile exists", () => {
    const updated = updateActiveProvider(DEFAULT_PROVIDER_CONFIG, "browser-demo");

    expect(updated.activeProviderId).toBe("browser-demo");
    expect(activeProvider(updated)?.runtime).toBe("browser-harness");
  });

  it("rejects unknown provider ids", () => {
    expect(() =>
      updateActiveProvider(DEFAULT_PROVIDER_CONFIG, "missing-provider")
    ).toThrow("unknown provider profile: missing-provider");
  });

  it("formats a provider summary for the active profile", () => {
    expect(providerSummary(DEFAULT_PROVIDER_CONFIG)).toContain(
      "Traverse local uses http://127.0.0.1:8787"
    );
  });
});

describe("author instance manifest", () => {
  it("points at the published shell and known providers", () => {
    expect(DEFAULT_AUTHOR_INSTANCE.instanceId).toBe("youaskm3-author");
    expect(DEFAULT_AUTHOR_INSTANCE.shellUrl).toContain("github.io/youaskm3");
    expect(DEFAULT_AUTHOR_INSTANCE.providerProfiles).toContain("browser-demo");
    expect(DEFAULT_AUTHOR_INSTANCE.providerProfiles).toContain("traverse-local");
  });
});

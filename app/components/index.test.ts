import { describe, expect, it } from "vitest";

import { componentNamespace } from "./index";

describe("componentNamespace", () => {
  it("returns the expected namespace", () => {
    expect(componentNamespace()).toBe("youaskm3");
  });
});

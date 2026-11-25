import { describe, expect, it } from "vitest";
import { fallbackProductName, productName, productNameFrom } from "./product";

describe("productNameFrom", () => {
  it("uses the configured name, trimmed", () => {
    expect(productNameFrom("  Yarnspun  ")).toBe("Yarnspun");
    expect(productNameFrom("Anything")).toBe("Anything");
  });
  it("falls back when the value is missing or blank", () => {
    expect(productNameFrom(undefined)).toBe(fallbackProductName);
    expect(productNameFrom("   ")).toBe(fallbackProductName);
  });
  it("reads the build's .env by default", () => {
    expect(productName).toBe("Yarnspun");
  });
});

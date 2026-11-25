/**
 * The public product name (ADR 0022). The project is TaleQuilt, and that name stays in code, resources and
 * documents; what users see is a configuration value, so a rename is a variable change, not a code change.
 * The default comes from .env at build time; the Deploy workflow passes an environment's PRODUCT_NAME variable.
 */
export const fallbackProductName = "Yarnspun";

export function productNameFrom(value: string | undefined): string {
  const trimmed = value?.trim() ?? "";
  return trimmed.length > 0 ? trimmed : fallbackProductName;
}

export const productName = productNameFrom(import.meta.env.VITE_PRODUCT_NAME);

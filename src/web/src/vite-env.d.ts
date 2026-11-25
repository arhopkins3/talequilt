/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Origin of the API when it is not served from the same host; empty or unset means same origin. */
  readonly VITE_API_BASE_URL?: string;
  /** The public product name shown to users (ADR 0022); the build's .env sets the default. */
  readonly VITE_PRODUCT_NAME?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

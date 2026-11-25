import { defineConfig } from "@playwright/test";

// End-to-end and accessibility checks (ADR 0021, Phase 3 build item 3b). Playwright serves the production build
// from dist/ with `vite preview`, whose /api proxy points at the API named by E2E_API_BASE_URL (the staging API
// in the Deploy workflow; the local API by default). Run `npm run build` first.
export default defineConfig({
  testDir: "./e2e",
  testMatch: /.*\.e2e\.ts$/,
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 120_000,
  expect: { timeout: 15_000 },
  reporter: [["list"], ["html", { open: "never", outputFolder: "playwright-report" }]],
  use: {
    baseURL: "http://localhost:4173",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
  webServer: {
    command: "npm run preview -- --port 4173 --strictPort",
    url: "http://localhost:4173",
    reuseExistingServer: false,
    timeout: 60_000,
  },
});

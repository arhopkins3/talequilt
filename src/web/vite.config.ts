import { configDefaults, defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

// Where /api goes when the web app is served by Vite rather than Static Web Apps.
// - dev: the local ASP.NET Core API.
// - preview (the end-to-end suite, ADR 0021): the staging API, named by E2E_API_BASE_URL. The suite drives a
//   local production build, because the deployed web app sits behind invited-user sign-in that a test runner
//   cannot complete, and the build is made without VITE_API_BASE_URL so its calls stay same-origin and reach
//   the staging API through this proxy from the runner's own address, which the Deploy workflow allow-lists
//   for the length of the job. The API's CORS policy is not involved; the deploy smoke tests cover the real
//   cross-origin path.
// The file public/staticwebapp.config.json is the Static Web Apps side of the same story (the ADR 0008 stopgap):
// every route needs the 'author' role, which only an invited user holds; a visitor without it is sent to GitHub
// sign-in, and a signed-in user without it gets forbidden.html. Vite copies it to the build output unchanged.
const apiTarget = process.env.E2E_API_BASE_URL ?? "http://localhost:5080";
const proxy = { "/api": { target: apiTarget, changeOrigin: true, secure: true } };

export default defineConfig({
  plugins: [react()],
  server: { proxy },
  preview: { proxy },
  test: {
    environment: "jsdom",
    globals: false,
    setupFiles: ["./src/test/setup.ts"],
    // The end-to-end suite under e2e/ is Playwright's, not Vitest's.
    exclude: [...configDefaults.exclude, "e2e/**"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json-summary", "lcov"],
      include: ["src/**/*.{ts,tsx}"],
      // Entry point and test helpers are excluded (ADR 0017); everything else counts.
      exclude: ["src/main.tsx", "src/test/**", "src/**/*.test.{ts,tsx}", "src/vite-env.d.ts"],
      thresholds: { lines: 80, statements: 80, functions: 80, branches: 80 },
    },
  },
});

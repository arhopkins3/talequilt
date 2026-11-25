import { expect, test, type Page } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

// The API behind the proxy scales down when idle, so the first probe can take most of a minute; the app shows
// "waking up" while it retries. Every test waits for the healthy verdict before judging anything else.
const coldStart = { timeout: 90_000 };

async function openWhenHealthy(page: Page) {
  await page.goto("/");
  await expect(page.getByRole("status")).toHaveText(/API: healthy/, coldStart);
}

test.describe("The web app against a live API", () => {
  test("reports the API healthy and shows the books list", async ({ page }) => {
    await openWhenHealthy(page);
    await expect(page.getByRole("heading", { name: "Books" })).toBeVisible();
    await expect(page.getByText(/No books yet/).or(page.getByRole("list"))).toBeVisible();
    await expect(page.getByRole("button", { name: "Add book" })).toBeVisible();
  });

  test("adds a book and shows it in the list", async ({ page }) => {
    await openWhenHealthy(page);
    // One row per run in the environment under test: the title says where it came from.
    const title = `Pipeline check ${process.env.GITHUB_RUN_ID ?? "local"} ${new Date().toISOString()}`;
    await page.getByLabel("Title").fill(title);
    await page.getByRole("button", { name: "Add book" }).click();
    await expect(page.getByRole("listitem").filter({ hasText: title })).toBeVisible();
    await expect(page.getByLabel("Title")).toHaveValue("");
  });

  test("has no serious or critical accessibility violations", async ({ page }) => {
    await openWhenHealthy(page);
    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
      .analyze();
    const blocking = results.violations.filter(
      (v) => v.impact === "serious" || v.impact === "critical",
    );
    expect(blocking, JSON.stringify(blocking, null, 2)).toEqual([]);
  });
});

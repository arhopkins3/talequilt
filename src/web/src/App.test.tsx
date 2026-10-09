import { describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { App } from "./App";

function mockFetch(routes: Record<string, (init?: RequestInit) => Response>) {
  const spy = vi.fn((input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
    const key = `${init?.method ?? "GET"} ${url}`;
    const handler = routes[key];
    if (!handler) return Promise.reject(new Error(`unexpected ${key}`));
    return Promise.resolve(handler(init));
  });
  vi.stubGlobal("fetch", spy);
  return spy;
}

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

describe("App", () => {
  it("shows the API health and an empty state", async () => {
    mockFetch({
      "GET /api/health": () => new Response("Healthy", { status: 200 }),
      "GET /api/books": () => json(200, []),
    });

    render(<App />);

    expect(await screen.findByRole("status")).toHaveTextContent("API: healthy");
    expect(screen.getByText(/No books yet/)).toBeInTheDocument();
  });

  it("lists books and adds a new one", async () => {
    const user = userEvent.setup();
    const existing = [{ id: "1", title: "First", createdAt: "2026-10-09T00:00:00Z" }];
    mockFetch({
      "GET /api/health": () => new Response("Healthy", { status: 200 }),
      "GET /api/books": () => json(200, existing),
      "POST /api/books": (init) => {
        const { title } = JSON.parse(init?.body as string) as { title: string };
        return json(201, { id: "2", title, createdAt: "2026-10-09T00:00:01Z" });
      },
    });

    render(<App />);

    expect(await screen.findByText("First")).toBeInTheDocument();
    await user.type(screen.getByLabelText("Title"), "Second");
    await user.click(screen.getByRole("button", { name: "Add book" }));

    expect(await screen.findByText("Second")).toBeInTheDocument();
    expect(screen.getByLabelText("Title")).toHaveValue("");
  });

  it("shows a validation error from the API", async () => {
    const user = userEvent.setup();
    mockFetch({
      "GET /api/health": () => new Response("Healthy", { status: 200 }),
      "GET /api/books": () => json(200, []),
      "POST /api/books": () => json(400, { errors: { title: ["A book needs a title."] } }),
    });

    render(<App />);
    await screen.findByRole("status");
    await user.type(screen.getByLabelText("Title"), "x");
    await user.click(screen.getByRole("button", { name: "Add book" }));

    expect(await screen.findByRole("alert")).toHaveTextContent("A book needs a title.");
  });

  it("reports an unhealthy API and a failed list", async () => {
    mockFetch({
      "GET /api/health": () => new Response(null, { status: 503 }),
      "GET /api/books": () => new Response(null, { status: 500 }),
    });

    render(<App />);

    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("API: unhealthy"));
    expect(await screen.findByRole("alert")).toHaveTextContent("Request failed (500).");
  });
});

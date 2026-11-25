import { describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { App, type HealthRetry } from "./App";

// Tests never wait for the real back-off: three quick probes stand in for the twelve slow ones.
const fastRetry: HealthRetry = { attempts: 3, intervalMs: 0 };

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

    render(<App retry={fastRetry} />);

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

    render(<App retry={fastRetry} />);

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

    render(<App retry={fastRetry} />);
    await screen.findByText(/No books yet/);
    await user.type(screen.getByLabelText("Title"), "x");
    await user.click(screen.getByRole("button", { name: "Add book" }));

    expect(await screen.findByRole("alert")).toHaveTextContent("A book needs a title.");
  });

  it("keeps the form disabled until the list has loaded", async () => {
    let resolveList: (r: Response) => void = () => {};
    vi.stubGlobal(
      "fetch",
      vi.fn((input: RequestInfo | URL) => {
        const url = String(input);
        if (url.endsWith("/api/books")) return new Promise<Response>((r) => (resolveList = r));
        return Promise.resolve(new Response("Healthy", { status: 200 }));
      }),
    );

    render(<App retry={fastRetry} />);

    expect(await screen.findByRole("status")).toHaveTextContent("API: healthy");
    expect(screen.getByText(/Loading books/)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Add book" })).toBeDisabled();
    resolveList(json(200, []));
    expect(await screen.findByText(/No books yet/)).toBeInTheDocument();
  });

  it("says the API is waking up while it retries, then reports it healthy", async () => {
    let probes = 0;
    mockFetch({
      "GET /api/health": () =>
        ++probes < 3
          ? new Response(null, { status: 503 })
          : new Response("Healthy", { status: 200 }),
      "GET /api/books": () => json(200, []),
    });

    render(<App retry={{ attempts: 5, intervalMs: 10 }} />);

    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("API: waking up"));
    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("API: healthy"));
    expect(probes).toBe(3);
    expect(await screen.findByText(/No books yet/)).toBeInTheDocument();
  });

  it("reports an unhealthy API once the retries run out, and a failed list", async () => {
    let probes = 0;
    mockFetch({
      "GET /api/health": () => {
        probes++;
        return new Response(null, { status: 503 });
      },
      "GET /api/books": () => new Response(null, { status: 500 }),
    });

    render(<App retry={fastRetry} />);

    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("API: unhealthy"));
    expect(probes).toBe(fastRetry.attempts);
    expect(await screen.findByRole("alert")).toHaveTextContent("Request failed (500).");
  });

  it("stops retrying at once when the allow-list refuses this address", async () => {
    let probes = 0;
    mockFetch({
      "GET /api/health": () => {
        probes++;
        return new Response(null, { status: 403 });
      },
      "GET /api/books": () => new Response(null, { status: 403 }),
    });

    render(<App retry={fastRetry} />);

    await waitFor(() =>
      expect(screen.getByRole("status")).toHaveTextContent("API: not reachable from this address"),
    );
    expect(probes).toBe(1);
  });

  it("reports the API unreachable when nothing answers", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(() => Promise.reject(new TypeError("offline"))),
    );

    render(<App retry={fastRetry} />);

    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("API: unreachable"));
    expect(await screen.findByRole("alert")).toHaveTextContent("offline");
  });
});

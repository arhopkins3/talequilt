import { describe, expect, it } from "vitest";
import { createBook, getHealth, listBooks } from "./api";

function fakeFetch(status: number, body: unknown): typeof fetch {
  return (() =>
    Promise.resolve(
      new Response(body === undefined ? null : JSON.stringify(body), {
        status,
        headers: { "Content-Type": "application/json" },
      }),
    )) as typeof fetch;
}

describe("getHealth", () => {
  it("is healthy on a 200", async () => {
    expect(await getHealth(fakeFetch(200, undefined))).toBe("healthy");
  });
  it("is unhealthy on a 503", async () => {
    expect(await getHealth(fakeFetch(503, undefined))).toBe("unhealthy");
  });
  it("is unhealthy when the network fails", async () => {
    const failing = (() => Promise.reject(new TypeError("offline"))) as typeof fetch;
    expect(await getHealth(failing)).toBe("unhealthy");
  });
});

describe("listBooks", () => {
  it("returns the books", async () => {
    const books = [{ id: "1", title: "A", createdAt: "2026-10-09T00:00:00Z" }];
    expect(await listBooks(fakeFetch(200, books))).toEqual(books);
  });
  it("throws the status when the request fails without a problem body", async () => {
    await expect(listBooks(fakeFetch(500, undefined))).rejects.toThrow("Request failed (500).");
  });
});

describe("createBook", () => {
  it("posts the title and returns the created book", async () => {
    let captured: RequestInit | undefined;
    const fetcher = ((_: string, init?: RequestInit) => {
      captured = init;
      return Promise.resolve(
        new Response(JSON.stringify({ id: "2", title: "B", createdAt: "x" }), { status: 201 }),
      );
    }) as typeof fetch;

    const book = await createBook("B", fetcher);

    expect(book.id).toBe("2");
    expect(captured?.method).toBe("POST");
    expect(JSON.parse(captured?.body as string)).toEqual({ title: "B" });
  });
  it("surfaces validation messages from a problem document", async () => {
    const problem = { errors: { title: ["A book needs a title."] } };
    await expect(createBook("", fakeFetch(400, problem))).rejects.toThrow("A book needs a title.");
  });
  it("falls back to the problem title when there are no field errors", async () => {
    await expect(createBook("", fakeFetch(400, { title: "Bad Request" }))).rejects.toThrow(
      "Bad Request",
    );
  });
});

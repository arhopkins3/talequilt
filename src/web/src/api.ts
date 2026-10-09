export interface Book {
  id: string;
  title: string;
  createdAt: string;
}

export type Health = "healthy" | "unhealthy";

interface ValidationProblem {
  errors?: Record<string, string[]>;
  title?: string;
}

async function parseProblem(response: Response): Promise<string> {
  try {
    const problem = (await response.json()) as ValidationProblem;
    const messages = Object.values(problem.errors ?? {}).flat();
    if (messages.length > 0) return messages.join(" ");
    if (problem.title) return problem.title;
  } catch {
    // Not a problem document; fall through to the status text.
  }
  return `Request failed (${response.status}).`;
}

export async function getHealth(fetcher: typeof fetch = fetch): Promise<Health> {
  try {
    const response = await fetcher("/api/health");
    return response.ok ? "healthy" : "unhealthy";
  } catch {
    return "unhealthy";
  }
}

export async function listBooks(fetcher: typeof fetch = fetch): Promise<Book[]> {
  const response = await fetcher("/api/books");
  if (!response.ok) throw new Error(await parseProblem(response));
  return (await response.json()) as Book[];
}

export async function createBook(title: string, fetcher: typeof fetch = fetch): Promise<Book> {
  const response = await fetcher("/api/books", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title }),
  });
  if (!response.ok) throw new Error(await parseProblem(response));
  return (await response.json()) as Book;
}

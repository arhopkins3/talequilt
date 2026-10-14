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

/**
 * Where the API lives. Empty in development, where Vite proxies /api to the API on one origin, and in tests.
 * In Azure the web app is served by Static Web Apps and the API by Container Apps on another hostname, so the
 * build sets VITE_API_BASE_URL and the API allows that origin in its CORS policy (ADR 0021).
 */
export function apiUrl(
  path: string,
  base: string | undefined = import.meta.env.VITE_API_BASE_URL,
): string {
  const trimmed = (base ?? "").replace(/\/+$/, "");
  return `${trimmed}${path}`;
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
    const response = await fetcher(apiUrl("/api/health"));
    return response.ok ? "healthy" : "unhealthy";
  } catch {
    return "unhealthy";
  }
}

export async function listBooks(fetcher: typeof fetch = fetch): Promise<Book[]> {
  const response = await fetcher(apiUrl("/api/books"));
  if (!response.ok) throw new Error(await parseProblem(response));
  return (await response.json()) as Book[];
}

export async function createBook(title: string, fetcher: typeof fetch = fetch): Promise<Book> {
  const response = await fetcher(apiUrl("/api/books"), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title }),
  });
  if (!response.ok) throw new Error(await parseProblem(response));
  return (await response.json()) as Book;
}

import { useEffect, useState, type FormEvent } from "react";
import { createBook, getHealth, listBooks, type Book, type Health } from "./api";

/**
 * How long to keep probing before giving a verdict. Both environments scale down when idle (the API to zero
 * replicas in staging, the database to paused everywhere), so the first request after a quiet spell can take
 * most of a minute. Showing "unhealthy" in that window was a false alarm twice in the first week.
 */
export interface HealthRetry {
  attempts: number;
  intervalMs: number;
}

const defaultRetry: HealthRetry = { attempts: 12, intervalMs: 5000 };

type HealthState = Health | "checking" | "waking";

const healthText: Record<HealthState, string> = {
  checking: "checking…",
  waking: "waking up… this can take a minute after a quiet spell",
  healthy: "healthy",
  unhealthy: "unhealthy (it answered, but its database check failed)",
  forbidden: "not reachable from this address (it answers only allow-listed addresses)",
  unreachable: "unreachable",
};

const wait = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/** Probes until the API is healthy, refuses this address, or the attempts run out. */
async function settleHealth(
  retry: HealthRetry,
  onWaking: () => void,
  isCancelled: () => boolean,
): Promise<Health | null> {
  for (let attempt = 1; ; attempt++) {
    const health = await getHealth();
    if (isCancelled()) return null;
    if (health === "healthy" || health === "forbidden" || attempt >= retry.attempts) return health;
    onWaking();
    await wait(retry.intervalMs);
    if (isCancelled()) return null;
  }
}

export function App({ retry = defaultRetry }: { retry?: HealthRetry } = {}) {
  const [health, setHealth] = useState<HealthState>("checking");
  const [books, setBooks] = useState<Book[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [title, setTitle] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      const settled = await settleHealth(
        retry,
        () => setHealth("waking"),
        () => cancelled,
      );
      if (settled === null) return;
      setHealth(settled);
      try {
        const list = await listBooks();
        if (!cancelled) setBooks(list);
      } catch (e: unknown) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Could not load books.");
      } finally {
        if (!cancelled) setLoaded(true);
      }
    };
    void run();
    return () => {
      cancelled = true;
    };
  }, [retry]);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const book = await createBook(title);
      setBooks((current) => [...current, book]);
      setTitle("");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Could not create the book.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main>
      <h1>TaleQuilt</h1>
      <p className="status" data-state={health} role="status">
        API: {healthText[health]}
      </p>

      <h2>Books</h2>
      {!loaded ? (
        <p>Loading books…</p>
      ) : books.length === 0 ? (
        <p>No books yet. Add the first one below.</p>
      ) : (
        <ul>
          {books.map((book) => (
            <li key={book.id}>{book.title}</li>
          ))}
        </ul>
      )}

      <form onSubmit={(e) => void onSubmit(e)}>
        <label htmlFor="title" className="sr-only">
          Title
        </label>
        <input
          id="title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Book title"
          maxLength={200}
          required
        />
        <button type="submit" disabled={!loaded || busy || title.trim().length === 0}>
          Add book
        </button>
      </form>
      {error ? (
        <p className="error" role="alert">
          {error}
        </p>
      ) : null}
    </main>
  );
}

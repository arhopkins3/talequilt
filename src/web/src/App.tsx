import { useEffect, useState, type FormEvent } from "react";
import { createBook, getHealth, listBooks, type Book, type Health } from "./api";

export function App() {
  const [health, setHealth] = useState<Health | "checking">("checking");
  const [books, setBooks] = useState<Book[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [title, setTitle] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    void getHealth().then((h) => {
      if (!cancelled) setHealth(h);
    });
    void listBooks()
      .then((b) => {
        if (!cancelled) setBooks(b);
      })
      .catch((e: unknown) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "Could not load books.");
      })
      .finally(() => {
        if (!cancelled) setLoaded(true);
      });
    return () => {
      cancelled = true;
    };
  }, []);

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
        API: {health === "checking" ? "checking…" : health}
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

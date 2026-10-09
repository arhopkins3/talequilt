namespace TaleQuilt.Core.Books;

/// <summary>
/// A manuscript the author is turning into an illustrated book. Phase 1 holds only identity and title;
/// chapters, scenes and the book bible arrive in Phases 5 and 6.
/// </summary>
public sealed class Book
{
    public const int TitleMaxLength = 200;

    private Book(Guid id, string title, DateTimeOffset createdAt)
    {
        Id = id;
        Title = title;
        CreatedAt = createdAt;
    }

    public Guid Id { get; private set; }

    public string Title { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    /// <summary>
    /// Creates a book from an author-supplied title. The title is author input, so it is trimmed and bounded here,
    /// before it is stored or shown to anyone.
    /// </summary>
    public static Book Create(string title, TimeProvider clock)
    {
        ArgumentNullException.ThrowIfNull(clock);
        var cleaned = (title ?? string.Empty).Trim();
        if (cleaned.Length == 0)
        {
            throw new ArgumentException("A book needs a title.", nameof(title));
        }

        if (cleaned.Length > TitleMaxLength)
        {
            throw new ArgumentException($"A title may be at most {TitleMaxLength} characters.", nameof(title));
        }

        return new Book(Guid.CreateVersion7(), cleaned, clock.GetUtcNow());
    }
}

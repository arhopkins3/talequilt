using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using TaleQuilt.Core.Books;
using TaleQuilt.Core.Data;

namespace TaleQuilt.Api.Endpoints;

public static class BookEndpoints
{
    public static IEndpointRouteBuilder MapBookEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/books").WithTags("Books");

        group.MapGet("/", ListBooks);
        group.MapGet("/{id:guid}", GetBook).WithName("GetBook");
        group.MapPost("/", CreateBook);

        return routes;
    }

    private static async Task<Ok<IReadOnlyList<BookResponse>>> ListBooks(TaleQuiltDbContext db, CancellationToken ct)
    {
        var books = await db.Books
            .OrderBy(b => b.CreatedAt)
            .Select(b => new BookResponse(b.Id, b.Title, b.CreatedAt))
            .ToListAsync(ct)
            .ConfigureAwait(false);
        return TypedResults.Ok<IReadOnlyList<BookResponse>>(books);
    }

    private static async Task<Results<Ok<BookResponse>, NotFound>> GetBook(Guid id, TaleQuiltDbContext db, CancellationToken ct)
    {
        var book = await db.Books.FindAsync([id], ct).ConfigureAwait(false);
        return book is null
            ? TypedResults.NotFound()
            : TypedResults.Ok(new BookResponse(book.Id, book.Title, book.CreatedAt));
    }

    private static async Task<Results<CreatedAtRoute<BookResponse>, ValidationProblem>> CreateBook(
        CreateBookRequest request, TaleQuiltDbContext db, TimeProvider clock, CancellationToken ct)
    {
        Book book;
        try
        {
            book = Book.Create(request.Title, clock);
        }
        catch (ArgumentException ex)
        {
            return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["title"] = [ex.Message] });
        }

        db.Books.Add(book);
        await db.SaveChangesAsync(ct).ConfigureAwait(false);

        var response = new BookResponse(book.Id, book.Title, book.CreatedAt);
        return TypedResults.CreatedAtRoute(response, "GetBook", new { id = book.Id });
    }
}

public sealed record CreateBookRequest(string Title);

public sealed record BookResponse(Guid Id, string Title, DateTimeOffset CreatedAt);

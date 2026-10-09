using System.Net;
using System.Net.Http.Json;
using Shouldly;
using TaleQuilt.Api.Endpoints;

namespace TaleQuilt.Api.Tests;

public sealed class BooksEndpointTests(ApiFixture fixture) : IClassFixture<ApiFixture>
{
    private readonly HttpClient _client = fixture.CreateClient();

    [Fact]
    public async Task Health_reports_healthy_when_the_database_is_reachable()
    {
        var response = await _client.GetAsync(new Uri("/api/health", UriKind.Relative), TestContext.Current.CancellationToken);

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
        (await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken)).ShouldBe("Healthy");
    }

    [Fact]
    public async Task Creating_a_book_returns_it_and_makes_it_listable()
    {
        var create = await _client.PostAsJsonAsync("/api/books", new CreateBookRequest("  The Lighthouse Keeper's Cat "), TestContext.Current.CancellationToken);

        create.StatusCode.ShouldBe(HttpStatusCode.Created);
        var created = await create.Content.ReadFromJsonAsync<BookResponse>(TestContext.Current.CancellationToken);
        created.ShouldNotBeNull();
        created.Title.ShouldBe("The Lighthouse Keeper's Cat");
        create.Headers.Location.ShouldNotBeNull();
        create.Headers.Location.ToString().ShouldEndWith($"/api/books/{created.Id}");

        var fetched = await _client.GetFromJsonAsync<BookResponse>(create.Headers.Location, TestContext.Current.CancellationToken);
        fetched.ShouldBe(created);

        var list = await _client.GetFromJsonAsync<List<BookResponse>>("/api/books", TestContext.Current.CancellationToken);
        list.ShouldNotBeNull();
        list.ShouldContain(created);
    }

    [Fact]
    public async Task Creating_a_book_with_a_blank_title_is_a_validation_problem()
    {
        var response = await _client.PostAsJsonAsync("/api/books", new CreateBookRequest("   "), TestContext.Current.CancellationToken);

        response.StatusCode.ShouldBe(HttpStatusCode.BadRequest);
        var problem = await response.Content.ReadFromJsonAsync<Microsoft.AspNetCore.Mvc.ValidationProblemDetails>(TestContext.Current.CancellationToken);
        problem.ShouldNotBeNull();
        problem.Errors.ShouldContainKey("title");
    }

    [Fact]
    public async Task Getting_an_unknown_book_is_not_found()
    {
        var response = await _client.GetAsync(new Uri($"/api/books/{Guid.NewGuid()}", UriKind.Relative), TestContext.Current.CancellationToken);

        response.StatusCode.ShouldBe(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Listing_books_orders_them_by_creation()
    {
        var first = await (await _client.PostAsJsonAsync("/api/books", new CreateBookRequest("Order A"), TestContext.Current.CancellationToken))
            .Content.ReadFromJsonAsync<BookResponse>(TestContext.Current.CancellationToken);
        var second = await (await _client.PostAsJsonAsync("/api/books", new CreateBookRequest("Order B"), TestContext.Current.CancellationToken))
            .Content.ReadFromJsonAsync<BookResponse>(TestContext.Current.CancellationToken);

        var list = await _client.GetFromJsonAsync<List<BookResponse>>("/api/books", TestContext.Current.CancellationToken);

        list.ShouldNotBeNull();
        list.IndexOf(first!).ShouldBeLessThan(list.IndexOf(second!));
    }
}

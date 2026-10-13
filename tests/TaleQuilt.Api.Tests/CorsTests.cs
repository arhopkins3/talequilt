using Microsoft.Extensions.Configuration;
using Shouldly;

namespace TaleQuilt.Api.Tests;

/// <summary>
/// The web app runs on another hostname in Azure (ADR 0021), so the API must answer cross-origin requests from
/// the configured origin and from nowhere else.
/// </summary>
public sealed class CorsTests(ApiFixture fixture) : IClassFixture<ApiFixture>
{
    private const string WebOrigin = "https://web.example.test";

    private HttpClient ClientWithOrigins(params string[] origins) =>
        fixture.WithWebHostBuilder(builder => builder.ConfigureAppConfiguration((_, config) =>
            config.AddInMemoryCollection(origins.Select((o, i) =>
                new KeyValuePair<string, string?>($"Cors:AllowedOrigins:{i}", o)))))
            .CreateClient();

    [Fact]
    public async Task Configured_origin_is_allowed()
    {
        using var client = ClientWithOrigins(WebOrigin);
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/health");
        request.Headers.Add("Origin", WebOrigin);

        using var response = await client.SendAsync(request, TestContext.Current.CancellationToken);

        response.Headers.TryGetValues("Access-Control-Allow-Origin", out var values).ShouldBeTrue();
        values.ShouldBe([WebOrigin]);
    }

    [Fact]
    public async Task Other_origins_are_not_allowed()
    {
        using var client = ClientWithOrigins(WebOrigin);
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/health");
        request.Headers.Add("Origin", "https://elsewhere.example.test");

        using var response = await client.SendAsync(request, TestContext.Current.CancellationToken);

        response.Headers.Contains("Access-Control-Allow-Origin").ShouldBeFalse();
    }

    [Fact]
    public async Task Preflight_for_a_post_is_answered_for_the_configured_origin()
    {
        using var client = ClientWithOrigins(WebOrigin);
        using var request = new HttpRequestMessage(HttpMethod.Options, "/api/books");
        request.Headers.Add("Origin", WebOrigin);
        request.Headers.Add("Access-Control-Request-Method", "POST");
        request.Headers.Add("Access-Control-Request-Headers", "Content-Type");

        using var response = await client.SendAsync(request, TestContext.Current.CancellationToken);

        response.StatusCode.ShouldBe(System.Net.HttpStatusCode.NoContent);
        response.Headers.GetValues("Access-Control-Allow-Methods").ShouldContain(v => v.Contains("POST", StringComparison.Ordinal));
    }

    [Fact]
    public async Task No_origins_configured_allows_nothing()
    {
        using var client = ClientWithOrigins();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/health");
        request.Headers.Add("Origin", WebOrigin);

        using var response = await client.SendAsync(request, TestContext.Current.CancellationToken);

        response.Headers.Contains("Access-Control-Allow-Origin").ShouldBeFalse();
    }
}

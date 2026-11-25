using System.Net;
using Microsoft.Extensions.Configuration;
using Shouldly;

namespace TaleQuilt.Api.Tests;

/// <summary>
/// The headers the ZAP baseline in the Deploy workflow expects on every answer (Phase 3 build item 3b), and the
/// OpenAPI document that scan reads to know which routes to test.
/// </summary>
public sealed class SecurityHeadersTests(ApiFixture fixture) : IClassFixture<ApiFixture>
{
    [Theory]
    [InlineData("/api/health")]
    [InlineData("/api/books")]
    [InlineData("/openapi/v1.json")]
    public async Task Every_answer_carries_the_strict_headers(string path)
    {
        using var client = fixture.CreateClient();

        using var response = await client.GetAsync(new Uri(path, UriKind.Relative), TestContext.Current.CancellationToken);

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
        response.Headers.GetValues("X-Content-Type-Options").ShouldBe(["nosniff"]);
        response.Headers.GetValues("X-Frame-Options").ShouldBe(["DENY"]);
        response.Headers.GetValues("Content-Security-Policy").ShouldBe(["default-src 'none'; frame-ancestors 'none'"]);
        response.Headers.GetValues("Referrer-Policy").ShouldBe(["no-referrer"]);
        response.Headers.GetValues("Cross-Origin-Resource-Policy").ShouldBe(["same-origin"]);
        response.Headers.CacheControl.ShouldNotBeNull().NoStore.ShouldBeTrue();
        response.Headers.Contains("X-Powered-By").ShouldBeFalse();
    }

    [Fact]
    public async Task Strict_transport_security_is_sent_over_https_only()
    {
        using var secure = fixture.CreateClient(new() { BaseAddress = new Uri("https://localhost") });
        using var plain = fixture.CreateClient(new() { BaseAddress = new Uri("http://localhost") });

        using var secureResponse = await secure.GetAsync(new Uri("/api/books", UriKind.Relative), TestContext.Current.CancellationToken);
        using var plainResponse = await plain.GetAsync(new Uri("/api/books", UriKind.Relative), TestContext.Current.CancellationToken);

        secureResponse.Headers.GetValues("Strict-Transport-Security").ShouldBe([SecurityHeaders.StrictTransportSecurityValue]);
        plainResponse.Headers.Contains("Strict-Transport-Security").ShouldBeFalse();
    }

    [Fact]
    public async Task A_request_the_framework_cannot_read_is_the_callers_error_not_a_500()
    {
        // ZAP's rehearsal sent this content type and got a 500; a malformed request is a 4xx.
        using var client = fixture.CreateClient();
        using var content = new StringContent("{\"title\":\"x\"}");
        content.Headers.Remove("Content-Type");
        content.Headers.TryAddWithoutValidation("Content-Type", "application/json,multipart/form-data; boundary=x").ShouldBeTrue();

        using var response = await client.PostAsync(new Uri("/api/books", UriKind.Relative), content, TestContext.Current.CancellationToken);

        ((int)response.StatusCode).ShouldBeInRange(400, 499);
        response.Headers.GetValues("X-Content-Type-Options").ShouldBe(["nosniff"]);
    }

    [Theory]
    [InlineData("", "Yarnspun API")]
    [InlineData("Other Name", "Other Name API")]
    public async Task The_openapi_title_follows_the_configured_product_name_with_a_fallback(string configured, string expected)
    {
        // ADR 0022: the product name is configuration; a blank value falls back to the default.
        using var client = fixture.WithWebHostBuilder(builder => builder.ConfigureAppConfiguration((_, config) =>
            config.AddInMemoryCollection([new KeyValuePair<string, string?>("Product:Name", configured)]))).CreateClient();

        using var response = await client.GetAsync(new Uri("/openapi/v1.json", UriKind.Relative), TestContext.Current.CancellationToken);
        var body = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);

        body.ShouldContain($"\"title\": \"{expected}\"");
    }

    [Fact]
    public async Task The_openapi_document_describes_the_book_routes()
    {
        using var client = fixture.CreateClient();

        using var response = await client.GetAsync(new Uri("/openapi/v1.json", UriKind.Relative), TestContext.Current.CancellationToken);
        var body = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);

        response.StatusCode.ShouldBe(HttpStatusCode.OK);
        response.Content.Headers.ContentType.ShouldNotBeNull().MediaType.ShouldBe("application/json");
        body.ShouldContain("\"/api/books\"");
        body.ShouldContain("\"title\": \"Yarnspun API\"");
    }
}

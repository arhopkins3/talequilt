using Microsoft.AspNetCore.Cors.Infrastructure;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using TaleQuilt.Api;
using TaleQuilt.Api.Endpoints;
using TaleQuilt.Core.Data;

var builder = WebApplication.CreateBuilder(args);

// No Server header: it names the web server and its version to anyone who asks, and nothing needs it.
builder.WebHost.ConfigureKestrel(static options => options.AddServerHeader = false);

builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddDbContext<TaleQuiltDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("TaleQuilt")));
builder.Services.AddHealthChecks().AddDbContextCheck<TaleQuiltDbContext>("database");
// The public product name (ADR 0022) is configuration, read for the OpenAPI document's title here and for the
// PDF's metadata later; the project name, TaleQuilt, stays in code and resources. It is read when the document is
// built, not when the host is, so configuration added by a test host or an environment is honoured.
builder.Services.AddOpenApi(options => options.AddDocumentTransformer((document, context, _) =>
{
    var configured = context.ApplicationServices.GetRequiredService<IConfiguration>()["Product:Name"];
    document.Info.Title = $"{(string.IsNullOrWhiteSpace(configured) ? "Yarnspun" : configured)} API";
    return Task.CompletedTask;
}));
builder.Services.AddProblemDetails();

// In Azure the web app is served from Static Web Apps on another hostname (ADR 0021), so the browser's calls are
// cross-origin. Only the origins listed under Cors:AllowedOrigins are allowed; an empty list allows none. The
// list is read when the options are first resolved, after the host is built, so configuration added by a test
// host or an environment is honoured, as the connection string is.
builder.Services.AddCors();
builder.Services.AddOptions<CorsOptions>().Configure<IConfiguration>((options, configuration) =>
{
    var allowedOrigins = configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
    options.AddDefaultPolicy(policy =>
        policy.WithOrigins(allowedOrigins).WithMethods("GET", "POST").WithHeaders("Content-Type"));
});

var app = builder.Build();

if (app.Configuration.GetValue<bool>("Database:MigrateOnStartup"))
{
    // Development and test convenience only (ADR 0016). Deployed environments run migrations as a
    // release step in Phase 3, never from a starting replica.
    using var scope = app.Services.CreateScope();
    await scope.ServiceProvider.GetRequiredService<TaleQuiltDbContext>().Database.MigrateAsync().ConfigureAwait(false);
}

app.UseExceptionHandler(new ExceptionHandlerOptions
{
    // A request the framework could not read (a malformed body or content type) is the caller's fault and
    // carries its own status code, 400 or 415; only everything else is a 500. Found by the ZAP rehearsal.
    StatusCodeSelector = static exception =>
        exception is BadHttpRequestException bad ? bad.StatusCode : StatusCodes.Status500InternalServerError,
});
app.UseStatusCodePages();
app.UseSecurityHeaders();
app.UseCors();

// The OpenAPI document is served in every environment: the API sits behind an IP allow-list (ADR 0008), the
// document holds nothing secret, and the ZAP scan in the Deploy workflow reads it to learn the routes to test.
app.MapOpenApi();

// The health answer is JSON, like every other answer: the overall status and one entry per check.
app.MapHealthChecks("/api/health", new HealthCheckOptions
{
    ResponseWriter = static (context, report) =>
    {
        context.Response.ContentType = "application/json; charset=utf-8";
        return context.Response.WriteAsJsonAsync(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new { name = e.Key, status = e.Value.Status.ToString() }),
        });
    },
});
app.MapBookEndpoints();

await app.RunAsync().ConfigureAwait(false);

/// <summary>Marker so integration tests can reference the entry assembly.</summary>
public partial class Program;

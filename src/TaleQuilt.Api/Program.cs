using Microsoft.AspNetCore.Cors.Infrastructure;
using Microsoft.EntityFrameworkCore;
using TaleQuilt.Api.Endpoints;
using TaleQuilt.Core.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddDbContext<TaleQuiltDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("TaleQuilt")));
builder.Services.AddHealthChecks().AddDbContextCheck<TaleQuiltDbContext>("database");
builder.Services.AddOpenApi();
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

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors();
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapHealthChecks("/api/health");
app.MapBookEndpoints();

await app.RunAsync().ConfigureAwait(false);

/// <summary>Marker so integration tests can reference the entry assembly.</summary>
public partial class Program;

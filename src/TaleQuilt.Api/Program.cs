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

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapHealthChecks("/api/health");
app.MapBookEndpoints();

await app.RunAsync().ConfigureAwait(false);

/// <summary>Marker so integration tests can reference the entry assembly.</summary>
public partial class Program;

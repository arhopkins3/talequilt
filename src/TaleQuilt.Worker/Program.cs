using System.Diagnostics.CodeAnalysis;
using TaleQuilt.Worker;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.Configure<HeartbeatOptions>(builder.Configuration.GetSection("Heartbeat"));
builder.Services.AddHostedService<HeartbeatWorker>();

var host = builder.Build();
await host.RunAsync().ConfigureAwait(false);

/// <summary>Process entry point; excluded from coverage (ADR 0017), everything it wires up is tested directly.</summary>
[ExcludeFromCodeCoverage]
internal sealed partial class Program;

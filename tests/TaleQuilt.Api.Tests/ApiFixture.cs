using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using TaleQuilt.Core.Data;
using Testcontainers.MsSql;

namespace TaleQuilt.Api.Tests;

/// <summary>
/// One SQL Server per test run, hosting the API in-process. The server comes from Testcontainers unless
/// <c>TALEQUILT_TEST_CONNECTION</c> names an existing SQL Server (ADR 0016), in which case a fresh database is
/// created there and dropped afterwards.
/// </summary>
public sealed class ApiFixture : WebApplicationFactory<Program>, IAsyncLifetime
{
    private const string EnvConnection = "TALEQUILT_TEST_CONNECTION";
    private readonly string _databaseName = $"TaleQuiltTest_{Guid.NewGuid():N}";
    private MsSqlContainer? _container;
    private string? _serverConnection;

    public string ConnectionString { get; private set; } = string.Empty;

    public async ValueTask InitializeAsync()
    {
        _serverConnection = Environment.GetEnvironmentVariable(EnvConnection);
        if (string.IsNullOrWhiteSpace(_serverConnection))
        {
            _container = new MsSqlBuilder("mcr.microsoft.com/mssql/server:2025-latest").Build();
            await _container.StartAsync().ConfigureAwait(false);
            _serverConnection = _container.GetConnectionString();
        }

        ConnectionString = new Microsoft.Data.SqlClient.SqlConnectionStringBuilder(_serverConnection)
        {
            InitialCatalog = _databaseName,
        }.ConnectionString;

        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TaleQuiltDbContext>();
        await db.Database.EnsureCreatedAsync().ConfigureAwait(false);
    }

    public override async ValueTask DisposeAsync()
    {
        if (!string.IsNullOrEmpty(ConnectionString))
        {
            using var scope = Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<TaleQuiltDbContext>();
            await db.Database.EnsureDeletedAsync().ConfigureAwait(false);
        }

        if (_container is not null)
        {
            await _container.DisposeAsync().ConfigureAwait(false);
        }

        await base.DisposeAsync().ConfigureAwait(false);
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureAppConfiguration((_, config) =>
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:TaleQuilt"] = ConnectionString,
            }));
    }
}

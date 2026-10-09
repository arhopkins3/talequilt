using System.Diagnostics.CodeAnalysis;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace TaleQuilt.Core.Data;

/// <summary>
/// Used only by the <c>dotnet ef</c> tooling to create migrations. The connection string is never used to connect
/// at design time; it only tells the provider which dialect to generate.
/// </summary>
[ExcludeFromCodeCoverage]
public sealed class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<TaleQuiltDbContext>
{
    public TaleQuiltDbContext CreateDbContext(string[] args)
    {
        var options = new DbContextOptionsBuilder<TaleQuiltDbContext>()
            .UseSqlServer("Server=localhost;Database=TaleQuilt;Trusted_Connection=False;TrustServerCertificate=True")
            .Options;
        return new TaleQuiltDbContext(options);
    }
}

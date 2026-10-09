using Microsoft.EntityFrameworkCore;
using TaleQuilt.Core.Books;

namespace TaleQuilt.Core.Data;

public sealed class TaleQuiltDbContext(DbContextOptions<TaleQuiltDbContext> options) : DbContext(options)
{
    public DbSet<Book> Books => Set<Book>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ArgumentNullException.ThrowIfNull(modelBuilder);

        modelBuilder.Entity<Book>(book =>
        {
            book.ToTable("Books");
            book.HasKey(b => b.Id);
            book.Property(b => b.Title).HasMaxLength(Book.TitleMaxLength).IsRequired();
            book.Property(b => b.CreatedAt).IsRequired();
        });
    }
}

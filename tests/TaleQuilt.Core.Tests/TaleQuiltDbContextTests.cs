using Microsoft.EntityFrameworkCore;
using Shouldly;
using TaleQuilt.Core.Books;
using TaleQuilt.Core.Data;

namespace TaleQuilt.Core.Tests;

public sealed class TaleQuiltDbContextTests
{
    [Fact]
    public void Model_maps_books_with_a_bounded_required_title()
    {
        var options = new DbContextOptionsBuilder<TaleQuiltDbContext>()
            .UseSqlServer("Server=unused;Database=unused")
            .Options;
        using var db = new TaleQuiltDbContext(options);

        var entity = db.Model.FindEntityType(typeof(Book));

        entity.ShouldNotBeNull();
        entity.GetTableName().ShouldBe("Books");
        var title = entity.FindProperty(nameof(Book.Title));
        title.ShouldNotBeNull();
        title.GetMaxLength().ShouldBe(Book.TitleMaxLength);
        title.IsNullable.ShouldBeFalse();
        entity.FindPrimaryKey()!.Properties.Single().Name.ShouldBe(nameof(Book.Id));
    }
}

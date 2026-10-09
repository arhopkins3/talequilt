using Microsoft.Extensions.Time.Testing;
using Shouldly;
using TaleQuilt.Core.Books;

namespace TaleQuilt.Core.Tests;

public sealed class BookTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 9, 12, 0, 0, TimeSpan.Zero);
    private readonly FakeTimeProvider _clock = new(Now);

    [Fact]
    public void Create_trims_the_title_and_stamps_the_time()
    {
        var book = Book.Create("  The Lighthouse Keeper's Cat  ", _clock);

        book.Title.ShouldBe("The Lighthouse Keeper's Cat");
        book.CreatedAt.ShouldBe(Now);
        book.Id.ShouldNotBe(Guid.Empty);
    }

    [Fact]
    public void Create_gives_each_book_its_own_id()
    {
        var first = Book.Create("One", _clock);
        var second = Book.Create("Two", _clock);

        first.Id.ShouldNotBe(second.Id);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public void Create_rejects_an_empty_title(string? title)
    {
        var ex = Should.Throw<ArgumentException>(() => Book.Create(title!, _clock));

        ex.ParamName.ShouldBe("title");
        ex.Message.ShouldContain("needs a title");
    }

    [Fact]
    public void Create_rejects_a_title_longer_than_the_limit()
    {
        var tooLong = new string('x', Book.TitleMaxLength + 1);

        var ex = Should.Throw<ArgumentException>(() => Book.Create(tooLong, _clock));

        ex.Message.ShouldContain(Book.TitleMaxLength.ToString(System.Globalization.CultureInfo.InvariantCulture));
    }

    [Fact]
    public void Create_accepts_a_title_exactly_at_the_limit()
    {
        var book = Book.Create(new string('x', Book.TitleMaxLength), _clock);

        book.Title.Length.ShouldBe(Book.TitleMaxLength);
    }

    [Fact]
    public void Create_requires_a_clock()
    {
        Should.Throw<ArgumentNullException>(() => Book.Create("Title", null!));
    }
}

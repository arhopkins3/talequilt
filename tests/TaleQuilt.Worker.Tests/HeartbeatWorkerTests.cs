using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Time.Testing;
using Shouldly;

namespace TaleQuilt.Worker.Tests;

public sealed class HeartbeatWorkerTests
{
    private static HeartbeatWorker CreateWorker(FakeTimeProvider clock, TimeSpan interval) =>
        new(NullLogger<HeartbeatWorker>.Instance, Options.Create(new HeartbeatOptions { Interval = interval }), clock);

    [Fact]
    public async Task Beats_once_per_interval()
    {
        var clock = new FakeTimeProvider();
        using var worker = CreateWorker(clock, TimeSpan.FromSeconds(10));

        await worker.StartAsync(CancellationToken.None);
        clock.Advance(TimeSpan.FromSeconds(9));
        worker.Beats.ShouldBe(0);
        clock.Advance(TimeSpan.FromSeconds(1));
        worker.Beats.ShouldBe(1);
        clock.Advance(TimeSpan.FromSeconds(20));
        worker.Beats.ShouldBe(3);
    }

    [Fact]
    public async Task Stops_beating_after_StopAsync()
    {
        var clock = new FakeTimeProvider();
        using var worker = CreateWorker(clock, TimeSpan.FromSeconds(10));

        await worker.StartAsync(CancellationToken.None);
        clock.Advance(TimeSpan.FromSeconds(10));
        await worker.StopAsync(CancellationToken.None);
        clock.Advance(TimeSpan.FromMinutes(5));

        worker.Beats.ShouldBe(1);
    }

    [Fact]
    public void Default_interval_is_thirty_seconds()
    {
        new HeartbeatOptions().Interval.ShouldBe(TimeSpan.FromSeconds(30));
    }
}

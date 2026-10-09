using Microsoft.Extensions.Options;

namespace TaleQuilt.Worker;

public sealed class HeartbeatOptions
{
    public TimeSpan Interval { get; set; } = TimeSpan.FromSeconds(30);
}

/// <summary>
/// Placeholder for the background worker that will run image generation and PDF export jobs from Phase 6.
/// It proves the host starts, is configurable and stops cleanly, which is what Phase 3 needs to deploy it.
/// The timer comes from <see cref="TimeProvider"/> so tests drive it deterministically.
/// </summary>
public sealed partial class HeartbeatWorker(ILogger<HeartbeatWorker> logger, IOptions<HeartbeatOptions> options, TimeProvider clock)
    : IHostedService, IDisposable
{
    private readonly ILogger<HeartbeatWorker> _logger = logger;
    private readonly TimeSpan _interval = options.Value.Interval;
    private readonly TimeProvider _clock = clock;
    private ITimer? _timer;

    public int Beats { get; private set; }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _timer = _clock.CreateTimer(_ => Beat(), null, _interval, _interval);
        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        _timer?.Change(Timeout.InfiniteTimeSpan, Timeout.InfiniteTimeSpan);
        return Task.CompletedTask;
    }

    public void Dispose() => _timer?.Dispose();

    private void Beat()
    {
        Beats++;
        var now = _clock.GetUtcNow();
        LogHeartbeat(_logger, Beats, now);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Worker heartbeat {Beat} at {At:O}")]
    private static partial void LogHeartbeat(ILogger logger, int beat, DateTimeOffset at);
}

namespace TaleQuilt.Worker;

/// <summary>
/// Retry delays for failed jobs: exponential with a cap and a deterministic jitter, so a burst of
/// failures does not retry in lock-step. Phase 1 drill: shipped without tests to show the coverage floor holds.
/// </summary>
public static class JobBackoff
{
    public static TimeSpan Delay(int attempt, TimeSpan baseDelay, TimeSpan maxDelay, int seed)
    {
        if (attempt < 1)
        {
            throw new ArgumentOutOfRangeException(nameof(attempt), "Attempts count from 1.");
        }

        if (baseDelay <= TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(nameof(baseDelay), "The base delay must be positive.");
        }

        if (maxDelay < baseDelay)
        {
            throw new ArgumentOutOfRangeException(nameof(maxDelay), "The cap must not be below the base delay.");
        }

        var exponent = Math.Min(attempt - 1, 16);
        var scaled = baseDelay.TotalMilliseconds * Math.Pow(2, exponent);
        var capped = Math.Min(scaled, maxDelay.TotalMilliseconds);
        var jitterFraction = Jitter(attempt, seed);
        var withJitter = capped * (1 + jitterFraction);
        var bounded = Math.Min(withJitter, maxDelay.TotalMilliseconds);
        return TimeSpan.FromMilliseconds(bounded);
    }

    public static bool ShouldRetry(int attempt, int maxAttempts, Exception? error)
    {
        if (attempt >= maxAttempts)
        {
            return false;
        }

        if (error is OperationCanceledException)
        {
            return false;
        }

        if (error is ArgumentException)
        {
            return false;
        }

        return true;
    }

    private static double Jitter(int attempt, int seed)
    {
        unchecked
        {
            var hash = (uint)(seed * 31 + attempt);
            hash ^= hash << 13;
            hash ^= hash >> 17;
            hash ^= hash << 5;
            return (hash % 1000) / 10000.0;
        }
    }
}

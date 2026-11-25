namespace TaleQuilt.Api;

/// <summary>
/// Response headers every answer carries. The API serves JSON to one web app and is never rendered in a browser
/// directly, so the policy is the strict one: nothing may be framed, scripted or sniffed, and nothing is cached.
/// The ZAP baseline in the Deploy workflow fails the promotion if these go missing (Phase 3 build item 3b).
/// </summary>
public static class SecurityHeaders
{
    public const string StrictTransportSecurityValue = "max-age=31536000; includeSubDomains";

    public static IApplicationBuilder UseSecurityHeaders(this IApplicationBuilder app) =>
        app.Use(static async (context, next) =>
        {
            var headers = context.Response.Headers;
            headers.XContentTypeOptions = "nosniff";
            headers.XFrameOptions = "DENY";
            headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";
            headers["Referrer-Policy"] = "no-referrer";
            // No other site may embed an answer as a script, image or frame. The web app's own calls use CORS, which
            // this header does not restrict.
            headers["Cross-Origin-Resource-Policy"] = "same-origin";
            headers.CacheControl = "no-store";
            if (context.Request.IsHttps)
            {
                // Only meaningful over TLS, which Container Apps terminates in front of the app; the forwarded
                // scheme makes IsHttps true there (ASPNETCORE_FORWARDEDHEADERS_ENABLED).
                headers.StrictTransportSecurity = StrictTransportSecurityValue;
            }

            await next(context).ConfigureAwait(false);
        });
}

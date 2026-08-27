using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;

namespace YourImageShare
{
    /// <summary>
    /// Official .NET client for the YourImageShare upload API
    /// (https://yourimageshare.com/about/api). Mirrors the existing JS (npm), Python
    /// (PyPI), PHP (Packagist), and Go SDKs - same method names, same result shapes,
    /// same error type - just idiomatic .NET on top (async, throws instead of
    /// returning an error value).
    /// </summary>
    public sealed class YourImageShareClient
    {
        public const string DefaultBaseUrl = "https://yourimageshare.com/api";
        private const string SdkVersion = "1.0.0";

        private static readonly JsonSerializerOptions JsonOptions = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
        };

        private readonly string _apiKey;
        private readonly string _baseUrl;
        private readonly HttpClient _httpClient;

        /// <param name="apiKey">Required - get one from the API tab at https://yourimageshare.com/my-account.</param>
        /// <param name="baseUrl">Overrides the API base URL - mainly for testing against a different environment.</param>
        /// <param name="httpClient">Overrides the HttpClient used for requests, e.g. for a custom timeout or handler. Defaults to a client with a 30s timeout.</param>
        public YourImageShareClient(string apiKey, string baseUrl = DefaultBaseUrl, HttpClient? httpClient = null)
        {
            if (string.IsNullOrEmpty(apiKey))
            {
                throw new ArgumentException("yourimageshare: apiKey is required", nameof(apiKey));
            }

            _apiKey = apiKey;
            _baseUrl = baseUrl;
            _httpClient = httpClient ?? new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
        }

        /// <summary>Uploads a local file by path. Streams from disk - doesn't buffer the whole file in memory.</summary>
        public async Task<UploadResult> UploadAsync(string filePath, UploadOptions? options = null, CancellationToken ct = default)
        {
            using var stream = File.OpenRead(filePath);
            return await UploadAsync(stream, Path.GetFileName(filePath), options, ct).ConfigureAwait(false);
        }

        /// <summary>
        /// Uploads from any <see cref="Stream"/> (an open file, a network stream, an
        /// in-memory buffer) - useful when the data isn't already a file on disk.
        /// <paramref name="filename"/> should include a real extension so the server
        /// can infer the content type correctly.
        /// </summary>
        public async Task<UploadResult> UploadAsync(Stream stream, string filename, UploadOptions? options = null, CancellationToken ct = default)
        {
            using var content = new MultipartFormDataContent();
            content.Add(new StreamContent(stream), "uploads", filename);

            if (options?.ExpiresIn is int expiresIn && expiresIn > 0)
            {
                content.Add(new StringContent(expiresIn.ToString()), "expires_in");
            }

            using var request = new HttpRequestMessage(HttpMethod.Post, _baseUrl) { Content = content };
            SetCommonHeaders(request);

            var raw = await SendAsync(request, ct).ConfigureAwait(false);
            var body = JsonSerializer.Deserialize<UploadEnvelope>(raw, JsonOptions);
            return body?.Data ?? throw new YourImageShareException(0, "internal: empty response body");
        }

        /// <summary>Returns your uploads, newest first, 50 per page. page &lt; 2 fetches the first page.</summary>
        public async Task<ListResult> ListAsync(int page = 1, CancellationToken ct = default)
        {
            var url = _baseUrl;
            if (page > 1)
            {
                url += "?page=" + Uri.EscapeDataString(page.ToString());
            }

            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            SetCommonHeaders(request);

            var raw = await SendAsync(request, ct).ConfigureAwait(false);
            return JsonSerializer.Deserialize<ListResult>(raw, JsonOptions)
                ?? throw new YourImageShareException(0, "internal: empty response body");
        }

        /// <summary>Removes one of your uploads by id. Throws a <see cref="YourImageShareException"/> on a 404/401.</summary>
        public async Task DeleteAsync(string id, CancellationToken ct = default)
        {
            using var request = new HttpRequestMessage(HttpMethod.Delete, _baseUrl + "/" + Uri.EscapeDataString(id));
            SetCommonHeaders(request);
            await SendAsync(request, ct).ConfigureAwait(false);
        }

        private void SetCommonHeaders(HttpRequestMessage request)
        {
            request.Headers.Add("X-API-Key", _apiKey);
            request.Headers.UserAgent.Add(new ProductInfoHeaderValue("yourimageshare-dotnet", SdkVersion));
        }

        /// <summary>
        /// Sends the request, decodes the `{"type": "success"|"error", ...}` envelope,
        /// throws <see cref="YourImageShareException"/> for any non-2xx response or a
        /// `type == "error"` payload, and returns the raw JSON body on success so each
        /// caller can re-deserialize into the shape it actually needs.
        /// </summary>
        private async Task<string> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            HttpResponseMessage response;
            try
            {
                response = await _httpClient.SendAsync(request, ct).ConfigureAwait(false);
            }
            catch (HttpRequestException ex)
            {
                throw new YourImageShareException(0, $"request failed: {ex.Message}");
            }

            using (response)
            {
                var raw = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                var status = (int)response.StatusCode;

                ApiEnvelope envelope;
                try
                {
                    envelope = JsonSerializer.Deserialize<ApiEnvelope>(raw, JsonOptions) ?? new ApiEnvelope();
                }
                catch (JsonException)
                {
                    throw new YourImageShareException(status, $"unexpected non-JSON response (HTTP {status})");
                }

                if (!response.IsSuccessStatusCode || envelope.Type == "error")
                {
                    var message = string.IsNullOrEmpty(envelope.Errors) ? $"request failed (HTTP {status})" : envelope.Errors!;
                    throw new YourImageShareException(status, message);
                }

                return raw;
            }
        }

        private sealed class UploadEnvelope
        {
            [JsonPropertyName("data")]
            public UploadResult? Data { get; set; }
        }
    }
}

using System;

namespace YourImageShare
{
    /// <summary>
    /// Thrown for any non-2xx response or a `{"type":"error"}` payload - mirrors the
    /// JS/Python/PHP/Go SDKs' error type (same Status/Message shape), thrown instead of
    /// returned since exceptions are idiomatic .NET.
    /// </summary>
    public sealed class YourImageShareException : Exception
    {
        public int Status { get; }
        public string ApiMessage { get; }

        public YourImageShareException(int status, string message)
            : base($"yourimageshare: [{status}] {message}")
        {
            Status = status;
            ApiMessage = message;
        }
    }
}

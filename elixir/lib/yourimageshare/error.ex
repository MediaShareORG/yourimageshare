defmodule YourImageShare.APIError do
  @moduledoc """
  Raised/returned for any non-2xx response or a `{"type": "error"}` payload -
  mirrors the JS/Python/PHP/Go/Rust/Ruby SDKs' error type exactly (same
  status/message shape) so error-handling logic reads the same across every
  official SDK.

  Functions in `YourImageShare.Client` return `{:error, %APIError{}}` by
  default (idiomatic Elixir - the tagged-tuple convention is the direct
  equivalent of Go's `(result, error)` return). Each also has a bang (`!`)
  variant that raises this struct instead, for callers who prefer that
  style (see e.g. `File.read/1` vs `File.read!/1`).
  """

  defexception [:status, :message]

  @type t :: %__MODULE__{status: non_neg_integer(), message: String.t()}

  @impl true
  def message(%__MODULE__{status: status, message: message}) do
    "yourimageshare: [#{status}] #{message}"
  end
end

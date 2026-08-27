defmodule YourImageShare.Client do
  @moduledoc """
  Client for the YourImageShare upload API
  (https://yourimageshare.com/about/api). Mirrors the existing JS, Python,
  PHP, Go, Rust, and Ruby SDKs - same method names, same result shapes,
  same error type - just idiomatic Elixir on top (`{:ok, result} |
  {:error, %YourImageShare.APIError{}}` tagged tuples, the direct
  equivalent of Go's `(result, error)` return; bang variants that raise
  are also provided).

  Built on `Req` (https://hex.pm/packages/req) for HTTP + native
  streaming multipart support.
  """

  alias YourImageShare.{APIError, ListResult, UploadResult}

  @default_base_url "https://yourimageshare.com/api"
  @sdk_version "1.0.0"

  defstruct [:api_key, :base_url, :req_options]

  @type t :: %__MODULE__{
          api_key: String.t(),
          base_url: String.t(),
          req_options: keyword()
        }

  @doc """
  Builds a client. `api_key` is required - get one from the API tab at
  https://yourimageshare.com/my-account.

  Options:
    * `:base_url` - overrides the API base URL (mainly for testing).
    * `:req_options` - extra options merged into every `Req.new/1` call,
      e.g. `receive_timeout:` or a custom `:finch` pool.
  """
  @spec new(String.t(), keyword()) :: t()
  def new(api_key, opts \\ []) when is_binary(api_key) and api_key != "" do
    %__MODULE__{
      api_key: api_key,
      base_url: Keyword.get(opts, :base_url, @default_base_url),
      req_options: Keyword.get(opts, :req_options, [])
    }
  end

  @doc """
  Uploads a local file by path. Streams from disk via `File.stream!/1` -
  doesn't buffer the whole file in memory. `opts[:expires_in]` auto-deletes
  the upload after that many seconds (60 to 2,592,000 = 30 days).
  """
  @spec upload(t(), Path.t(), keyword()) :: {:ok, UploadResult.t()} | {:error, APIError.t()}
  def upload(%__MODULE__{} = client, file_path, opts \\ []) do
    upload_stream(client, File.stream!(file_path), Path.basename(file_path), opts)
  end

  @doc "Same as `upload/3`, but raises `YourImageShare.APIError` instead of returning `{:error, _}`."
  @spec upload!(t(), Path.t(), keyword()) :: UploadResult.t()
  def upload!(%__MODULE__{} = client, file_path, opts \\ []) do
    bang!(upload(client, file_path, opts))
  end

  @doc """
  Uploads from any `Enumerable`/`File.Stream` (an open file, a network
  stream, an in-memory list of binaries) - useful when the data isn't
  already a file on disk. `filename` should include a real extension so
  the server can infer the content type correctly.
  """
  @spec upload_stream(t(), Enumerable.t(), String.t(), keyword()) ::
          {:ok, UploadResult.t()} | {:error, APIError.t()}
  def upload_stream(%__MODULE__{} = client, stream, filename, opts \\ []) do
    expires_in = Keyword.get(opts, :expires_in)

    fields =
      [uploads: {stream, filename: filename}] ++
        if(is_integer(expires_in) and expires_in > 0,
          do: [expires_in: Integer.to_string(expires_in)],
          else: []
        )

    client
    |> request(:post, client.base_url, form_multipart: fields)
    |> decode(fn %{"data" => data} -> UploadResult.from_map(data) end)
  end

  @doc "Same as `upload_stream/4`, but raises instead of returning `{:error, _}`."
  @spec upload_stream!(t(), Enumerable.t(), String.t(), keyword()) :: UploadResult.t()
  def upload_stream!(%__MODULE__{} = client, stream, filename, opts \\ []) do
    bang!(upload_stream(client, stream, filename, opts))
  end

  @doc "Returns your uploads, newest first, 50 per page. `opts[:page]` < 2 fetches the first page."
  @spec list(t(), keyword()) :: {:ok, ListResult.t()} | {:error, APIError.t()}
  def list(%__MODULE__{} = client, opts \\ []) do
    page = Keyword.get(opts, :page)
    params = if is_integer(page) and page > 1, do: [page: page], else: []

    client
    |> request(:get, client.base_url, params: params)
    |> decode(&ListResult.from_map/1)
  end

  @doc "Same as `list/2`, but raises instead of returning `{:error, _}`."
  @spec list!(t(), keyword()) :: ListResult.t()
  def list!(%__MODULE__{} = client, opts \\ []) do
    bang!(list(client, opts))
  end

  @doc "Removes one of your uploads by id. Returns `{:error, %APIError{}}` on a 404/401."
  @spec delete(t(), String.t()) :: :ok | {:error, APIError.t()}
  def delete(%__MODULE__{} = client, id) do
    client
    |> request(:delete, client.base_url <> "/" <> URI.encode_www_form(id))
    |> decode(fn _ -> :ok end)
  end

  @doc "Same as `delete/2`, but raises instead of returning `{:error, _}`."
  @spec delete!(t(), String.t()) :: :ok
  def delete!(%__MODULE__{} = client, id) do
    bang!(delete(client, id))
  end

  defp request(%__MODULE__{} = client, method, url, extra \\ []) do
    req_opts =
      [
        method: method,
        url: url,
        headers: [
          {"x-api-key", client.api_key},
          {"user-agent", "yourimageshare-elixir/#{@sdk_version}"}
        ]
      ]
      |> Kernel.++(extra)
      |> Kernel.++(client.req_options)

    case Req.request(req_opts) do
      {:ok, %Req.Response{} = resp} ->
        {:ok, resp}

      {:error, exception} ->
        {:error, %APIError{status: 0, message: "request failed: #{Exception.message(exception)}"}}
    end
  end

  defp decode({:error, %APIError{}} = error, _on_success), do: error

  defp decode({:ok, %Req.Response{status: status, body: body}}, on_success) do
    envelope = if is_map(body), do: body, else: %{}

    cond do
      not is_map(body) ->
        {:error,
         %APIError{status: status, message: "unexpected non-JSON response (HTTP #{status})"}}

      status not in 200..299 or envelope["type"] == "error" ->
        message = envelope["errors"] || "request failed (HTTP #{status})"
        {:error, %APIError{status: status, message: message}}

      true ->
        {:ok, on_success.(envelope)}
    end
  end

  defp bang!({:ok, result}), do: result
  defp bang!({:error, %APIError{} = error}), do: raise(error)
end

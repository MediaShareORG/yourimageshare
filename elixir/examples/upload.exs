Mix.install([{:yourimageshare, "~> 1.0"}])

client = YourImageShare.Client.new(System.fetch_env!("YOURIMAGESHARE_API_KEY"))

case YourImageShare.Client.upload(client, "photo.jpg") do
  {:ok, result} ->
    IO.puts(result.direct)

  {:error, %YourImageShare.APIError{status: status, message: message}} ->
    IO.puts(:stderr, "#{status}: #{message}")
    System.halt(1)
end

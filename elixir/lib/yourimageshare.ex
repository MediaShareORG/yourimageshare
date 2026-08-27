defmodule YourImageShare do
  @moduledoc """
  Official Elixir client for the [YourImageShare](https://yourimageshare.com)
  upload API. See `YourImageShare.Client` for the full API - this module is
  just an entry point.

      client = YourImageShare.Client.new("YOUR_API_KEY")
      {:ok, result} = YourImageShare.Client.upload(client, "photo.jpg")
      result.direct
      #=> "https://yourimageshare.com/ib/aB3xY9qRz1"

  Full HTTP reference: https://yourimageshare.com/about/api
  """
end

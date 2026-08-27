require "yourimageshare"

client = YourImageShare::Client.new("YOUR_API_KEY")

begin
  result = client.upload("photo.jpg")
  puts result.direct # https://yourimageshare.com/ib/aB3xY9qRz1
rescue YourImageShare::APIError => e
  warn "#{e.status}: #{e.message}"
  exit 1
end

require "net/http"
require "uri"
require "json"

module YourImageShare
  DEFAULT_BASE_URL = "https://yourimageshare.com/api"

  # Talks to the YourImageShare upload API. Create one with
  # YourImageShare::Client.new(api_key). Get a key from the API tab at
  # https://yourimageshare.com/my-account.
  class Client
    def initialize(api_key, base_url: DEFAULT_BASE_URL, timeout: 30)
      raise ArgumentError, "api_key is required" if api_key.nil? || api_key.empty?

      @api_key = api_key
      @base_url = base_url
      @timeout = timeout
    end

    # Uploads a local file by path. expires_in (seconds, 60 to 2,592,000 =
    # 30 days) auto-deletes the upload later; nil means a permanent upload.
    def upload(file_path, expires_in: nil)
      File.open(file_path, "rb") do |f|
        upload_io(f, File.basename(file_path), expires_in: expires_in)
      end
    end

    # Uploads from any IO-like object (must respond to #read). filename
    # should include a real extension so the server can infer content type.
    def upload_io(io, filename, expires_in: nil)
      uri = URI(@base_url)
      request = Net::HTTP::Post.new(uri)
      set_common_headers(request)

      form = [["uploads", io, { filename: filename }]]
      form << ["expires_in", expires_in.to_s] if expires_in && expires_in > 0
      # Net::HTTP streams IO form values in chunks rather than buffering
      # the whole file into memory - important since uploads can be up to
      # 200MB (video).
      request.set_form(form, "multipart/form-data")

      body = execute(uri, request)
      UploadResult.from_json(body["data"] || {})
    end

    # Returns your uploads, newest first, 50 per page. page < 2 fetches the
    # first page.
    def list(page = nil)
      uri = URI(@base_url)
      uri.query = URI.encode_www_form(page: page) if page && page > 1

      request = Net::HTTP::Get.new(uri)
      set_common_headers(request)

      ListResult.from_json(execute(uri, request))
    end

    # Removes one of your uploads by id. Raises APIError on failure.
    def delete(id)
      uri = URI("#{@base_url}/#{URI.encode_www_form_component(id)}")
      request = Net::HTTP::Delete.new(uri)
      set_common_headers(request)

      execute(uri, request)
      nil
    end

    private

    def set_common_headers(request)
      request["X-API-Key"] = @api_key
      request["User-Agent"] = "yourimageshare-ruby/#{VERSION}"
    end

    def execute(uri, request)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                  open_timeout: @timeout, read_timeout: @timeout) do |http|
        http.request(request)
      end

      envelope = begin
        JSON.parse(response.body.to_s)
      rescue JSON::ParserError
        raise APIError.new(response.code.to_i, "unexpected non-JSON response (HTTP #{response.code})")
      end

      status = response.code.to_i
      if status < 200 || status >= 300 || envelope["type"] == "error"
        message = envelope["errors"]
        message = "request failed (HTTP #{status})" if message.nil? || message.empty?
        raise APIError.new(status, message)
      end

      envelope
    end
  end
end

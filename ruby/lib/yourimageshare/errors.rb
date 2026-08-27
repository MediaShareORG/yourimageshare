module YourImageShare
  # Raised for any non-2xx response or a `{"type":"error"}` payload -
  # mirrors the Go/JS/Python/PHP SDKs' error shape (status + message) so
  # error-handling logic reads the same across every official SDK. Ruby
  # convention is to raise, not to return an error object like Go does.
  class APIError < StandardError
    attr_reader :status, :message

    def initialize(status, message)
      @status = status
      @message = message
      super("yourimageshare: [#{status}] #{message}")
    end
  end
end

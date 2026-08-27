require_relative "yourimageshare/version"
require_relative "yourimageshare/errors"
require_relative "yourimageshare/types"
require_relative "yourimageshare/client"

# The official Ruby client for the YourImageShare upload API
# (https://yourimageshare.com/about/api). It mirrors the existing Go, JS
# (npm), and Python (PyPI) SDKs - same method names, same result shapes,
# same error semantics - just idiomatic Ruby on top (raises APIError
# instead of Go's (result, error) return style).
#
# Zero gem dependencies - only the Ruby standard library.
module YourImageShare
end

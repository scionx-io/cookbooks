# frozen_string_literal: true

module Tron
  module Abi
    # Base error class for ABI-related errors
    class Error < StandardError; end
    
    # Error raised when there's an issue with encoding
    class EncodingError < Error; end
    
    # Error raised when there's an issue with decoding  
    class DecodingError < Error; end
    
    # Error raised when a value is out of bounds for its type
    class ValueOutOfBounds < Error; end
    
    # Require all components of the ABI module
    require_relative 'abi/type'
    require_relative 'abi/encoder'
    require_relative 'abi/decoder'
    require_relative 'abi/util'
    require_relative 'abi/constant'
  end
end
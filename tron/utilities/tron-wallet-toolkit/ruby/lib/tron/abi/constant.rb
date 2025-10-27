# frozen_string_literal: true

module Tron
  module Abi
    # Provides constants for ABI encoding/decoding
    module Constant
      extend self

      # Byte zero constant
      # @return [String] binary string containing zero byte
      BYTE_ZERO = "\x00".b

      # Byte one constant
      # @return [String] binary string containing one byte
      BYTE_ONE = "\x01".b
    end
  end
end
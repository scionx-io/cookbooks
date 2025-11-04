# frozen_string_literal: true

module Tron
  module Abi
    # Provides constants for ABI encoding/decoding
    module Constant
      extend self

      # Maximum value for uint256 (2^256 - 1)
      # @return [Integer] maximum value for uint256
      UINT_MAX = 2**256 - 1

      # Minimum value for uint256
      # @return [Integer] minimum value for uint256
      UINT_MIN = 0

      # Maximum value for int256 (2^255 - 1)
      # @return [Integer] maximum value for int256
      INT_MAX = 2**255 - 1

      # Minimum value for int256 (-(2^255))
      # @return [Integer] minimum value for int256
      INT_MIN = -(2**255)

      # Byte zero constant
      # @return [String] binary string containing zero byte
      BYTE_ZERO = "\x00".b

      # Byte one constant
      # @return [String] binary string containing one byte
      BYTE_ONE = "\x01".b
    end
  end
end
require 'digest'

module Tron
  module Utils
    # Utility class for handling TRON contract ABIs
    class ABI
      # Type mappings for Solidity to Ruby
      SOLIDITY_TYPES = {
        'address' => :address,
        'uint256' => :uint256,
        'uint' => :uint256,
        'bool' => :bool,
        'bytes16' => :bytes16,
        'bytes32' => :bytes32,
        'string' => :string
      }.freeze

      # Parse function signature
      # Example: "registerOperator()" or "splitPayment(address,address,uint256,address,uint256,bytes16)"
      def self.parse_signature(signature)
        match = signature.match(/^(\w+)\((.*)\)$/)
        raise ArgumentError, "Invalid function signature: #{signature}" unless match

        {
          name: match[1],
          params: match[2].empty? ? [] : match[2].split(',').map(&:strip)
        }
      end

      # Encode function call
      def self.encode_function_call(signature, parameters = [])
        parsed = parse_signature(signature)

        # Get function selector (first 4 bytes of keccak256 hash)
        selector = function_selector(signature)

        # Encode parameters
        encoded_params = encode_parameters(parsed[:params], parameters)

        selector + encoded_params
      end

      # Function selector (4-byte hash)
      def self.function_selector(signature)
        require 'digest'
        # Note: TRON uses same ABI as Ethereum
        # Using SHA3-256 (Keccak256) for hash
        hash = Digest::SHA3.digest(signature, 256)
        # Take only the first 4 bytes (8 hex chars)
        hash.unpack1('H*')[0..7]
      end

      # Encode parameters
      def self.encode_parameters(types, values)
        raise ArgumentError, "Types and values length mismatch" if types.length != values.length

        encoded_parts = []
        dynamic_params = []
        dynamic_offset = types.length * 32 # Each static param takes 32 bytes (64 hex chars)
        
        types.each_with_index do |type, index|
          value = values[index]
          
          case type
          when 'address'
            # Address is padded to 32 bytes (64 hex chars)
            padded_address = encode_address(value)
            encoded_parts << padded_address
          when 'uint256', 'uint'
            # Convert to hex and pad to 32 bytes (64 hex chars)
            hex_value = encode_uint256(value)
            encoded_parts << hex_value
          when 'bool'
            # Boolean to uint256 (1 for true, 0 for false)
            encoded_parts << encode_bool(value)
          when /^bytes(\d+)$/
            # Static, fixed-size bytes array, pad to 32 bytes
            encoded_parts << encode_bytes($1.to_i, value)
          when 'string', 'bytes'
            # For dynamic types, add offset and store actual data separately
            encoded_parts << dynamic_offset.to_s(16).rjust(64, '0') # offset
            # Calculate the actual data for later encoding
            dynamic_data = encode_dynamic_parameter(type, value)
            dynamic_params << dynamic_data
            dynamic_offset += (dynamic_data.length / 2.0).ceil # Increase offset by byte length, rounded up to nearest whole byte
          else
            raise ArgumentError, "Unsupported ABI type: #{type}"
          end
        end
        
        # Encode dynamic parameters
        dynamic_parts = []
        dynamic_params.each do |data|
          dynamic_parts << data
        end
        
        (encoded_parts + dynamic_parts).join
      end

      # Encode a single value
      def self.encode_value(type, value)
        case type
        when 'address'
          encode_address(value)
        when 'uint256', 'uint'
          encode_uint256(value)
        when 'bool'
          encode_bool(value)
        when /^bytes(\d+)$/
          encode_bytes($1.to_i, value)
        when 'string'
          encode_string(value)
        else
          raise ArgumentError, "Unsupported type: #{type}"
        end
      end

      # Encode TRON address (T address to hex)
      def self.encode_address(address)
        # Convert TRON T-address to hex address
        # Remove 'T' prefix, convert base58 to hex, pad to 32 bytes
        hex = Address.to_hex(address)
        hex.rjust(64, '0') # Pad to 64 hex chars (32 bytes)
      end

      # Encode uint256
      def self.encode_uint256(value)
        value.to_i.to_s(16).rjust(64, '0')
      end

      # Encode bool
      def self.encode_bool(value)
        value ? '1'.rjust(64, '0') : '0'.rjust(64, '0')
      end

      # Encode bytes
      def self.encode_bytes(size, value)
        hex = value.is_a?(String) ? value.unpack1('H*') : value.to_s
        # Limit to the size of the bytes type and pad to 32 bytes
        hex_part = hex[0...(size * 2)] # Each byte is 2 hex chars
        hex_part.ljust(64, '0')
      end

      # Encode string
      def self.encode_string(value)
        # For dynamic types like string, return the length and data separately
        # This will be handled by the main encode_parameters method
        raise NotImplementedError, "String encoding is handled via encode_dynamic_parameter"
      end

      # Encode bytes (dynamic type)
      def self.encode_bytes_dynamic(value)
        # For dynamic bytes, encode length and data
        bytes_data = value.is_a?(String) ? value : value.to_s
        bytes_array = bytes_data.start_with?('0x') ? bytes_data[2..-1].scan(/../) : bytes_data.scan(/../)
        length = bytes_array.length.to_s(16).rjust(64, '0')
        data = bytes_array.map { |b| b.rjust(2, '0') }.join
        # Pad data to 32-byte boundaries (64 hex chars)
        padded_length = ((data.length / 64.0).ceil * 64).to_i
        padded_data = data.ljust(padded_length, '0')
        
        length + padded_data
      end

      # Decode output
      def self.decode_output(type, hex_data)
        case type
        when 'bool'
          hex_data.to_i(16) != 0
        when 'address'
          Address.from_hex(hex_data)
        when 'uint256', 'uint'
          hex_data.to_i(16)
        else
          hex_data
        end
      end

      # Decodes parameters based on ABI types
      def self.decode_parameters(types, data)
        # Remove '0x' prefix if present
        raw_data = data.start_with?('0x') ? data[2..-1] : data

        # Ensure the data length is valid
        if raw_data.length % 64 != 0
          raise ArgumentError, "Invalid data length: must be multiple of 64 hex chars"
        end

        values = []
        pos = 0

        types.each do |type|
          # Each parameter is 32 bytes (64 hex chars)
          param_hex = raw_data[pos...(pos + 64)]
          pos += 64

          case type
          when /address/
            # Extract the address (last 40 hex chars)
            addr_hex = param_hex[-40..-1]
            # Add TRON prefix
            values << "41#{addr_hex}"
          when /uint/, /int/
            # Convert hex to integer
            values << param_hex.to_i(16)
          when /bool/
            # Boolean is 0 or 1
            values << (param_hex.to_i(16) != 0)
          when /string|bytes/
            # Dynamic type - get offset first
            offset = param_hex.to_i(16) * 2 # Convert to byte position in hex string

            # Extract length of data
            length_hex = raw_data[offset...(offset + 64)]
            length = length_hex.to_i(16) * 2 # Each byte is 2 hex chars

            # Extract actual data
            actual_data = raw_data[(offset + 64)...(offset + 64 + length)]

            if type.start_with?('string')
              # Convert hex to string
              values << [actual_data].pack('H*')
            else
              # Return hex string for bytes
              values << actual_data
            end
          else
            raise ArgumentError, "Unsupported ABI type for decoding: #{type}"
          end
        end

        values
      end

      private

      # Helper method to encode dynamic parameters
      def self.encode_dynamic_parameter(type, value)
        if type.start_with?('string')
          # For strings, we need to encode length and data
          str_bytes = value.bytes
          length = str_bytes.length.to_s(16).rjust(64, '0')
          data = str_bytes.map { |b| b.to_s(16).rjust(2, '0') }.join
          # Pad data to 32-byte boundaries (64 hex chars)
          padded_length = ((data.length / 64.0).ceil * 64).to_i
          padded_data = data.ljust(padded_length, '0')

          length + padded_data
        elsif type.start_with?('bytes')
          # For bytes, similar to string
          bytes_data = value.is_a?(String) ? value : value.to_s
          bytes_array = bytes_data.start_with?('0x') ? bytes_data[2..-1].scan(/../) : bytes_data.scan(/../)
          length = bytes_array.length.to_s(16).rjust(64, '0')
          data = bytes_array.map { |b| b.rjust(2, '0') }.join
          # Pad data to 32-byte boundaries (64 hex chars)
          padded_length = ((data.length / 64.0).ceil * 64).to_i
          padded_data = data.ljust(padded_length, '0')

          length + padded_data
        else
          raise ArgumentError, "Unsupported dynamic type: #{type}"
        end
      end
    end
  end
end
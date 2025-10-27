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
    require_relative 'abi/function'
    require_relative 'abi/event'
    require_relative 'abi/util'
    require_relative 'abi/constant'
    
    # For address handling functionality
    require_relative 'utils/address'
    require_relative 'key'
    
    # Convenience method for encoding
    def self.encode(types, values)
      # Parse the types
      parsed_types = types.map { |t| Type.parse(t) }

      # Split into static and dynamic parts
      static_parts = []
      dynamic_parts = []
      dynamic_offsets = []
      offset_index = 0

      parsed_types.each_with_index do |type, i|
        if type.dynamic?
          # For dynamic types, store a placeholder offset and the actual data
          static_parts << nil  # Placeholder for offset
          dynamic_parts << Encoder.type(type, values[i])
          dynamic_offsets[offset_index] = dynamic_parts.length - 1
          offset_index += 1
        else
          # For static types, encode directly
          static_parts << Encoder.type(type, values[i])
        end
      end

      # Calculate actual offsets for dynamic parts
      # The offset is the position in the encoded result where the dynamic data begins
      # This is after all static parts (each parameter takes 32 bytes)
      static_size = parsed_types.count * 32  # Size of all parameter slots
      dynamic_offset = static_size  # Start of dynamic data

      # Replace the nil placeholders with actual offsets
      placeholders_replaced = 0
      static_parts.map! do |part|
        if part.nil?
          offset_value = dynamic_offset
          # Update offset for next dynamic part
          dynamic_part_idx = dynamic_offsets[placeholders_replaced]
          dynamic_offset += dynamic_parts[dynamic_part_idx].bytesize  # Use bytesize for binary
          placeholders_replaced += 1
          Encoder.type(Type.parse('uint256'), offset_value)
        else
          part
        end
      end

      # Combine static and dynamic parts and convert to hex at the boundary
      result_binary = static_parts.join + dynamic_parts.join
      Util.bin_to_hex(result_binary)
    end

    # Convenience method for decoding
    def self.decode(types, hex_data)
      # Convert hex to binary at the boundary
      data = Util.hex_to_bin(hex_data)
      parsed_types = types.map { |t| Type.parse(t) }

      # Decode each parameter, tracking the static section position as we go
      results = []
      static_offset = 0  # Position in the static section for both offset pointers and static values
      
      parsed_types.each do |type|
        if type.dynamic?
          # Check if we have enough data in static section for this offset
          raise DecodingError, "Insufficient data for dynamic type offset" if data.bytesize < static_offset + 32
          # Get offset from static section for this dynamic parameter
          offset_value = Util.deserialize_big_endian_to_int(data[static_offset, 32])
          
          # Check if we have enough data at the dynamic offset location
          raise DecodingError, "Insufficient data for dynamic type at offset #{offset_value}" if data.bytesize < offset_value + 32
          
          # Determine the size of data for this dynamic parameter
          # First, read the length from the dynamic data location
          data_length = Util.deserialize_big_endian_to_int(data[offset_value, 32])
          
          # Calculate total data size based on type
          if %w(string bytes).include?(type.base_type) and type.sub_type.empty? and type.dimensions.empty?
            # String or bytes: 32-byte length + padded content
            total_size = 32 + Util.ceil32(data_length)
          elsif !type.dimensions.empty?  # Array type
            # Dynamic array: 32-byte length + element encodings
            nested_type = type.nested_sub
            if nested_type.dynamic?
              # Complex case for arrays with dynamic elements - use full remaining data
              param_data = data[offset_value..-1]
              decoded_value = Decoder.type(type, param_data)
              results << decoded_value
              static_offset += 32  # Advance past the offset pointer
              next
            else
              # Array with static elements: 32-byte length + (element_size * count)
              total_size = 32 + (nested_type.size || 32) * data_length
            end
          else
            # Default for other dynamic types: 32-byte length + padded content
            total_size = 32 + Util.ceil32(data_length)
          end
          
          # Verify we have enough data
          raise DecodingError, "Insufficient data for dynamic type content" if data.bytesize < offset_value + total_size
          
          # Extract the parameter's data and decode
          param_data = data[offset_value, total_size]
          decoded_value = Decoder.type(type, param_data)
          results << decoded_value
          static_offset += 32  # Advance past the offset pointer
        else
          # For static types, decode directly from current static position
          size = type.size  # Size in bytes
          if size
            # Check bounds before reading static data
            raise DecodingError, "Insufficient data for static type" if data.bytesize < static_offset + size
            decoded_value = Decoder.type(type, data[static_offset, size])
            results << decoded_value
            static_offset += size  # Advance to next position
          else
            raise DecodingError, "Cannot decode static type without size"
          end
        end
      end

      results
    end
  end
end
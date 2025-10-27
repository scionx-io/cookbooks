# frozen_string_literal: true

require 'digest/keccak'
require_relative 'type'
require_relative 'encoder'
require_relative 'decoder'
require_relative 'util'

module Tron
  module Abi
    # Represents a Solidity function for ABI encoding/decoding
    class Function
      attr_reader :name, :inputs, :outputs, :signature, :method_id

      # Create a new Function instance
      #
      # @param name [String] the function name
      # @param inputs [Array<Hash>] the input parameters
      # @param outputs [Array<Hash>] the output parameters
      # @param constant [Boolean] whether the function is constant (view/pure)
      # @param payable [Boolean] whether the function is payable
      def initialize(name:, inputs: [], outputs: [], constant: false, payable: false)
        @name = name
        @inputs = inputs
        @outputs = outputs
        @constant = constant
        @payable = payable
        @signature = generate_signature
        @method_id = generate_method_id
      end

      # Generate the function signature
      #
      # @return [String] the function signature
      def generate_signature
        param_types = @inputs.map { |input| input[:type] }.join(',')
        "#{@name}(#{param_types})"
      end

      # Generate the method ID (first 4 bytes of Keccak256 hash of signature)
      #
      # @return [String] the method ID as hex string
      def generate_method_id
        # Using Keccak256 hash from the gem
        hash = Digest::Keccak.new(256).digest(@signature)
        # Take only first 4 bytes (8 hex chars)
        hash[0, 4].unpack1('H*')
      end

      # Encode a function call with given parameters
      #
      # @param parameters [Array] the parameter values to encode
      # @return [String] encoded function call data
      def encode_input(parameters)
        # Verify parameter count matches input count
        raise ArgumentError, "Expected #{@inputs.length} parameters, got #{parameters.length}" unless parameters.length == @inputs.length

        # Encode each parameter according to its type
        encoded_params = []
        parameters.each_with_index do |param, idx|
          input_type = @inputs[idx][:type]
          type = Type.parse(input_type)
          encoded_params << Encoder.type(type, param)
        end

        # Combine method ID and encoded parameters
        @method_id + encoded_params.join
      end

      # Decode function output from returned data
      #
      # @param data [String] the returned data from the function call
      # @return [Array] decoded output values
      def decode_output(data)
        # Remove the '0x' prefix if present
        raw_data = data.start_with?('0x') ? data[2..-1] : data

        # Decode each output parameter
        results = []
        offset = 0

        @outputs.each do |output|
          type = Type.parse(output[:type])
          if type.dynamic?
            # For dynamic types, read the offset first
            offset_ptr = raw_data[offset, 64]  # 32 bytes = 64 hex chars
            # Convert hex to binary before deserializing
            actual_offset = Util.deserialize_big_endian_to_int(Util.hex_to_bin(offset_ptr))

            # Decode using the actual offset
            # Convert hex to binary before decoding
            decoded_value = Decoder.type(type, Util.hex_to_bin(raw_data[actual_offset * 2..-1]))
            results << decoded_value
            offset += 64  # Move by 64 hex chars for the offset pointer
          else
            # For static types, decode directly from current offset
            size = type.size * 2  # size in bytes converted to hex chars
            # Convert hex to binary before decoding
            decoded_value = Decoder.type(type, Util.hex_to_bin(raw_data[offset, size]))
            results << decoded_value
            offset += size
          end
        end

        results
      end

      # Create a Function instance from an ABI definition
      #
      # @param abi_def [Hash] the ABI definition
      # @return [Function] a new Function instance
      def self.from_abi(abi_def)
        raise ArgumentError, "Not a function definition" unless abi_def[:type] == 'function' || abi_def['type'] == 'function'

        new(
          name: abi_def[:name] || abi_def['name'],
          inputs: abi_def[:inputs] || abi_def['inputs'] || [],
          outputs: abi_def[:outputs] || abi_def['outputs'] || [],
          constant: abi_def[:constant] || abi_def['constant'] || false,
          payable: abi_def[:payable] || abi_def['payable'] || false
        )
      end

      # Generate function signature from signature string
      #
      # @param sig [String] function signature (e.g. "transfer(address,uint256)")
      # @return [String] the method ID
      def self.signature(sig)
        hash = Digest::Keccak.new(256).digest(sig)
        hash[0, 4].unpack1('H*')
      end
    end
  end
end
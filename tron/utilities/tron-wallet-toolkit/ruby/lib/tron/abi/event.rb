# frozen_string_literal: true

require 'digest/keccak'
require_relative 'type'
require_relative 'encoder'
require_relative 'decoder'
require_relative 'util'

module Tron
  module Abi
    # Represents a Solidity event for ABI encoding/decoding
    class Event
      attr_reader :name, :inputs, :anonymous, :signature, :topic_hash

      # Create a new Event instance
      #
      # @param name [String] the event name
      # @param inputs [Array<Hash>] the input parameters
      # @param anonymous [Boolean] whether the event is anonymous
      def initialize(name:, inputs: [], anonymous: false)
        @name = name
        @inputs = inputs
        @anonymous = anonymous
        @signature = generate_signature
        @topic_hash = generate_topic_hash
      end

      # Generate the event signature
      #
      # @return [String] the event signature
      def generate_signature
        param_types = @inputs.map { |input| input[:type] }.join(',')
        "#{@name}(#{param_types})"
      end

      # Generate the topic hash (Keccak256 hash of signature)
      #
      # @return [String] the topic hash as hex string
      def generate_topic_hash
        # Using Keccak256 hash from the gem
        hash = Digest::Keccak.new(256).digest(@signature)
        hash.unpack1('H*')
      end

      # Decode event log data from transaction receipt
      #
      # @param topics [Array<String>] the topics from the event log
      # @param data [String] the data from the event log
      # @return [Hash] decoded event parameters
      def decode_log(topics, data)
        # Create a result hash with the event name
        result = { name: @name, params: [] }

        # Remove '0x' prefix if present
        raw_data = data.start_with?('0x') ? data[2..-1] : data
        raw_topics = topics.map { |t| t.start_with?('0x') ? t[2..-1] : t }

        # Process topics and inputs
        topic_idx = @anonymous ? 0 : 1  # Skip the first topic if not anonymous
        data_offset = 0

        @inputs.each_with_index do |input, i|
          type = Type.parse(input[:type])

          if input[:indexed]  # This parameter was included in the topics
            if topic_idx < raw_topics.length
              # Decode the topic value
              topic_data = raw_topics[topic_idx]
              # For static types like uint, address, bool, etc., the value is directly in the topic
              # For dynamic types like string, bytes, arrays, etc., the topic contains a hash of the value
              decoded_value = if type.dynamic?
                               # For dynamic types in topics, the topic contains the hash of the value
                               # For proper decoding, you'd need the original value or to look it up elsewhere
                               topic_data
                             else
                               # For static types, decode from the 32-byte topic value
                               # Convert hex to binary before decoding
                               Decoder.type(type, Util.hex_to_bin(topic_data))
                             end
              result[:params] << { name: input[:name], type: input[:type], value: decoded_value, indexed: true }
              topic_idx += 1
            end
          else  # This parameter was included in the data section
            if type.dynamic?
              # For dynamic types, read the offset first
              offset_ptr = raw_data[data_offset, 64]  # 32 bytes = 64 hex chars
              # Convert hex to binary before deserializing
              actual_offset = Util.deserialize_big_endian_to_int(Util.hex_to_bin(offset_ptr))

              # Decode using the actual offset
              # Convert hex to binary before decoding
              decoded_value = Decoder.type(type, Util.hex_to_bin(raw_data[actual_offset * 2..-1]))
              result[:params] << { name: input[:name], type: input[:type], value: decoded_value, indexed: false }
              data_offset += 64  # Move by 64 hex chars for the offset pointer
            else
              # For static types, decode directly from current offset
              size = type.size * 2  # size in bytes converted to hex chars
              # Convert hex to binary before decoding
              decoded_value = Decoder.type(type, Util.hex_to_bin(raw_data[data_offset, size]))
              result[:params] << { name: input[:name], type: input[:type], value: decoded_value, indexed: false }
              data_offset += size
            end
          end
        end

        result
      end

      # Create an Event instance from an ABI definition
      #
      # @param abi_def [Hash] the ABI definition
      # @return [Event] a new Event instance
      def self.from_abi(abi_def)
        raise ArgumentError, "Not an event definition" unless abi_def[:type] == 'event' || abi_def['type'] == 'event'

        new(
          name: abi_def[:name] || abi_def['name'],
          inputs: abi_def[:inputs] || abi_def['inputs'] || [],
          anonymous: abi_def[:anonymous] || abi_def['anonymous'] || false
        )
      end

      # Generate event signature from signature string
      #
      # @param sig [String] event signature (e.g. "Transfer(address,address,uint256)")
      # @return [String] the topic hash
      def self.signature(sig)
        hash = Digest::Keccak.new(256).digest(sig)
        hash.unpack1('H*')
      end
    end
  end
end
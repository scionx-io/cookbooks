# frozen_string_literal: true
require 'google/protobuf'
require_relative 'protobuf/transaction_raw_serializer'

module Tron
  module Protobuf
    # Main class to serialize TRON transactions for signing
    class TransactionSerializer
      # Serializes a transaction for signing
      #
      # @param transaction [Hash] the transaction to serialize
      # @return [String] the serialized transaction
      def self.serialize_for_signing(transaction)
        TransactionRawSerializer.serialize(transaction)
      end
    end
  end
end
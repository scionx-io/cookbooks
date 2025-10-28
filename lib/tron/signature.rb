# frozen_string_literal: true

module Tron
  # Module for handling TRON signature operations
  module Signature
    # Custom error class for signature-related errors
    class SignatureError < StandardError; end
    
    # Prefix byte for TRON signed messages
    PREFIX_BYTE = "\x19".freeze
    
    # Prefixes a message according to the TRON signed message format
    # This format is used in personal_sign operations
    #
    # @param message [String] the message to prefix
    # @return [String] the prefixed message ready for signing
    def self.prefix_message(message)
      "#{PREFIX_BYTE}Tron Signed Message:\n#{message.size}#{message}"
    end
  end
end
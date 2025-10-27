# frozen_string_literal: true

module Tron
  module Signature
    class SignatureError < StandardError; end
    
    PREFIX_BYTE = "\x19".freeze
    
    def self.prefix_message(message)
      "#{PREFIX_BYTE}Tron Signed Message:\n#{message.size}#{message}"
    end
  end
end
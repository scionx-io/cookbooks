# lib/tron/utils/cache.rb
require 'monitor'

module Tron
  module Utils
    # A simple thread-safe cache with time-based expiration
    class Cache
      include MonitorMixin

      # Creates a new cache instance with the specified maximum age
      #
      # @param max_age [Integer] maximum age of cached entries in seconds (default: 300)
      def initialize(max_age: 300) # 5 minutes default
        super()
        @cache = {}
        @timestamps = {}
        @max_age = max_age
      end

      # Retrieves a value from the cache
      # Automatically removes expired entries before retrieval
      #
      # @param key [Object] the cache key
      # @return [Object, nil] the cached value or nil if not found or expired
      def get(key)
        synchronize do
          cleanup_expired_entries

          if @cache.key?(key)
            @cache[key]
          else
            nil
          end
        end
      end

      # Sets a value in the cache with the current timestamp
      #
      # @param key [Object] the cache key
      # @param value [Object] the value to cache
      def set(key, value)
        synchronize do
          @cache[key] = value
          @timestamps[key] = Time.now.to_f
        end
      end

      # Removes a specific key from the cache
      #
      # @param key [Object] the cache key to delete
      def delete(key)
        synchronize do
          @cache.delete(key)
          @timestamps.delete(key)
        end
      end

      # Clears all entries from the cache
      def clear
        synchronize do
          @cache.clear
          @timestamps.clear
        end
      end

      private

      # Removes expired entries from the cache
      def cleanup_expired_entries
        now = Time.now.to_f
        expired_keys = @timestamps.select { |_, timestamp| now - timestamp > @max_age }.keys
        expired_keys.each do |key|
          @cache.delete(key)
          @timestamps.delete(key)
        end
      end
    end
  end
end
# lib/tron/utils/cache.rb
require 'monitor'

module Tron
  module Utils
    class Cache
      include MonitorMixin

      def initialize(max_age: 300) # 5 minutes default
        super()
        @cache = {}
        @timestamps = {}
        @max_age = max_age
      end

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

      def set(key, value)
        synchronize do
          @cache[key] = value
          @timestamps[key] = Time.now.to_f
        end
      end

      def delete(key)
        synchronize do
          @cache.delete(key)
          @timestamps.delete(key)
        end
      end

      def clear
        synchronize do
          @cache.clear
          @timestamps.clear
        end
      end

      private

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
# lib/tron/utils/rate_limiter.rb
require 'monitor'

module Tron
  module Utils
    class RateLimiter
      include MonitorMixin

      def initialize(max_requests:, time_window:)
        super()
        @max_requests = max_requests
        @time_window = time_window
        @request_timestamps = []
      end

      def can_make_request?
        synchronize do
          cleanup_old_requests
          @request_timestamps.length < @max_requests
        end
      end

      def execute_request
        synchronize do
          cleanup_old_requests
          
          if @request_timestamps.length >= @max_requests
            # Calculate sleep time until oldest request exits the time window
            oldest_time = @request_timestamps.first
            sleep_time = @time_window - (Time.now.to_f - oldest_time)
            sleep(sleep_time) if sleep_time > 0
            cleanup_old_requests
          end
          
          @request_timestamps << Time.now.to_f
          # Return the time until next allowed request
          calculate_time_to_next_request
        end
      end

      private

      def cleanup_old_requests
        now = Time.now.to_f
        @request_timestamps.reject! { |timestamp| now - timestamp > @time_window }
      end

      def calculate_time_to_next_request
        if @request_timestamps.length <= 1
          0
        else
          now = Time.now.to_f
          oldest_in_window = now - @time_window
          next_available = @request_timestamps.find { |ts| ts > oldest_in_window }
          next_available ? [0, @time_window - (now - next_available)].max : 0
        end
      end
    end
  end
end
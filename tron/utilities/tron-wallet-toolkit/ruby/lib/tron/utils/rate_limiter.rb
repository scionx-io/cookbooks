# lib/tron/utils/rate_limiter.rb
require 'monitor'

module Tron
  module Utils
    # A thread-safe rate limiter that limits requests based on a maximum number of requests within a specific time window
    class RateLimiter
      include MonitorMixin

      # Creates a new rate limiter instance
      #
      # @param max_requests [Integer] maximum number of requests allowed in the time window
      # @param time_window [Float] time window in seconds
      def initialize(max_requests:, time_window:)
        super()
        @max_requests = max_requests
        @time_window = time_window
        @request_timestamps = []
      end

      # Checks if a request can be made without exceeding the rate limit
      #
      # @return [Boolean] true if a request can be made, false otherwise
      def can_make_request?
        synchronize do
          cleanup_old_requests
          @request_timestamps.length < @max_requests
        end
      end

      # Executes a request, blocking if necessary to respect the rate limit
      # This method will sleep if necessary to ensure the rate limit is not exceeded
      #
      # @return [Float] the time until the next request is allowed
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

      # Removes timestamps that are outside the time window
      def cleanup_old_requests
        now = Time.now.to_f
        @request_timestamps.reject! { |timestamp| now - timestamp > @time_window }
      end

      # Calculates the time until the next request is allowed
      #
      # @return [Float] the time in seconds until the next request is allowed
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
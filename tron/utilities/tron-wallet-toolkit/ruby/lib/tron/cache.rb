require 'thread'

module Tron
  # Thread-safe, global cache implementation for TRON wallet toolkit
  # 
  # This cache provides a simple key-value store with time-based expiration and 
  # failure fallback capabilities. It's designed specifically for caching API 
  # responses to improve performance and reduce rate limit issues.
  # 
  # Features:
  # - Thread-safe operations using Mutex synchronization
  # - Time-based expiration with TTL (time-to-live) and max_stale settings
  # - Fallback behavior when cache refresh fails
  # - Global storage shared across all instances
  # - Cache statistics tracking (hits, misses)
  # 
  # Example usage:
  #   Tron::Cache.fetch("wallet_balance_#{address}", ttl: 300, max_stale: 600) do
  #     api_client.get_wallet_balance(address)
  #   end
  class Cache
    # Class-level storage for global cache
    @@store = {}
    @@mutex = Mutex.new
    # Global statistics
    @@global_stats = { total_hits: 0, total_misses: 0, total_fetches: 0 }

    # Fetches a value from cache or executes the block to generate and cache it
    #
    # The fetch method implements a time-based caching strategy with fallback:
    # 1. If entry exists and is fresh (age < ttl) → return cached value
    # 2. If entry exists but stale (age > ttl but < max_stale) → try to update:
    #    - If block succeeds: cache new value and return it
    #    - If block raises error: return stale value (fallback)
    # 3. If no cache or too old → execute block, cache result, return it
    #
    # @param key [String] the cache key (should be unique for the data being cached)
    # @param ttl [Integer] time-to-live in seconds (how long to consider value fresh)
    # @param max_stale [Integer] maximum stale time in seconds (how long to keep stale values)
    # @yield [Proc] block to execute if value is not cached or expired
    # @return [Object] the cached value or result from the block
    # @raise [ArgumentError] if no block is provided
    def self.fetch(key, ttl:, max_stale:, &block)
      raise ArgumentError, "Block required for cache fetch" unless block_given?
      
      @@mutex.synchronize do
        entry = @@store[key]
        @@global_stats[:total_fetches] += 1

        if entry && Time.now - entry[:cached_at] < ttl
          # Cache is fresh - return cached value
          # Increment hit counter if present
          @@store[key][:hits] = (entry[:hits] || 0) + 1
          @@global_stats[:total_hits] += 1
          return entry[:value]
        elsif entry && Time.now - entry[:cached_at] < max_stale
          # Cache is stale but within max_stale - try to update with fallback
          begin
            new_value = yield
            @@store[key] = {
              value: new_value,
              cached_at: Time.now,
              ttl: ttl,
              max_stale: max_stale,
              hits: 0,
              misses: 0
            }
            @@global_stats[:total_misses] += 1
            return new_value
          rescue => e
            # Return stale value as fallback
            # Increment miss counter since the block failed
            @@store[key][:misses] = (entry[:misses] || 0) + 1
            @@global_stats[:total_hits] += 1  # Stale hit is still a hit
            return entry[:value]
          end
        else
          # No cache or too old - execute block and cache result
          new_value = yield
          @@store[key] = {
            value: new_value,
            cached_at: Time.now,
            ttl: ttl,
            max_stale: max_stale,
            hits: 0,
            misses: 0
          }
          @@global_stats[:total_misses] += 1
          return new_value
        end
      end
    end

    # Checks if a key exists in the cache (without considering expiration)
    #
    # @param key [String] the cache key
    # @return [Boolean] true if key exists in the cache, false otherwise
    def self.exists?(key)
      @@mutex.synchronize do
        @@store.key?(key)
      end
    end

    # Deletes a specific key from the cache
    #
    # @param key [String] the cache key to delete
    # @return [void]
    def self.delete(key)
      @@mutex.synchronize do
        @@store.delete(key)
      end
    end

    # Clears all cached entries
    # 
    # This is useful for testing or when a full cache refresh is needed.
    # @return [void]
    def self.clear
      @@mutex.synchronize do
        @@store.clear
      end
    end

    # Returns the number of cached entries
    # @return [Integer] number of cached entries
    def self.size
      @@mutex.synchronize do
        @@store.size
      end
    end
    
    # Returns cache statistics for a specific key
    #
    # @param key [String] the cache key
    # @return [Hash, nil] statistics hash if key exists, nil otherwise
    def self.stats(key)
      @@mutex.synchronize do
        entry = @@store[key]
        return nil unless entry

        {
          hits: entry[:hits] || 0,
          misses: entry[:misses] || 0,
          cached_at: entry[:cached_at],
          expires_at: entry[:cached_at] + entry[:ttl],
          ttl: entry[:ttl],
          max_stale: entry[:max_stale],
          expired: Time.now - entry[:cached_at] >= entry[:ttl]
        }
      end
    end

    # Returns global cache statistics across all keys
    #
    # This provides an overall view of cache performance including hit rate.
    # @return [Hash] global statistics including total_hits, total_misses, hit_rate
    def self.global_stats
      @@mutex.synchronize do
        total_requests = @@global_stats[:total_fetches]
        hit_rate = if total_requests > 0
          (@@global_stats[:total_hits].to_f / total_requests * 100).round(2)
        else
          0.0
        end

        {
          total_hits: @@global_stats[:total_hits],
          total_misses: @@global_stats[:total_misses],
          total_fetches: @@global_stats[:total_fetches],
          hit_rate_percentage: hit_rate,
          cache_size: @@store.size,
          memory_keys: @@store.keys.size
        }
      end
    end

    # Reset global statistics
    # Useful for testing or when you want to start fresh statistics
    # @return [void]
    def self.reset_stats
      @@mutex.synchronize do
        @@global_stats = { total_hits: 0, total_misses: 0, total_fetches: 0 }
      end
    end
  end
end
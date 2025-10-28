require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/tron'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class TestCache < Minitest::Test
  def setup
    Tron::Cache.clear # Ensure clean state before each test
    Tron::Cache.reset_stats # Reset global statistics before each test
  end

  def teardown
    Tron::Cache.clear # Clean up after each test
    Tron::Cache.reset_stats # Reset global statistics after each test
  end

  def test_basic_caching_functionality
    key = "test_key"
    expected_value = "cached_value"

    # First fetch should execute the block and cache the result
    result1 = Tron::Cache.fetch(key, ttl: 10, max_stale: 20) { expected_value }
    assert_equal expected_value, result1

    # Second fetch should return the cached value without executing the block
    block_executed = false
    result2 = Tron::Cache.fetch(key, ttl: 10, max_stale: 20) do
      block_executed = true
      "should_not_be_returned"
    end
    
    assert_equal expected_value, result2
    refute block_executed, "Block should not have been executed on second fetch"
  end

  def test_ttl_expiration
    key = "ttl_test"
    initial_value = "initial_value_#{Time.now.to_i}"

    # Initial fetch
    result1 = Tron::Cache.fetch(key, ttl: 1, max_stale: 5) { initial_value }
    assert_equal initial_value, result1

    sleep(2)  # Wait for TTL to expire

    # After TTL expiry, block should be executed again
    new_value = "new_value_#{Time.now.to_i}"
    result2 = Tron::Cache.fetch(key, ttl: 1, max_stale: 5) { new_value }
    assert_equal new_value, result2
  end

  def test_max_stale_with_fallback
    key = "stale_test"
    
    # First, cache a value
    initial_value = "initial_value"
    result1 = Tron::Cache.fetch(key, ttl: 1, max_stale: 10) { initial_value }
    assert_equal initial_value, result1
    
    # Wait for TTL to expire but stay within max_stale
    sleep(2)
    
    # When block fails, should return stale value
    result2 = Tron::Cache.fetch(key, ttl: 1, max_stale: 10) do
      raise "API call failed"
    end
    assert_equal initial_value, result2
  end

  def test_cache_size
    # Initially empty
    assert_equal 0, Tron::Cache.size

    # Add items
    Tron::Cache.fetch("size_test1", ttl: 10, max_stale: 20) { "value1" }
    assert_equal 1, Tron::Cache.size

    Tron::Cache.fetch("size_test2", ttl: 10, max_stale: 20) { "value2" }
    assert_equal 2, Tron::Cache.size

    # Clear and verify
    Tron::Cache.clear
    assert_equal 0, Tron::Cache.size
  end

  def test_exists_method
    key = "exists_test"
    
    # Key should not exist initially
    refute Tron::Cache.exists?(key)

    # After caching a value, should exist
    Tron::Cache.fetch(key, ttl: 10, max_stale: 20) { "value" }
    assert Tron::Cache.exists?(key)

    # After deletion, should not exist
    Tron::Cache.delete(key)
    refute Tron::Cache.exists?(key)
  end

  def test_delete_method
    key = "delete_test"
    
    # Cache a value
    Tron::Cache.fetch(key, ttl: 10, max_stale: 20) { "value" }
    assert Tron::Cache.exists?(key)

    # Delete it
    Tron::Cache.delete(key)
    refute Tron::Cache.exists?(key)
  end

  def test_block_not_provided_error
    assert_raises(ArgumentError) do
      Tron::Cache.fetch("no_block_test", ttl: 10, max_stale: 20)
    end
  end

  def test_different_data_types
    # Test with string
    string_result = Tron::Cache.fetch("string_key", ttl: 10, max_stale: 20) { "string_value" }
    assert_equal "string_value", string_result

    # Test with array
    array_result = Tron::Cache.fetch("array_key", ttl: 10, max_stale: 20) { [1, 2, 3] }
    assert_equal [1, 2, 3], array_result

    # Test with hash
    hash_result = Tron::Cache.fetch("hash_key", ttl: 10, max_stale: 20) { { key: "value" } }
    assert_equal({ key: "value" }, hash_result)

    # Verify they all return cached values
    assert_equal "string_value", Tron::Cache.fetch("string_key", ttl: 10, max_stale: 20) { "different" }
    assert_equal [1, 2, 3], Tron::Cache.fetch("array_key", ttl: 10, max_stale: 20) { [4, 5, 6] }
    assert_equal({ key: "value" }, Tron::Cache.fetch("hash_key", ttl: 10, max_stale: 20) { { different: "value" } })
  end

  def test_cache_stats
    key = "stats_test"
    
    # Cache a value
    Tron::Cache.fetch(key, ttl: 30, max_stale: 60) { "value" }
    
    # Check stats exist
    stats = Tron::Cache.stats(key)
    refute_nil stats
    assert_equal 0, stats[:hits]  # No hits yet since it was just cached
    assert_equal 0, stats[:misses]
    refute_nil stats[:cached_at]
    refute_nil stats[:expires_at]
    assert_equal 30, stats[:ttl]
    assert_equal 60, stats[:max_stale]
    refute stats[:expired]
    
    # Access again to increment hits
    Tron::Cache.fetch(key, ttl: 30, max_stale: 60) { "value" }
    
    # Check that hits were incremented
    stats_after_hit = Tron::Cache.stats(key)
    assert_equal 1, stats_after_hit[:hits]
  end

  def test_concurrent_access_thread_safety
    # This test checks for basic thread safety by running multiple threads
    # accessing the same key to verify that the mutex prevents race conditions
    key = "thread_safety_test"
    results = []
    threads = []

    # Create multiple threads that all try to fetch the same key
    5.times do |i|
      threads << Thread.new do
        result = Tron::Cache.fetch(key, ttl: 10, max_stale: 20) { "value_from_thread_#{i}" }
        results << result
      end
    end

    threads.each(&:join)

    # All threads should have received the same value (from the first thread that cached it)
    assert_equal 1, results.uniq.length, "All threads should have received the same cached value"
  end

  def test_global_statistics
    # Initially, stats should be zero
    stats = Tron::Cache.global_stats
    assert_equal 0, stats[:total_hits]
    assert_equal 0, stats[:total_misses]
    assert_equal 0, stats[:total_fetches]
    assert_equal 0.0, stats[:hit_rate_percentage]

    # First fetch should be a miss
    Tron::Cache.fetch("stats_key", ttl: 10, max_stale: 20) { "value" }
    stats = Tron::Cache.global_stats
    assert_equal 0, stats[:total_hits]
    assert_equal 1, stats[:total_misses]
    assert_equal 1, stats[:total_fetches]
    assert_equal 0.0, stats[:hit_rate_percentage]

    # Second fetch should be a hit
    Tron::Cache.fetch("stats_key", ttl: 10, max_stale: 20) { "value" }
    stats = Tron::Cache.global_stats
    assert_equal 1, stats[:total_hits]
    assert_equal 1, stats[:total_misses]
    assert_equal 2, stats[:total_fetches]
    assert_equal 50.0, stats[:hit_rate_percentage]

    # Third fetch should also be a hit
    Tron::Cache.fetch("stats_key", ttl: 10, max_stale: 20) { "value" }
    stats = Tron::Cache.global_stats
    assert_equal 2, stats[:total_hits]
    assert_equal 1, stats[:total_misses]
    assert_equal 3, stats[:total_fetches]
    assert_equal 66.67, stats[:hit_rate_percentage]
  end

  def test_reset_stats
    # Add some cache entries
    Tron::Cache.fetch("key1", ttl: 10, max_stale: 20) { "value1" }
    Tron::Cache.fetch("key1", ttl: 10, max_stale: 20) { "value1" }

    stats = Tron::Cache.global_stats
    assert stats[:total_fetches] > 0

    # Reset stats
    Tron::Cache.reset_stats

    stats = Tron::Cache.global_stats
    assert_equal 0, stats[:total_hits]
    assert_equal 0, stats[:total_misses]
    assert_equal 0, stats[:total_fetches]
  end
end
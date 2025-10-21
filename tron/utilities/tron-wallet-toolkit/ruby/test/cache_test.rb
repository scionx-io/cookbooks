require 'test_helper'

class CacheTest < Minitest::Test
  def setup
    # Clear the global cache before each test
    Tron::Cache.clear
    Tron::Cache.reset_stats
  end

  def teardown
    # Clear the global cache after each test
    Tron::Cache.clear
    Tron::Cache.reset_stats
  end

  def test_basic_caching
    call_count = 0

    # First call - should execute block
    result1 = Tron::Cache.fetch("test_key", ttl: 30, max_stale: 300) do
      call_count += 1
      "cached_value"
    end

    # Second call - should use cache
    result2 = Tron::Cache.fetch("test_key", ttl: 30, max_stale: 300) do
      call_count += 1
      "cached_value"
    end

    assert_equal "cached_value", result1
    assert_equal "cached_value", result2
    assert_equal 1, call_count, "Block should only execute once"
  end

  def test_cache_ttl_expiration
    call_count = 0

    # First call
    result1 = Tron::Cache.fetch("test_ttl", ttl: 1, max_stale: 10) do
      call_count += 1
      "value_#{call_count}"
    end

    # Immediate second call - should use cache
    result2 = Tron::Cache.fetch("test_ttl", ttl: 1, max_stale: 10) do
      call_count += 1
      "value_#{call_count}"
    end

    # Wait for TTL to expire
    sleep 1.5

    # Third call - should execute block again
    result3 = Tron::Cache.fetch("test_ttl", ttl: 1, max_stale: 10) do
      call_count += 1
      "value_#{call_count}"
    end

    assert_equal "value_1", result1
    assert_equal "value_1", result2
    assert_equal "value_2", result3
    assert_equal 2, call_count, "Block should execute twice (initial + after expiry)"
  end

  def test_stale_value_fallback
    call_count = 0

    # First call - cache a value
    result1 = Tron::Cache.fetch("test_stale", ttl: 1, max_stale: 10) do
      call_count += 1
      "initial_value"
    end

    # Wait for TTL to expire but stay within max_stale
    sleep 1.5

    # Second call - TTL expired, block raises error, should return stale value
    result2 = Tron::Cache.fetch("test_stale", ttl: 1, max_stale: 10) do
      call_count += 1
      raise "API Error"
    end

    assert_equal "initial_value", result1
    assert_equal "initial_value", result2, "Should return stale value on error"
    assert_equal 2, call_count, "Block should execute twice"
  end

  def test_cache_stats
    # Make some cache calls
    3.times do
      Tron::Cache.fetch("stats_key", ttl: 30, max_stale: 300) { "value" }
    end

    stats = Tron::Cache.stats("stats_key")
    assert_equal 2, stats[:hits], "Should have 2 cache hits"
    assert_equal 0, stats[:misses]
    assert stats[:cached_at].is_a?(Time)
    assert_equal 30, stats[:ttl]
  end

  def test_global_stats
    # Make cache calls to different keys
    2.times { Tron::Cache.fetch("key1", ttl: 30, max_stale: 300) { "value1" } }
    3.times { Tron::Cache.fetch("key2", ttl: 30, max_stale: 300) { "value2" } }

    global_stats = Tron::Cache.global_stats

    assert_equal 3, global_stats[:total_hits], "Should have 3 cache hits (1 from key1, 2 from key2)"
    assert_equal 2, global_stats[:total_misses], "Should have 2 misses (initial calls)"
    assert_equal 5, global_stats[:total_fetches], "Should have 5 total fetches"
    assert global_stats[:hit_rate_percentage] > 0
  end

  def test_cache_exists
    refute Tron::Cache.exists?("nonexistent"), "Should not exist"

    Tron::Cache.fetch("existing", ttl: 30, max_stale: 300) { "value" }

    assert Tron::Cache.exists?("existing"), "Should exist after caching"
  end

  def test_cache_delete
    Tron::Cache.fetch("deletable", ttl: 30, max_stale: 300) { "value" }
    assert Tron::Cache.exists?("deletable")

    Tron::Cache.delete("deletable")
    refute Tron::Cache.exists?("deletable"), "Should be deleted"
  end

  def test_cache_clear
    Tron::Cache.fetch("key1", ttl: 30, max_stale: 300) { "value1" }
    Tron::Cache.fetch("key2", ttl: 30, max_stale: 300) { "value2" }

    assert_equal 2, Tron::Cache.size

    Tron::Cache.clear

    assert_equal 0, Tron::Cache.size
  end

  def test_cache_size
    assert_equal 0, Tron::Cache.size

    Tron::Cache.fetch("key1", ttl: 30, max_stale: 300) { "value1" }
    assert_equal 1, Tron::Cache.size

    Tron::Cache.fetch("key2", ttl: 30, max_stale: 300) { "value2" }
    assert_equal 2, Tron::Cache.size
  end

  def test_block_required
    assert_raises(ArgumentError) do
      Tron::Cache.fetch("key", ttl: 30, max_stale: 300)
    end
  end

  def test_different_networks_use_different_cache_keys
    # This test verifies that cache keys should include network context
    # when used by the client (this is tested at integration level)

    mainnet_value = Tron::Cache.fetch("balance:mainnet:addr123", ttl: 30, max_stale: 300) { "mainnet_data" }
    nile_value = Tron::Cache.fetch("balance:nile:addr123", ttl: 30, max_stale: 300) { "nile_data" }

    assert_equal "mainnet_data", mainnet_value
    assert_equal "nile_data", nile_value
    assert_equal 2, Tron::Cache.size, "Should have separate cache entries for different networks"
  end
end

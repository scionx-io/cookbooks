require 'test_helper'

class CacheTest < Minitest::Test
  def setup
    @client = Tron::Client.new(
      api_key: ENV['TRONGRID_API_KEY'],
      tronscan_api_key: ENV['TRONSCAN_API_KEY'],
      network: :mainnet,
      cache: { enabled: true, ttl: 30, max_stale: 300 }
    )
    @test_address = "TCPh7Qd7DwHvphmfJGCQQgCGRP7aY4drEV"
  end

  def test_cache_configuration
    assert @client.respond_to?(:cache_enabled?), "Client should have cache_enabled? method"
    assert @client.cache_enabled?, "Cache should be enabled"
    assert_equal 30, @client.configuration.cache_ttl
    assert_equal 300, @client.configuration.cache_max_stale
  end

  def test_portfolio_caching_speedup
    # First call - should hit API
    start = Time.now
    result1 = @client.get_wallet_portfolio(@test_address)
    time1 = Time.now - start

    # Second call - should use cache
    start = Time.now
    result2 = @client.get_wallet_portfolio(@test_address)
    time2 = Time.now - start

    assert result1[:tokens].length > 0, "Should have tokens"
    assert_equal result1[:tokens].length, result2[:tokens].length, "Results should match"
    assert time2 < (time1 / 2), "Second call should be at least 2x faster (cached)"
  end

  def test_price_caching
    # First call
    result1 = @client.get_wallet_portfolio(@test_address)
    usdt1 = result1[:tokens].find { |t| t[:symbol] == 'USDT' }

    sleep 1 # Small delay

    # Second call - prices should be cached
    start = Time.now
    result2 = @client.get_wallet_portfolio(@test_address)
    time2 = Time.now - start

    usdt2 = result2[:tokens].find { |t| t[:symbol] == 'USDT' }

    assert_equal usdt1[:price_usd], usdt2[:price_usd], "Cached price should match"
    assert time2 < 0.5, "Second call should be very fast (cached)"
  end

  def test_rate_limit_protection
    errors = 0
    cached = 0

    10.times do |i|
      start = Time.now
      begin
        result = @client.get_wallet_portfolio(@test_address)
        time = Time.now - start
        cached += 1 if time < 0.5
      rescue => e
        errors += 1
      end
      sleep 0.5 # Faster than 1 req/sec rate limit
    end

    assert_equal 0, errors, "Should not have any rate limit errors"
    assert cached >= 8, "At least 8/10 requests should be cached"
  end

  def test_cache_ttl_expiration
    # Create client with short TTL for testing
    client = Tron::Client.new(
      api_key: ENV['TRONGRID_API_KEY'],
      tronscan_api_key: ENV['TRONSCAN_API_KEY'],
      cache: { enabled: true, ttl: 5, max_stale: 10 }
    )

    # First request
    start = Time.now
    result1 = client.get_wallet_portfolio(@test_address)
    time1 = Time.now - start

    # Immediate second request (should be cached)
    start = Time.now
    result2 = client.get_wallet_portfolio(@test_address)
    time2 = Time.now - start

    # Wait for TTL to expire
    sleep 6

    # Third request (should hit API again)
    start = Time.now
    result3 = client.get_wallet_portfolio(@test_address)
    time3 = Time.now - start

    assert time2 < (time1 / 2), "Second request should be cached"
    assert time3 > (time2 * 2), "Third request should hit API again after TTL"
  end

  def test_stale_while_revalidate
    skip "Requires manual testing with API failures"

    # 1. Populate cache
    @client.get_wallet_portfolio(@test_address)

    # 2. Wait for TTL to expire but within max_stale
    sleep 35 # Cache is stale but within 5min max_stale

    # 3. Make request - should serve stale if API fails
    result = @client.get_wallet_portfolio(@test_address)

    assert !result[:tokens].empty?, "Should return data (fresh or stale)"
  end

  def test_cache_stats
    skip unless @client.respond_to?(:cache_stats)

    # Make some requests
    3.times { @client.get_wallet_portfolio(@test_address) }

    stats = @client.cache_stats
    assert stats.is_a?(Hash), "Cache stats should be a hash"
  end

  def test_cache_key_includes_network
    skip "Requires cache implementation in services"

    mainnet_client = Tron::Client.new(
      api_key: ENV['TRONGRID_API_KEY'],
      tronscan_api_key: ENV['TRONSCAN_API_KEY'],
      network: :mainnet,
      cache: { enabled: true, ttl: 30 }
    )

    nile_client = Tron::Client.new(
      api_key: ENV['TRONGRID_API_KEY'],
      tronscan_api_key: ENV['TRONSCAN_API_KEY'],
      network: :nile,
      cache: { enabled: true, ttl: 30 }
    )

    # These should cache separately (different networks)
    mainnet_result = mainnet_client.get_wallet_portfolio(@test_address)
    nile_result = nile_client.get_wallet_portfolio(@test_address)

    # Results should potentially be different (different networks)
    # Cache keys should include network to prevent cross-contamination
    assert true # Placeholder - actual test would verify cache keys
  end
end

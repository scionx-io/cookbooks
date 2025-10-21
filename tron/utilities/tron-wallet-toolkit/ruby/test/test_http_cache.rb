require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/tron'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class TestHTTPCache < Minitest::Test
  def setup
    Tron::Cache.clear
    Tron::Cache.reset_stats
    # Reset configuration to defaults
    Tron.configure do |config|
      config.cache_enabled = true
      config.cache_ttl = 300
      config.cache_max_stale = 600
    end
  end

  def teardown
    Tron::Cache.clear
    Tron::Cache.reset_stats
  end

  def test_cache_configuration_defaults
    config = Tron.configuration
    assert_equal true, config.cache_enabled
    assert_equal 300, config.cache_ttl
    assert_equal 600, config.cache_max_stale
  end

  def test_cache_can_be_disabled_globally
    Tron.configure do |config|
      config.cache_enabled = false
    end

    assert_equal false, Tron.configuration.cache_enabled
  end

  def test_custom_cache_ttl_configuration
    Tron.configure do |config|
      config.cache_ttl = 600
      config.cache_max_stale = 1200
    end

    assert_equal 600, Tron.configuration.cache_ttl
    assert_equal 1200, Tron.configuration.cache_max_stale
  end

  def test_endpoint_ttl_constants
    # Verify that different endpoint types have appropriate TTL values
    assert_equal 300, Tron::Utils::HTTP::ENDPOINT_TTL[:balance][:ttl]
    assert_equal 900, Tron::Utils::HTTP::ENDPOINT_TTL[:token_info][:ttl]
    assert_equal 60, Tron::Utils::HTTP::ENDPOINT_TTL[:price][:ttl]
    assert_equal 300, Tron::Utils::HTTP::ENDPOINT_TTL[:resources][:ttl]
    assert_equal 300, Tron::Utils::HTTP::ENDPOINT_TTL[:default][:ttl]
  end

  def test_cache_key_generation_is_consistent
    # Cache keys should be consistent for the same request
    key1 = Tron::Utils::HTTP.send(:generate_cache_key, 'GET', 'http://example.com/test', {})
    key2 = Tron::Utils::HTTP.send(:generate_cache_key, 'GET', 'http://example.com/test', {})
    assert_equal key1, key2
  end

  def test_cache_key_differs_for_different_urls
    key1 = Tron::Utils::HTTP.send(:generate_cache_key, 'GET', 'http://example.com/test1', {})
    key2 = Tron::Utils::HTTP.send(:generate_cache_key, 'GET', 'http://example.com/test2', {})
    refute_equal key1, key2
  end

  def test_cache_key_differs_for_different_headers
    key1 = Tron::Utils::HTTP.send(:generate_cache_key, 'GET', 'http://example.com/test', { 'Authorization' => 'token1' })
    key2 = Tron::Utils::HTTP.send(:generate_cache_key, 'GET', 'http://example.com/test', { 'Authorization' => 'token2' })
    refute_equal key1, key2
  end

  def test_cache_key_ignores_user_agent
    # User-Agent should not affect cache key
    key1 = Tron::Utils::HTTP.send(:generate_cache_key, 'GET', 'http://example.com/test', { 'User-Agent' => 'browser1' })
    key2 = Tron::Utils::HTTP.send(:generate_cache_key, 'GET', 'http://example.com/test', { 'User-Agent' => 'browser2' })
    assert_equal key1, key2
  end

  def test_should_use_cache_respects_global_config
    # When cache is enabled globally
    Tron.configure { |c| c.cache_enabled = true }
    assert Tron::Utils::HTTP.send(:should_use_cache?, {})

    # When cache is disabled globally
    Tron.configure { |c| c.cache_enabled = false }
    refute Tron::Utils::HTTP.send(:should_use_cache?, {})
  end

  def test_should_use_cache_respects_local_override
    # Global enabled, local disabled
    Tron.configure { |c| c.cache_enabled = true }
    refute Tron::Utils::HTTP.send(:should_use_cache?, { enabled: false })

    # Global disabled, but local override doesn't enable it
    # (local can only disable, not enable when globally disabled)
    Tron.configure { |c| c.cache_enabled = false }
    refute Tron::Utils::HTTP.send(:should_use_cache?, { enabled: true })
  end

  def test_get_ttl_config_with_custom_values
    ttl_config = Tron::Utils::HTTP.send(:get_ttl_config, { ttl: 100, max_stale: 200 })
    assert_equal 100, ttl_config[:ttl]
    assert_equal 200, ttl_config[:max_stale]
  end

  def test_get_ttl_config_with_endpoint_type
    ttl_config = Tron::Utils::HTTP.send(:get_ttl_config, { endpoint_type: :price })
    assert_equal 60, ttl_config[:ttl]
    assert_equal 120, ttl_config[:max_stale]
  end

  def test_get_ttl_config_uses_global_configuration
    Tron.configure do |config|
      config.cache_ttl = 500
      config.cache_max_stale = 1000
    end

    ttl_config = Tron::Utils::HTTP.send(:get_ttl_config, {})
    assert_equal 500, ttl_config[:ttl]
    assert_equal 1000, ttl_config[:max_stale]
  end

  def test_get_ttl_config_falls_back_to_default
    # Reset configuration to not have custom values
    Tron.configure do |config|
      config.cache_ttl = nil
      config.cache_max_stale = nil
    end

    ttl_config = Tron::Utils::HTTP.send(:get_ttl_config, {})
    assert_equal 300, ttl_config[:ttl]  # Default TTL
    assert_equal 600, ttl_config[:max_stale]  # Default max_stale
  end

  def test_clear_cache_method_exists
    # Verify that clear_cache method is available
    assert_respond_to Tron::Utils::HTTP, :clear_cache
  end

  def test_cache_stats_method_exists
    # Verify that cache_stats method is available
    assert_respond_to Tron::Utils::HTTP, :cache_stats
  end
end

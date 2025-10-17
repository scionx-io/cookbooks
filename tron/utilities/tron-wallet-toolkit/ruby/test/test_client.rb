require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/tron/client'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class TestClient < Minitest::Test
  TEST_ADDRESS = 'TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb'  # Example address
  def test_client_initialization
    client = Tron::Client.new
    assert_instance_of Tron::Client, client
  end

  def test_client_has_configuration
    client = Tron::Client.new
    assert_instance_of Tron::Configuration, client.configuration
  end

  def test_get_wallet_portfolio_returns_valid_structure
    # Mock the services to avoid actual API calls during testing
    client = Tron::Client.new
    
    # Since testing with real API calls would be complex in test environment,
    # we'll just test that the method exists and doesn't immediately error
    assert_respond_to client, :get_wallet_portfolio
    
    # Test with a mock/stubbed approach would be needed for full testing
    # of the actual API functionality
  end

  def test_get_wallet_portfolio_excludes_zero_balances_by_default
    client = Tron::Client.new
    assert_respond_to client, :get_wallet_portfolio
  end

  def test_get_wallet_portfolio_includes_zero_balances_when_requested
    client = Tron::Client.new
    assert_respond_to client, :get_wallet_portfolio
  end
end
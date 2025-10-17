require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/tron/client'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class TestClient < Minitest::Test
  def test_client_initialization
    client = Tron::Client.new
    assert_instance_of Tron::Client, client
  end

  def test_client_has_configuration
    client = Tron::Client.new
    assert_instance_of Tron::Configuration, client.configuration
  end
end
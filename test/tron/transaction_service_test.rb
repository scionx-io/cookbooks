require 'test_helper'

class TransactionServiceTest < Minitest::Test
  def setup
    @config = Tron::Configuration.new
    @transaction_service = Tron::Services::Transaction.new(@config)
  end

  def test_transaction_service_initialization
    assert_instance_of Tron::Services::Transaction, @transaction_service
    assert_equal @config, @transaction_service.instance_variable_get(:@configuration)
  end

  def test_get_transaction_method_exists
    assert_respond_to @transaction_service, :get_transaction
  end

  def test_sign_and_broadcast_method_exists
    assert_respond_to @transaction_service, :sign_and_broadcast
  end

  def test_transaction_service_can_be_accessed_from_client
    client = Tron::Client.new
    assert_respond_to client, :transaction_service
    assert_instance_of Tron::Services::Transaction, client.transaction_service
  end
end
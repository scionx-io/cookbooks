# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../../lib/tron/abi'

class EventTest < Minitest::Test
  def test_event_signature
    # Test standard ERC20 Transfer event signature
    signature = Tron::Abi::Event.signature("Transfer(address,address,uint256)")
    expected = "ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    assert_equal expected, signature
  end

  def test_event_creation_from_abi
    abi_def = {
      type: 'event',
      name: 'Transfer',
      inputs: [
        { type: 'address', name: 'from', indexed: true },
        { type: 'address', name: 'to', indexed: true },
        { type: 'uint256', name: 'value', indexed: false }
      ],
      anonymous: false
    }
    
    event = Tron::Abi::Event.from_abi(abi_def)
    assert_equal 'Transfer', event.name
    assert_equal 3, event.inputs.length
    refute event.anonymous
  end

  def test_decode_log_data
    event = Tron::Abi::Event.new(
      name: 'Transfer',
      inputs: [
        { type: 'address', name: 'from', indexed: true },
        { type: 'address', name: 'to', indexed: true },
        { type: 'uint256', name: 'value', indexed: false }
      ]
    )
    
    # Create mock log data
    from_addr = 'TJRyWwFs9wkrx1UN2bCJNBYFv3nD82H6uq'
    to_addr = 'TY1y3eVDa6X6Xj5aVq44a5r5GQbq88Yj71'
    value = 1000
    
    # Encode the non-indexed parameters to form the data part
    encoded_data = Tron::Abi.encode(['uint256'], [value])
    
    # Create topic values (indexed parameters + event signature for non-anonymous events)
    topic0 = event.topic_hash  # Event signature hash
    topic1 = Tron::Abi.encode(['address'], [from_addr])  # Encoded address (32 bytes as hex)
    topic2 = Tron::Abi.encode(['address'], [to_addr])    # Encoded address (32 bytes as hex)
    
    # Create topics array (for non-anonymous events, first topic is the signature)
    topics = [topic0, topic1, topic2]
    
    # Decode the log
    result = event.decode_log(topics, encoded_data)
    
    # Check the results
    assert_equal 'Transfer', result[:name]
    assert_equal 3, result[:params].length
    
    # Find the value parameter in results (non-indexed)
    value_param = result[:params].find { |p| p[:name] == 'value' }
    assert_equal value, value_param[:value].to_i
    assert_equal false, value_param[:indexed]
    
    # Since addresses in topics are hashed for dynamic types, we check differently
    indexed_params = result[:params].select { |p| p[:indexed] }
    assert_equal 2, indexed_params.length
  end

  def test_decode_log_data_static_types
    # Test with static types in topics (like uint256 which can be in indexed position)
    event = Tron::Abi::Event.new(
      name: 'TestEvent',
      inputs: [
        { type: 'uint256', name: 'id', indexed: true },
        { type: 'address', name: 'user', indexed: false }
      ]
    )

    # Create mock log data
    id = 123
    user_addr = 'TJRyWwFs9wkrx1UN2bCJNBYFv3nD6HUGKN'

    # Encode the non-indexed parameters
    encoded_data = Tron::Abi.encode(['address'], [user_addr])

    # Create topic values
    topic0 = event.topic_hash
    topic1 = Tron::Abi.encode(['uint256'], [id])  # uint256 is static, so full 32 bytes value

    # Create topics array
    topics = [topic0, topic1]

    # Decode the log
    result = event.decode_log(topics, encoded_data)

    # Check the results
    assert_equal 'TestEvent', result[:name]
    assert_equal 2, result[:params].length

    # Find the id parameter (indexed)
    id_param = result[:params].find { |p| p[:name] == 'id' }
    assert_equal id, id_param[:value]
    assert_equal true, id_param[:indexed]

    # Find the user parameter (non-indexed)
    user_param = result[:params].find { |p| p[:name] == 'user' }
    assert_equal user_addr, user_param[:value]
    assert_equal false, user_param[:indexed]
  end
end
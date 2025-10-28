# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../../lib/tron/abi'

class FunctionTest < Minitest::Test
  def test_function_signature
    # Test standard ERC20 transfer function signature
    signature = Tron::Abi::Function.signature("transfer(address,uint256)")
    assert_equal "a9059cbb", signature[0..7]  # First 8 chars of transfer signature
  end

  def test_encode_call_data
    func = Tron::Abi::Function.new(
      name: 'transfer',
      inputs: [
        { type: 'address', name: 'to' },
        { type: 'uint256', name: 'value' }
      ],
      outputs: [
        { type: 'bool', name: 'success' }
      ]
    )
    
    # Encode function call with parameters
    to_address = 'TJRyWwFs9wkrx1UN2bCJNBYFv3nD82H6uq'
    amount = 1000
    encoded_call = func.encode_input([to_address, amount])
    
    # Should start with the function selector (method ID)
    assert encoded_call.start_with?(func.method_id)
    # Should be longer than just the method ID
    assert encoded_call.length > func.method_id.length
  end

  def test_decode_return_values
    func = Tron::Abi::Function.new(
      name: 'balanceOf',
      inputs: [
        { type: 'address', name: 'owner' }
      ],
      outputs: [
        { type: 'uint256', name: 'balance' }
      ]
    )
    
    # Encode a return value
    balance = 1000000
    encoded_return = Tron::Abi.encode(['uint256'], [balance])
    
    # Decode it back using the function
    decoded = func.decode_output('0x' + encoded_return)
    assert_equal [balance], decoded
  end

  def test_function_creation_from_abi
    abi_def = {
      type: 'function',
      name: 'approve',
      inputs: [
        { type: 'address', name: 'spender' },
        { type: 'uint256', name: 'value' }
      ],
      outputs: [
        { type: 'bool', name: 'success' }
      ],
      constant: false
    }
    
    func = Tron::Abi::Function.from_abi(abi_def)
    assert_equal 'approve', func.name
    assert_equal 2, func.inputs.length
    assert func.outputs.length >= 1
  end

  def test_parameter_count_validation
    func = Tron::Abi::Function.new(
      name: 'transfer',
      inputs: [
        { type: 'address', name: 'to' },
        { type: 'uint256', name: 'value' }
      ],
      outputs: [
        { type: 'bool', name: 'success' }
      ]
    )
    
    # Should work with correct parameter count
    assert func.encode_input(['TJRyWwFs9wkrx1UN2bCJNBYFv3nD82H6uq', 100])
    
    # Should raise error with incorrect parameter count
    assert_raises(ArgumentError) { func.encode_input(['TJRyWwFs9wkrx1UN2bCJNBYFv3nD82H6uq']) }  # Missing value
    assert_raises(ArgumentError) { func.encode_input(['TJRyWwFs9wkrx1UN2bCJNBYFv3nD82H6uq', 100, 'extra']) }  # Extra param
  end
end
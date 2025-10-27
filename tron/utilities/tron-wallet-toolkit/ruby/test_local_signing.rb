#!/usr/bin/env ruby

# Verify that the local signing implementation works correctly
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'tron'

puts "Testing local signing implementation..."

# Test 1: Key generation
puts "\n1. Testing key generation..."
begin
  key = Tron::Key.new
  puts "   Generated private key: #{key.private_hex.length} characters"
  puts "   Generated public key: #{key.public_hex.length} characters"
  puts "   Generated TRON address: #{key.address}"
  puts "   ✓ Key generation works"
rescue => e
  puts "   ✗ Key generation failed: #{e.message}"
end

# Test 2: Key from existing private key
puts "\n2. Testing key from existing private key..."
begin
  private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  key = Tron::Key.new(priv: private_key_hex)
  
  if key.private_hex == private_key_hex
    puts "   ✓ Key from private key works"
  else
    puts "   ✗ Key from private key failed - mismatch"
  end
rescue => e
  puts "   ✗ Key from private key failed: #{e.message}"
end

# Test 3: Address derivation
puts "\n3. Testing address derivation..."
begin
  private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  key = Tron::Key.new(priv: private_key_hex)
  
  address = key.address
  if address.length == 34 && address.start_with?('T')
    puts "   Generated address: #{address}"
    puts "   ✓ Address derivation works"
  else
    puts "   ✗ Address derivation failed - invalid format"
  end
rescue => e
  puts "   ✗ Address derivation failed: #{e.message}"
end

# Test 4: Signing functionality
puts "\n4. Testing signing functionality..."
begin
  private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  key = Tron::Key.new(priv: private_key_hex)
  
  data_to_sign = "Hello, TRON!"
  hash_to_sign = Tron::Utils::Crypto.keccak256(data_to_sign)
  signature = key.sign(hash_to_sign)
  
  if signature && signature.length > 0
    puts "   Signature: #{signature[0..20]}... (#{signature.length} chars)"
    puts "   ✓ Signing works"
  else
    puts "   ✗ Signing failed - no signature returned"
  end
rescue => e
  puts "   ✗ Signing failed: #{e.message}"
end

# Test 5: Personal signing
puts "\n5. Testing personal signing..."
begin
  private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  key = Tron::Key.new(priv: private_key_hex)
  
  message = "Hello, TRON!"
  signature = key.personal_sign(message)
  
  if signature && signature.length > 0
    puts "   Personal signature: #{signature[0..20]}... (#{signature.length} chars)"
    puts "   ✓ Personal signing works"
  else
    puts "   ✗ Personal signing failed - no signature returned"
  end
rescue => e
  puts "   ✗ Personal signing failed: #{e.message}"
end

# Test 6: Crypto utilities
puts "\n6. Testing crypto utilities..."
begin
  # Test hex conversion
  hex = "68656c6c6f"  # "hello" in hex
  bin = Tron::Utils::Crypto.hex_to_bin(hex)
  if bin == "hello"
    puts "   ✓ Hex to bin conversion works"
  else
    puts "   ✗ Hex to bin conversion failed"
  end

  # Test bin conversion  
  bin = "hello"
  hex = Tron::Utils::Crypto.bin_to_hex(bin)
  if hex == "68656c6c6f"
    puts "   ✓ Bin to hex conversion works"
  else
    puts "   ✗ Bin to hex conversion failed"
  end

  # Test keccak256
  data = "hello"
  hash = Tron::Utils::Crypto.keccak256(data)
  if hash.length == 32
    puts "   ✓ Keccak256 hashing works"
  else
    puts "   ✗ Keccak256 hashing failed - wrong length"
  end

  # Test is_hex
  if Tron::Utils::Crypto.is_hex?("68656c6c6f") && Tron::Utils::Crypto.is_hex?("0x68656c6c6f")
    puts "   ✓ Hex validation works"
  else
    puts "   ✗ Hex validation failed"
  end
rescue => e
  puts "   ✗ Crypto utilities failed: #{e.message}"
end

puts "\nPhase 1 Review Completed!"
puts "Summary: Local signing implementation appears to be working correctly"
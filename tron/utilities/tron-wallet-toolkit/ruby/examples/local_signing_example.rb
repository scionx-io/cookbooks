#!/usr/bin/env ruby
# frozen_string_literal: true

# ===============================================================================
# TRON Local Signing Example
# ===============================================================================
#
# This example demonstrates how to sign TRON transactions locally (securely)
# without sending your private key to any external service.
#
# SECURITY: Your private key NEVER leaves your machine!
#
# ===============================================================================

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'tron'

puts "\n" + "="*70
puts "TRON LOCAL SIGNING EXAMPLE"
puts "="*70

# ===============================================================================
# STEP 1: Generate or Import a Key
# ===============================================================================

puts "\n[Step 1] Key Management\n" + "-"*70

# Option A: Generate a new random key
puts "\nOption A: Generate new key"
new_key = Tron::Key.new
puts "  Private Key: #{new_key.private_hex[0..20]}... (hidden for security)"
puts "  Address: #{new_key.address}"

# Option B: Import existing private key
puts "\nOption B: Import existing key"
EXAMPLE_PRIVATE_KEY = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
imported_key = Tron::Key.new(priv: EXAMPLE_PRIVATE_KEY)
puts "  Address: #{imported_key.address}"

# Use the imported key for the rest of this example
key = imported_key

# ===============================================================================
# STEP 2: Create a Transaction via TronGrid API
# ===============================================================================

puts "\n[Step 2] Create Transaction\n" + "-"*70

# Initialize client (use :mainnet for production, :shasta for testing)
client = Tron::Client.new(network: :shasta)

# Create a simple TRX transfer transaction
# In production, use the actual API to create transactions:

puts "\nCreating TRX transfer transaction..."

# Example: Transfer 1 TRX from your address to another
from_address = key.address
to_address = "TGXz5k6xP7JNF5dVHvWJYDzZdVp6eWkqZV"  # Example destination
amount = 1_000_000  # 1 TRX in SUN (1 TRX = 1,000,000 SUN)

# Convert addresses to hex format for API
from_hex = Tron::Utils::Address.to_hex(from_address)
to_hex = Tron::Utils::Address.to_hex(to_address)

puts "  From: #{from_address}"
puts "  To: #{to_address}"
puts "  Amount: #{amount / 1_000_000.0} TRX"

# Call TronGrid API to create the transaction
# This gives us a transaction object with txID (SHA256 hash)
endpoint = "#{client.configuration.base_url}/wallet/createtransaction"
transaction = Tron::Utils::HTTP.post(endpoint, {
  owner_address: from_hex,
  to_address: to_hex,
  amount: amount
})

if transaction['Error']
  puts "  ✗ Error creating transaction: #{transaction['Error']}"
  puts "  Note: This is just an example. You need test TRX from faucet first."
  puts "  Visit: https://www.trongrid.io/faucet"
  # For this example, we'll use a mock transaction
  transaction = {
    'txID' => '88f3cf37fa1d059d1cb9da6c5c8f21fbe5e4add390b42c2d85e50f6945f7578a',
    'raw_data' => {
      'ref_block_bytes' => '604b',
      'ref_block_hash' => 'f7603fc3761380f3',
      'expiration' => Time.now.to_i * 1000 + 60000,
      'timestamp' => Time.now.to_i * 1000
    }
  }
  puts "  Using mock transaction for demonstration..."
end

puts "  ✓ Transaction created"
puts "  Transaction ID (txID): #{transaction['txID']}"

# ===============================================================================
# STEP 3: Sign the Transaction Locally
# ===============================================================================

puts "\n[Step 3] Sign Transaction Locally\n" + "-"*70

puts "\nSigning transaction..."
puts "  IMPORTANT: Your private key stays on this machine!"
puts "  TRON uses SHA256 for transaction hashing"

# The txID is already the SHA256 hash of the protobuf-serialized raw_data
tx_hash = Tron::Utils::Crypto.hex_to_bin(transaction['txID'])

# Sign the transaction hash with your private key
signature = key.sign(tx_hash)

# Add signature to transaction
transaction['signature'] = [signature]

puts "  ✓ Transaction signed locally"
puts "  Signature: #{signature[0..40]}... (#{signature.length} chars)"
puts "  Signature format: Valid (130 hex chars = 65 bytes)"

# ===============================================================================
# STEP 4: Broadcast the Signed Transaction
# ===============================================================================

puts "\n[Step 4] Broadcast Transaction\n" + "-"*70

puts "\nBroadcasting to TRON network..."

# Broadcast the signed transaction
endpoint = "#{client.configuration.base_url}/wallet/broadcasttransaction"
begin
  result = Tron::Utils::HTTP.post(endpoint, transaction)

  if result['result'] == true
    puts "  ✓ Transaction broadcast successful!"
    puts "  Transaction ID: #{result['txid']}"
    puts "\n  View on Shasta Explorer:"
    puts "  https://shasta.tronscan.org/#/transaction/#{result['txid']}"
  else
    puts "  ✗ Broadcast failed"
    puts "  Message: #{result['message'] || result['code']}"
    puts "\n  Note: This example uses mock data. For real transactions:"
    puts "  1. Get test TRX from: https://www.trongrid.io/faucet"
    puts "  2. Use a valid destination address"
    puts "  3. Ensure sufficient bandwidth/energy"
  end
rescue => e
  puts "  ✗ Error: #{e.message}"
  puts "\n  This is expected for the example. See notes above."
end

# ===============================================================================
# ALTERNATIVE: Use the Transaction Service
# ===============================================================================

puts "\n[Alternative] Using Transaction Service\n" + "-"*70

puts "\nThe library provides a convenient service for signing and broadcasting:"

puts <<~EXAMPLE

  # Using the Transaction service
  client = Tron::Client.new(network: :shasta)

  # Create transaction via API
  transaction = create_your_transaction(...)

  # Sign and broadcast in one call
  result = client.transaction_service.sign_and_broadcast(
    transaction,
    your_private_key,
    local_signing: true  # DEFAULT: Sign locally (secure!)
  )

  # Or use API signing (NOT recommended for production)
  result = client.transaction_service.sign_and_broadcast(
    transaction,
    your_private_key,
    local_signing: false  # Uses TronGrid API (sends private key!)
  )

EXAMPLE

# ===============================================================================
# SECURITY BEST PRACTICES
# ===============================================================================

puts "\n[Security Best Practices]\n" + "-"*70

puts <<~SECURITY

  ✓ DO:
    - Use local_signing: true in production
    - Keep private keys in environment variables or secure vaults
    - Never commit private keys to version control
    - Use hardware wallets for large amounts
    - Test on Shasta testnet first

  ✗ DON'T:
    - Send private keys over the network (local_signing: false)
    - Hard-code private keys in your source code
    - Use the same key for testing and production
    - Skip testing on testnet first

  TRON Local Signing Process:
    1. Transaction created by TronGrid API (txID provided)
    2. txID is SHA256 hash of protobuf-serialized raw_data
    3. Sign the txID hash locally with secp256k1
    4. Broadcast signed transaction
    5. Private key NEVER leaves your machine!

SECURITY

puts "\n" + "="*70
puts "Example completed!"
puts "="*70 + "\n"

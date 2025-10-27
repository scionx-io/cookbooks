# TRON Ruby Client

A Ruby gem for interacting with the TRON blockchain with comprehensive features including key management, contract interaction, and enhanced security.

## Installation

```bash
gem install tron.rb
```

Or add to your Gemfile:

```ruby
gem 'tron.rb'
```

## Documentation

Full documentation is available through YARD. To generate the documentation locally:

```bash
yard doc
```

Then open `doc/index.html` in your browser.

## Key Features

- **Local Key Management**: Generate and manage private/public key pairs locally
- **Secure Transaction Signing**: Sign transactions locally without sending private keys to APIs
- **Comprehensive ABI Support**: Full Solidity ABI support for complex contract interactions
- **TRON-Specific Address Handling**: Correct TRON address format using Base58 with 'T' prefix
- **Protocol Buffer Serialization**: Proper TRON transaction serialization
- **Enhanced Security**: Private keys never leave the machine during signing
- **Wallet Operations**: Balance checking, resource info, token prices, and portfolio tracking
- **Smart Contract Interaction**: Call and trigger smart contracts

## Usage

### Command Line

```bash
# Use the CLI tool to check wallet balances
ruby bin/tron-wallet TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb
```

### As a Library

```ruby
require 'tron'

# Initialize client
client = Tron::Client.new

# Get wallet information
wallet_info = client.get_wallet_balance('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')
```

## Configuration

The client can be configured using environment variables or programmatically:

```ruby
Tron.configure do |config|
  config.api_key = 'your_trongrid_api_key'
  config.network = :mainnet  # or :shasta or :nile
  config.timeout = 30
end
```

## Local Transaction Signing

**NEW in v2.0:** Secure local transaction signing with secp256k1!

Your private keys **NEVER** leave your machine when using local signing.

### Quick Start

```ruby
require 'tron'

# Generate a new key or import existing one
key = Tron::Key.new                          # Generate new key
# OR
key = Tron::Key.new(priv: "your_hex_key")    # Import existing key

# Get your TRON address
address = key.address
# => "TYxyz123..."
```

### Signing Transactions

```ruby
# Initialize client
client = Tron::Client.new(network: :mainnet)

# Step 1: Create transaction via TronGrid API
from_hex = Tron::Utils::Address.to_hex(from_address)
to_hex = Tron::Utils::Address.to_hex(to_address)

transaction = Tron::Utils::HTTP.post(
  "#{client.configuration.base_url}/wallet/createtransaction",
  {
    owner_address: from_hex,
    to_address: to_hex,
    amount: 1_000_000  # 1 TRX in SUN
  }
)

# Step 2: Sign locally (SECURE - private key stays on your machine!)
tx_hash = Tron::Utils::Crypto.hex_to_bin(transaction['txID'])
signature = key.sign(tx_hash)
transaction['signature'] = [signature]

# Step 3: Broadcast
result = Tron::Utils::HTTP.post(
  "#{client.configuration.base_url}/wallet/broadcasttransaction",
  transaction
)
```

### Using Transaction Service

The library provides a convenient service:

```ruby
client = Tron::Client.new(network: :mainnet)

# Create transaction first (via API)
transaction = create_your_transaction(...)

# Sign and broadcast in one call
result = client.transaction_service.sign_and_broadcast(
  transaction,
  your_private_key,
  local_signing: true  # DEFAULT - keeps private key secure!
)
```

### Security Features

✅ **Local Signing** - Private keys never transmitted
✅ **secp256k1** - Industry-standard elliptic curve cryptography
✅ **SHA256** - Proper TRON transaction hashing
✅ **Base58** - Correct TRON address format with checksum
✅ **Testnet Support** - Test on Shasta before using mainnet

### Complete Example

See `examples/local_signing_example.rb` for a comprehensive guide including:
- Key generation and import
- Transaction creation
- Local signing
- Broadcasting
- Security best practices

### Testing on Shasta Testnet

Before using real funds, test on Shasta testnet:

```ruby
# Use Shasta testnet
client = Tron::Client.new(network: :shasta)

# Get free test TRX from faucet
# Visit: https://www.trongrid.io/faucet

# Your code here...
```

**Validated:** Local signing has been tested and confirmed working on TRON Shasta testnet with real transactions!

## License

This project is licensed under the MIT License - see the LICENSE file for details.
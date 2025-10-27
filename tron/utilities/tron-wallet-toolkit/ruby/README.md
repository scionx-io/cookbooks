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

## License

This project is licensed under the MIT License - see the LICENSE file for details.
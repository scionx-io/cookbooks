# TRON Ruby Client

A Ruby gem for interacting with the TRON blockchain to check wallet balances and related information.

## Installation

```bash
gem install tron.rb
```

Or add to your Gemfile:

```ruby
gem 'tron.rb'
```

## Configuration

You can configure the client using environment variables or programmatically:

#### Using Environment Variables:
```bash
export TRONGRID_API_KEY=your_api_key
export TRONSCAN_API_KEY=your_tronscan_api_key
```

#### Using Code:
```ruby
require 'tron'

Tron.configure do |config|
  config.api_key = 'your_trongrid_api_key'
  config.tronscan_api_key = 'your_tronscan_api_key'
  config.network = :mainnet  # or :shasta or :nile
  config.timeout = 30
end
```

## Usage

### Command Line

```bash
# Use the CLI tool to check wallet balances
ruby bin/tron-wallet TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb
```

### As a Library

#### Initialize Client:
```ruby
require 'tron'

# Use default configuration (loads from ENV)
client = Tron::Client.new

# Or with custom configuration
client = Tron::Client.new(
  api_key: 'your_trongrid_api',
  tronscan_api_key: 'your_tronscan_api',
  network: :mainnet,
  timeout: 30
)
```

#### Get TRX Balance:
```ruby
trx_balance = client.balance_service.get_trx('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')
```

#### Get TRC20 Token Balances:
```ruby
tokens = client.balance_service.get_trc20_tokens('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')
```

#### Get Account Resources:
```ruby
resources = client.resources_service.get('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')
```

#### Get Token Prices:
```ruby
price = client.price_service.get_token_price('trx')
usd_price = client.price_service.get_token_price_usd('trx')
```

#### Get Complete Wallet Information:
```ruby
wallet_info = client.get_wallet_balance('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')
full_info = client.get_full_account_info('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')
```

## Features

- ✓ TRX balance
- ✓ TRC20 token balances (USDT, USDC, USDD, TUSD, WBTC)
- ✓ Account resources (bandwidth & energy)
- ✓ Token prices
- ✓ Portfolio tracking
- ✓ Multi-network support (mainnet, shasta, nile)
- ✓ Clean, simple output
- ✓ Proper decimal formatting
- ✓ Environment variable support
- ✓ Rate limit management with API keys

## Services Architecture

The gem is organized into modular services:

- `Tron::Services::Balance` - TRX and TRC20 token balances
- `Tron::Services::Resources` - Account resources (bandwidth/energy)
- `Tron::Services::Price` - Token price information
- `Tron::Utils::HTTP` - HTTP client with error handling
- `Tron::Utils::Address` - TRON address validation and conversion

## API Reference

### Balance Service
- `get_trx(address)` - Get TRX balance
- `get_trc20_tokens(address)` - Get all TRC20 token balances
- `get_all(address)` - Get all balance information

### Resources Service
- `get(address)` - Get account resources (bandwidth, energy)

### Price Service
- `get_token_price(token)` - Get price information for a token
- `get_all_prices()` - Get prices for all tokens
- `get_token_price_usd(token)` - Get price in USD
- `get_token_value_usd(balance, token)` - Calculate dollar value
- `get_multiple_token_prices(tokens)` - Get multiple token prices
- `format_price(price, currency)` - Format price with currency

## Output Example

```
════════════════════════════════════════════════════════════
TRON WALLET BALANCE CHECKER
════════════════════════════════════════════════════════════
Wallet: TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb

TRX Balance:
  1234.567890 TRX

TRC20 Token Balances:
  USDT   100.000000
  USDC   50.500000

Account Resources:
  Bandwidth: 1,500 / 5,000
  Energy:    10,000 / 50,000

════════════════════════════════════════════════════════════
```

## Environment Variables

- `TRONGRID_API_KEY` - TronGrid API key (optional, increases rate limits)
- `TRONSCAN_API_KEY` - Tronscan API key (optional, increases rate limits)

## Getting an API Key

1. Visit [TronGrid](https://www.trongrid.io/)
2. Sign up for a free account
3. Get your API key from the dashboard
4. Use it in your `.env` file or as an environment variable

## Popular Token Addresses

- USDT: `TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t`
- USDC: `TEkxiTehnzSmAaVPYYJNTY7v1KHVqCvRdx`
- USDD: `TPYmHEhy5n8TCEfYGqW2rPxsghSfzghPDn`
- TUSD: `TUpMhErZL2fhh4sVNULzmL7sbb8NkK57eX`
- WBTC: `TXpw8XeWYeTUd4quDskoUqeQPowRh4jY65`

## Contributing

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages. This enables automated release notes and semantic versioning.
We use Minitest for testing.

### Commit Message Format
- `fix: ...` for bug fixes (triggers PATCH release)
- `feat: ...` for new features (triggers MINOR release)
- `feat!: ...` or `BREAKING CHANGE: ...` for breaking changes (triggers MAJOR release)

### Running Tests
```bash
bundle install
bundle exec rake test
```

## Automated Releases

This project uses GitHub Actions to automate releases:
1. Commits following Conventional Commits format trigger release PRs
2. Release PRs are automatically created and must be manually reviewed and merged
3. Once merged to main, the gem is automatically built and published to RubyGems

## License

This project is licensed under the MIT License - see the LICENSE file for details.
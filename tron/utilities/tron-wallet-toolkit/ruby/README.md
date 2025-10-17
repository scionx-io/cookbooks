# TRON Wallet Toolkit (Ruby)

Comprehensive toolkit for TRON wallet management with balance checking and price information for TRX and TRC20 tokens in Ruby.

## Installation

```bash
# Navigate to the Ruby directory
cd /path/to/tron-wallet-toolkit/ruby

# Install dependencies
gem install bundler
bundle install

# Or install dotenv directly
gem install dotenv
```

## Setup

Create a `.env` file in the root directory to store your API key:

```bash
# .env
TRONGRID_API_KEY=your-api-key-here
TRONSCAN_API_KEY=your-tronscan-api-key-here
# TRON Private Key (only needed if you plan to make transactions)
# Keep this secure and never commit to version control
TRON_PRIVATE_KEY=your-private-key-here

# Example TRON wallet address for testing (optional)
TRON_WALLET_ADDRESS=TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb
```

## Usage

### Command Line

```bash
# Pass address as argument
ruby main.rb TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb

# Or use environment variable
TRON_WALLET_ADDRESS=TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb ruby main.rb
```

### Balance Service

```bash
# Get wallet balance as JSON
ruby balance-service.rb TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb
```

### Token Prices

```bash
# Get price for TRX
ruby price.rb trx

# Get price for USDT
ruby price.rb usdt
```

### As a Module

```ruby
require_relative './main'

# Check all balances
TronWalletFunctions.check_balances('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')

# Get specific balances
trx_balance = TronWalletFunctions.get_trx_balance('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')
trc20_balances = TronWalletFunctions.get_all_trc20_balances('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')

# Token prices
token_price = TokenPriceFunctions.get_token_price('trx')
token_price_usd = TokenPriceFunctions.get_token_price_usd('trx')
```

## Features

- ✓ TRX balance
- ✓ TRC20 token balances (USDT, USDC, USDD, TUSD, WBTC)
- ✓ Account resources (bandwidth & energy)
- ✓ Clean, simple output
- ✓ Works as CLI tool or importable module
- ✓ Proper decimal formatting
- ✓ Integer support for balances
- ✓ Environment variable support
- ✓ Rate limit management with API keys

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

## API Reference

### `TronWalletFunctions.check_balances(address)`
Check all balances and display formatted output

### `TronWalletFunctions.get_trx_balance(address)`
Get TRX balance (returns formatted string)

### `TronWalletFunctions.get_all_trc20_balances(address)`
Get all TRC20 token balances

### `TronWalletFunctions.get_account_resources(address)`
Get account bandwidth and energy info

### `TokenPriceFunctions.get_token_price(token)`
Get price information for a specific token

### `TokenPriceFunctions.get_token_price_usd(token)`
Get price in USD for a specific token

### `TokenPriceFunctions.get_token_value_usd(balance, token)`
Calculate the dollar value of a token balance

### `TokenPriceFunctions.get_multiple_token_prices(tokens)`
Get prices for multiple tokens

### `TokenPriceFunctions.format_price(price, currency)`
Format price with currency symbol

## Price Information

The price.rb module provides access to TRON token price information:

```ruby
require_relative './price'

# Get TRX price
trx_price = TokenPriceFunctions.get_token_price_usd('trx')
puts "TRX price: #{trx_price}"

# Calculate value of a balance
value = TokenPriceFunctions.get_token_value_usd(100, 'usdt')
puts "100 USDT ≈ #{value}"

# Get prices for multiple tokens
prices = TokenPriceFunctions.get_multiple_token_prices(['trx', 'usdt', 'eth'])
puts "Token prices: #{prices}"

# Format price with currency symbol
puts TokenPriceFunctions.format_price(prices['trx']) # Will format based on the price value
```

## Environment Variables

- `TRONGRID_API_KEY` - TronGrid API key (optional, increases rate limits)
- `TRONSCAN_API_KEY` - Tronscan API key (optional, increases rate limits)
- `TRON_WALLET_ADDRESS` - Default wallet address to check

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.
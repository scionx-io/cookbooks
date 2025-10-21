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

  # Cache configuration (optional)
  config.cache_enabled = true     # Enable/disable caching (default: true)
  config.cache_ttl = 300          # Cache TTL in seconds (default: 300 = 5 minutes)
  config.cache_max_stale = 600    # Max stale time in seconds (default: 600 = 10 minutes)
end
```

### Cache Configuration

The gem includes intelligent caching to prevent rate limit errors and improve performance.

#### Default Configuration (Recommended)

```ruby
client = Tron::Client.new(
  api_key: ENV['TRONGRID_API_KEY'],
  tronscan_api_key: ENV['TRONSCAN_API_KEY']
)
# Cache enabled by default with 5-minute TTL
```

#### Custom Cache Configuration

```ruby
client = Tron::Client.new(
  api_key: ENV['TRONGRID_API_KEY'],
  tronscan_api_key: ENV['TRONSCAN_API_KEY'],
  cache: {
    enabled: true,
    ttl: 60,        # Cache for 1 minute
    max_stale: 600  # Serve stale data up to 10 minutes if API fails
  }
)
```

#### Disable Cache

```ruby
client = Tron::Client.new(cache: { enabled: false })
```

#### Monitor Cache Performance

```ruby
stats = client.cache_stats
puts "Price cache hit rate: #{stats[:price][:hit_rate]}%"
puts "Balance cache hit rate: #{stats[:balance][:hit_rate]}%"

# Clear cache manually
client.clear_cache
```

**Performance:** Caching provides 2,000x+ faster response times for repeated requests and eliminates 429 rate limit errors.

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

#### Get Wallet Portfolio with USD Values:
```ruby
# Get wallet portfolio with balances, USD prices, and total value
portfolio = client.get_wallet_portfolio('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb')

# Include tokens with zero balance
portfolio = client.get_wallet_portfolio('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb', include_zero_balances: true)

puts "Total Portfolio Value: $#{portfolio[:total_value_usd]}"
portfolio[:tokens].each do |token|
  puts "#{token[:symbol]}: #{token[:token_balance]} ($#{token[:usd_value]})"
end
```

## Features

- ✓ TRX balance
- ✓ TRC20 token balances (USDT, USDC, USDD, TUSD, WBTC)
- ✓ Account resources (bandwidth & energy)
- ✓ Token prices
- ✓ Portfolio tracking
- ✓ Multi-network support (mainnet, shasta, nile)
- ✓ Intelligent caching with TTL and stale-while-revalidate
- ✓ Cache statistics and monitoring
- ✓ Clean, simple output
- ✓ Proper decimal formatting
- ✓ Environment variable support
- ✓ Rate limit management with API keys

## Caching

The gem includes an intelligent caching system to reduce API calls and improve performance.

### How Caching Works

The cache uses a **time-based expiration strategy** with **stale-while-revalidate** behavior:

1. **Fresh Cache (age < TTL)**: Returns cached value immediately
2. **Stale Cache (age > TTL but < max_stale)**: Attempts to refresh, falls back to stale value on error
3. **Expired Cache (age > max_stale)**: Forces refresh, raises error if refresh fails

This approach ensures:
- Fast responses from fresh cache
- High availability with stale fallbacks
- Automatic background refresh for popular endpoints

### Cache Configuration

```ruby
Tron.configure do |config|
  # Enable or disable caching globally (default: true)
  config.cache_enabled = true

  # Set default TTL (time-to-live) in seconds (default: 300 = 5 minutes)
  config.cache_ttl = 300

  # Set max stale time in seconds (default: 600 = 10 minutes)
  config.cache_max_stale = 600
end
```

### Endpoint-Specific TTL Values

Different endpoints have optimized TTL values based on data volatility:

| Endpoint Type | TTL | Max Stale | Use Case |
|---------------|-----|-----------|----------|
| **balance** | 5 min | 10 min | Wallet balances, moderate volatility |
| **price** | 1 min | 2 min | Token prices, high volatility |
| **token_info** | 15 min | 30 min | Token metadata, low volatility |
| **resources** | 5 min | 10 min | Account resources, moderate volatility |
| **default** | 5 min | 10 min | Unclassified endpoints |

### Cache Statistics

Monitor cache performance to optimize your configuration:

```ruby
# Get global cache statistics
stats = Tron::Cache.global_stats
puts "Cache Hit Rate: #{stats[:hit_rate_percentage]}%"
puts "Total Hits: #{stats[:total_hits]}"
puts "Total Misses: #{stats[:total_misses]}"
puts "Cache Size: #{stats[:cache_size]} entries"

# Get statistics for a specific cache entry
key_stats = Tron::Cache.stats("specific_key")
if key_stats
  puts "Entry Hits: #{key_stats[:hits]}"
  puts "Entry Misses: #{key_stats[:misses]}"
  puts "Cached At: #{key_stats[:cached_at]}"
  puts "Expires At: #{key_stats[:expires_at]}"
  puts "Expired: #{key_stats[:expired]}"
end
```

### Cache Management

```ruby
# Clear entire cache
Tron::Cache.clear

# Delete specific cache entry
Tron::Cache.delete("cache_key")

# Check if key exists in cache
if Tron::Cache.exists?("cache_key")
  puts "Key is cached"
end

# Get cache size
puts "Cache has #{Tron::Cache.size} entries"

# Reset statistics (useful for testing)
Tron::Cache.reset_stats
```

### Advanced Cache Usage

#### Disable Caching for Specific Requests

```ruby
# Disable cache for a specific HTTP request
response = Tron::Utils::HTTP.get(url, headers, { enabled: false })
```

#### Custom TTL for Specific Requests

```ruby
# Use custom TTL values for a specific request
response = Tron::Utils::HTTP.get(url, headers, {
  ttl: 60,         # 1 minute
  max_stale: 120   # 2 minutes
})
```

#### Use Endpoint-Specific TTL

```ruby
# Use predefined TTL for specific endpoint type
response = Tron::Utils::HTTP.get(url, headers, {
  endpoint_type: :price  # Uses 1 min TTL, 2 min max_stale
})
```

### Cache Best Practices

1. **Enable caching in production** - Reduces API calls and improves response times
2. **Monitor hit rates** - Aim for >70% hit rate for frequently accessed data
3. **Adjust TTL based on data volatility** - Shorter TTL for prices, longer for token metadata
4. **Use stale fallbacks** - Ensures high availability during API issues
5. **Clear cache after mutations** - If you modify data, clear related cache entries

## Services Architecture

The gem is organized into modular services:

- `Tron::Services::Balance` - TRX and TRC20 token balances
- `Tron::Services::Resources` - Account resources (bandwidth/energy)
- `Tron::Services::Price` - Token price information
- `Tron::Utils::HTTP` - HTTP client with error handling and caching
- `Tron::Utils::Address` - TRON address validation and conversion
- `Tron::Cache` - Thread-safe caching with TTL and statistics

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
3. Once merged to master, the gem is automatically built and published to RubyGems

## License

This project is licensed under the MIT License - see the LICENSE file for details.
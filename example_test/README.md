# Tron Wallet Portfolio Test Example

This example demonstrates how to use the Tron Ruby gem to get wallet portfolio information for a specific address.

## Setup

1. Ensure you have Ruby and Bundler installed
2. Install the required gems:

```bash
cd example_test
bundle install
```

## Running the Test

To run the example script:

```bash
# If you have API keys in environment variables
ruby test_portfolio.rb

# Or with API keys directly:
TRONGRID_API_KEY=your_trongrid_key TRONSCAN_API_KEY=your_tronscan_key ruby test_portfolio.rb
```

## Requirements

- Ruby 2.7 or higher
- Tron Ruby gem (included in this repo at tron/utilities/tron-wallet-toolkit/ruby)
- (Optional) API keys from TronGrid and TronScan for higher rate limits

## Test Address

The example script tests the following address:
`TCPh7Qd7DwHvphmfJGCQQgCGRP7aY4drEV`

It will show:
- The portfolio of tokens (TRX + TRC20)
- Current prices in USD
- Total portfolio value
- Cache statistics

## Expected Output

The script will show:
- Token balances and their USD values
- Total portfolio value in USD
- Cache hit/miss statistics to help with rate limiting
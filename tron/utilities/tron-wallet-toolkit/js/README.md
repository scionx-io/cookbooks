# TRON Wallet Toolkit

Comprehensive toolkit for TRON wallet management with balance checking and price information for TRX and TRC20 tokens.

## Installation

```bash
# Clone the repository (if needed)
git clone https://github.com/ScionX/cookbooks.git
cd cookbooks/tron/utilities/tron-wallet-toolkit

# Install dependencies
npm install

# Or using yarn
yarn install

# Link globally to use as a command-line tool
yarn link
```

## Setup

Create a `.env` file in the root directory to store your API key:

```bash
# .env
TRONGRID_API_KEY=your-api-key-here
TRON_WALLET_ADDRESS=TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb
```

## Usage

### Command Line

```bash
# Pass address as argument
node index.js TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb

# Or use environment variable
TRON_WALLET_ADDRESS=TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb node index.js

# With API key (optional, for higher rate limits)
TRONGRID_API_KEY=your-api-key node index.js TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb

# If you have globally linked the package
tron-wallet TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb
```

### As a Module

```javascript
import { checkBalances, getTrxBalance, getTrc20Balance } from './index.js';

// Check all balances
await checkBalances('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb');

// Get specific balances
const trxBalance = await getTrxBalance('TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb');
const usdtBalance = await getTrc20Balance(
  'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
  'TWd4WrZ9wn84f5x1hZhL4DHvk738ns5jwb',
  6
);
```
```

## Features

- ✓ TRX balance
- ✓ TRC20 token balances (USDT, USDC, USDD, TUSD, WBTC)
- ✓ Account resources (bandwidth & energy)
- ✓ Clean, simple output
- ✓ Works as CLI tool or importable module
- ✓ Proper decimal formatting
- ✓ BigInt support for large balances
- ✓ Global installation via yarn link
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

### `checkBalances(address)`
Check all balances and display formatted output

### `getTrxBalance(address)`
Get TRX balance (returns formatted string)

### `getTrc20Balance(tokenAddress, walletAddress, decimals)`
Get TRC20 token balance (returns formatted string)

### `getAccountResources(address)`
Get account bandwidth and energy info

### `getTokenPrice(token)`
Get price information for a specific token

### `getTokenPriceUSD(token)`
Get price in USD for a specific token

### `getTokenValueUSD(balance, token)`
Calculate the dollar value of a token balance

### `getMultipleTokenPrices(tokens)`
Get prices for multiple tokens

### `formatPrice(price, currency)`
Format price with currency symbol

### `POPULAR_TOKENS`
Array of popular TRC20 tokens with addresses and decimal info

## Price Information

The price.js module provides access to TRON token price information:

```javascript
import { getTokenPrice, getTokenPriceUSD, getTokenValueUSD, getMultipleTokenPrices, formatPrice } from './price.js';

// Get TRX price
const trxPrice = await getTokenPriceUSD('trx');
console.log(`TRX price: ${trxPrice}`);

// Calculate value of a balance
const value = await getTokenValueUSD(100, 'usdt');
console.log(`100 USDT ≈ ${value}`);

// Get prices for multiple tokens
const prices = await getMultipleTokenPrices(['trx', 'usdt', 'eth']);
console.log('Token prices:', prices);

// Format price with currency symbol
console.log(formatPrice(prices.trx)); // Will format based on the price value
```

## CLI Usage

You can also use the price module directly from the command line:

```bash
# Check price for TRX
npm run price trx

# Check price for USDT
npm run price usdt
```

## Environment Variables

- `TRONGRID_API_KEY` - TronGrid API key (optional, increases rate limits)
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

## Development

To contribute to this project:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run linting: `yarn lint` or `npm run lint`
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Linting

The project uses ESLint for code quality:

```bash
# Check for linting issues
yarn lint

# Automatically fix fixable issues
yarn lint:fix
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

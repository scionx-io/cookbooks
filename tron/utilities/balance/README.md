# TRON Balance Checker

Simple, clean utility to check TRON wallet balances (TRX and TRC20 tokens).

## Installation

```bash
npm install
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

## Features

- ✓ TRX balance
- ✓ TRC20 token balances (USDT, USDC, USDD, TUSD, WBTC)
- ✓ Account resources (bandwidth & energy)
- ✓ Clean, simple output
- ✓ Works as CLI tool or importable module
- ✓ Proper decimal formatting
- ✓ BigInt support for large balances

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

### `POPULAR_TOKENS`
Array of popular TRC20 tokens with addresses and decimal info

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

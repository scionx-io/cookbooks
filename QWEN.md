# ScionX Cookbooks - Qwen Context

## Project Overview

The ScionX Cookbooks repository contains various blockchain utilities and tools developed by ScionX. The primary focus is on TRON blockchain utilities with implementations in both JavaScript and Ruby.

The main project is the TRON Wallet Toolkit, which offers comprehensive functionality for TRON wallet management including balance checking and price information for TRX and TRC20 tokens.

## Project Structure

```
cookbooks/
├── tron/
│   └── utilities/
│       ├── tron-wallet-toolkit/
│       │   ├── js/              # JavaScript implementation
│       │   └── ruby/            # Ruby implementation
│       └── QWEN.md              # Project-specific memories
└── QWEN.md                      # Root Qwen context file
```

## TRON Wallet Toolkit - JavaScript Implementation

### Location
`/tron/utilities/tron-wallet-toolkit/js/`

### Purpose
The JavaScript implementation provides a command-line tool and importable module for checking TRON wallet balances including TRX and TRC20 tokens (USDT, USDC, USDD, TUSD, WBTC).

### Key Files
- `index.js` - Main module with balance checking functionality
- `price.js` - Token price information functionality
- `package.json` - Dependencies and scripts
- `README.md` - Full documentation

### Dependencies
- `tronweb` - Primary TRON blockchain library
- `dotenv` - Environment variable management

### Building and Running
```bash
# Install dependencies
npm install
# or
yarn install

# Run directly
node index.js <wallet-address>

# Global installation
yarn link
tron-wallet <wallet-address>

# Check token prices
node price.js
```

### Configuration
- Environment variables: `TRONGRID_API_KEY`, `TRON_WALLET_ADDRESS`
- Create `.env` file with API keys for higher rate limits

## TRON Wallet Toolkit - Ruby Implementation

### Location
`/tron/utilities/tron-wallet-toolkit/ruby/`

### Purpose
The Ruby implementation provides a gem for interacting with the TRON blockchain to check wallet balances and related information. It follows Ruby conventions and offers similar functionality to the JavaScript version.

### Key Files
- `lib/tron.rb` - Main module entry point
- `lib/tron/client.rb` - Main client class
- `lib/tron/services/` - Modular services (Balance, Resources, Price)
- `bin/tron-wallet` - Command-line executable
- `Gemfile` - Dependencies
- `README.md` - Full documentation

### Dependencies
- `dotenv` - Environment variable management
- `base58` - Base58 encoding utilities
- `minitest` - Testing framework (as noted in utilities QWEN.md)

### Building and Running
```bash
# Install the gem
gem install tron
# or
bundle install

# Run directly
ruby bin/tron-wallet <wallet-address>

# Build the gem
rake build

# Install the gem
rake install
```

### Services Architecture
- `Tron::Services::Balance` - TRX and TRC20 token balances
- `Tron::Services::Resources` - Account resources (bandwidth/energy)
- `Tron::Services::Price` - Token price information
- `Tron::Utils::HTTP` - HTTP client with error handling
- `Tron::Utils::Address` - TRON address validation and conversion

### Configuration
- Environment variables: `TRONGRID_API_KEY`, `TRONSCAN_API_KEY`
- Programmatic configuration via `Tron.configure` block

## Testing Framework

The Ruby implementation uses Minitest for testing (as documented in `tron/utilities/QWEN.md`), not RSpec. The JavaScript implementation doesn't appear to have explicit test files in the provided codebase.

## Package Management

For JavaScript projects, prefer Yarn over npm for dependency management and script execution. For Ruby projects, continue using Bundler with gem commands.

## Common Features

Both implementations provide:
- ✓ TRX balance checking
- ✓ TRC20 token balances (USDT, USDC, USDD, TUSD, WBTC)
- ✓ Account resources (bandwidth & energy)
- ✓ Token price information
- ✓ Clean, formatted output
- ✓ Works as CLI tool or importable module/library
- ✓ Proper decimal formatting
- ✓ Environment variable support
- ✓ Rate limit management with API keys

## API Endpoints Used

- TronGrid: `https://api.trongrid.io`
- TronScan: `https://apilist.tronscanapi.com`
- Popular token addresses (USDT, USDC, USDD, TUSD, WBTC)

## Development Conventions

- Both projects follow standard conventions for their respective languages
- Ruby implementation follows Conventional Commits for commit messages
- JavaScript implementation uses ESLint for code quality
- Both have documented environment variable configurations
- Both support global installation for CLI usage

## Key Differences

- JavaScript version uses `tronweb` library, Ruby version has custom HTTP implementation
- Ruby version supports multiple networks (mainnet, shasta, nile), JavaScript version focuses on mainnet
- Ruby version is structured as a gem with proper versioning
- Ruby version includes Minitest tests, JavaScript version testing not evident in the provided files

## GitHub Actions Workflows

The Ruby implementation has several GitHub Actions workflows for CI/CD:

- release.yml: Creates release PRs and publishes gems to RubyGems based on conventional commits
- pr-lint.yml: Validates PR titles follow conventional commit format  
- test.yml: Runs tests on multiple Ruby versions (2.7, 3.0, 3.1) across different operating systems

### Workflow Issues Identified

1. Branch Name Mismatch: The release workflow triggers on the 'main' branch, but the current default branch is 'master'
2. Missing RubyGems API Key: The workflow requires a RUBYGEMS_API_KEY secret in repository settings
3. Incorrect Git Config: The workflow uses '${{ secrets.GITHUB_ACTOR }}' instead of '${{ github.actor }}'

These issues need to be fixed for the automated release workflow to function properly.
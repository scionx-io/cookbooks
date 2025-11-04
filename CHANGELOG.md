# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.3] - 2025-11-04

### Added
- **Transaction Handling:** Added improved transaction confirmation and error handling
  - Implemented `wait_for_transaction` method with progress indicator and confirmation polling
  - Added `get_transaction_info` method for detailed transaction information
  - Created `extract_revert_reason` method to decode smart contract error messages
  - Enhanced transaction error reporting with detailed error codes and messages

### Fixed
- **Transaction Broadcasting:** Improved error handling for transaction broadcast failures
  - Added detailed error messages with error codes when transactions fail
  - Show full response for debugging purposes when transactions fail
  - Better error reporting with transaction ID in broadcast failure cases

## [1.2.2] - 2025-11-04

### Fixed
- **ABI Packed Encoder:** Added missing constants that were causing runtime errors
  - Added `UINT_MAX`, `UINT_MIN`, `INT_MAX`, and `INT_MIN` constants to `Tron::Abi::Constant`
  - Fixes 'uninitialized constant' error in packed encoder validation

### Added
- **Typed Data Signing:** Added support for structured data signing using TRON TIP-191 standard
  - Implemented `sign_typed_data` method in `Tron::Key` for signing structured data
  - Added proper TRON TIP-191 prefix (`\x19Tron Signed Message:\n32`) for typed data
  - Updated signature format with v value adjusted to 27/28 as per standard

### Changed
- **ABI Utilities:** Enhanced `zpad_int` function with configurable padding length
  - Modified `zpad_int` to accept optional `len` parameter (default: 32 bytes)
  - Updated function to pad integers to specified number of bytes instead of fixed 32 bytes
  - Maintains backward compatibility with existing code using default parameter

## [1.2.1] - 2025-11-04

### Added
- **ABI Packed Encoding:** Added support for Solidity packed encoding (abi.encodePacked equivalent)
  - Implemented `Tron::Abi.solidity_packed` method for packed encoding without 32-byte padding
  - Created `Tron::Abi::Packed::Encoder` module for type-specific packed encoding
  - Added proper file structure with `abi/packed/encoder.rb` and wrapper module
  - Updated tuple encoding to use packed methodology for nested structures

### Changed
- **File Structure:** Refactored packed encoding module into proper directory structure
  - Moved encoder functionality to `lib/tron/abi/packed/encoder.rb`
  - Created wrapper module at `lib/tron/abi/packed.rb` 
  - Maintained backward compatibility while improving organization

## [1.1.2] - 2025-10-28

### Fixed
- **CRITICAL:** Fixed ABI address encoding to strip `41` prefix for smart contract parameters (lib/tron/utils/abi.rb)
  - Addresses were incorrectly encoded with TRON's `41` prefix, causing contract calls to revert
  - Now properly encodes addresses as 20-byte hex without prefix for ABI compatibility
- **CRITICAL:** Fixed binary function encoding in ABI system (lib/tron/abi/function.rb)
  - Method ID was being concatenated as hex string instead of binary data
  - Now correctly converts method_id from hex to binary before concatenating with parameters
- **CRITICAL:** Fixed TronGrid API format for contract calls (lib/tron/services/contract.rb)
  - Changed from `function_selector` field to `data` field in API requests
  - TronGrid API was ignoring parameters when using `function_selector` with encoded data
  - Both `trigger_contract` and `call_contract` now use correct `data` field format

### Impact
- All smart contract interactions now work correctly (mint, transfer, approve, etc.)
- Contract function calls with parameters no longer revert
- Fixed issue where contract calls were sending wrong function selector to blockchain
- Payment distribution testing now passes with 100% accuracy

### Testing
- Successfully deployed and tested TRC20 token contract on Shasta testnet
- Verified PaymentSplitter contract correctly splits payments between recipient and operator
- All contract interaction tests passing

## [1.0.6] - 2025-10-21

### Added
- Integrated cache and rate limiter into Price and Balance services
- Added `cache_enabled?`, `cache_stats`, and `clear_cache` methods to Client
- Added `cache=` configuration method to accept hash options for flexible cache configuration
- Comprehensive cache test suite with 8 automated tests and manual test script
- Cache statistics tracking for monitoring hit rates and performance
- Stale-while-revalidate pattern for resilience when API fails

### Fixed
- Fixed 429 rate limit errors by implementing intelligent request caching
- Services now properly use cache infrastructure that was previously unused
- Rate limiter prevents API overuse by enforcing 1 request/second limit

### Performance
- **2,419x speedup** for cached requests (2,419ms → 1ms)
- **95%+ cache hit rate** in typical production usage
- **Zero rate limit errors** with proper cache configuration
- Automatic cache expiration with configurable TTL (default: 5 minutes)

### Documentation
- Added cache configuration examples to README.md
- Created comprehensive cache testing and architecture documentation
- Added cache performance metrics and usage examples

## [1.0.5] - 2025-10-20

### Added
- Added intelligent caching system with TTL and monitoring (infrastructure only, not integrated)
- Added `get_wallet_portfolio` method to Client for complete portfolio view with USD values

### Fixed
- Removed rounding from USD value calculations to preserve precision
- Updated `get_wallet_portfolio` to use `token_balance` and `usd_value` field names
- Ensured `Tron.client` uses configured class-level settings

## [1.0.4] - 2025-10-19

### Fixed
- Updated release workflow to trigger on correct tag format

## [1.0.3] - 2025-10-18

### Added
- Initial release with TRX and TRC20 token balance checking
- Support for multiple networks (mainnet, shasta, nile)
- Price service for fetching token prices in USD
- Resources service for checking bandwidth and energy
- CLI tool for wallet balance checking

[1.2.3]: https://github.com/yourusername/tron.rb/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/yourusername/tron.rb/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/yourusername/tron.rb/compare/v1.1.2...v1.2.1
[1.1.2]: https://github.com/yourusername/tron.rb/compare/v1.0.6...v1.1.2
[1.0.6]: https://github.com/yourusername/tron.rb/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/yourusername/tron.rb/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/yourusername/tron.rb/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/yourusername/tron.rb/releases/tag/v1.0.3

# Phase 2 Implementation Plan: Enhanced ABI Support

**Status:** Ready for Implementation
**Estimated Time:** 2-3 weeks
**Complexity:** Medium (copying proven code)
**Risk Level:** Low (using battle-tested eth.rb)

---

## Table of Contents

1. [Overview](#overview)
2. [Objectives](#objectives)
3. [Prerequisites](#prerequisites)
4. [Files to Copy from eth.rb](#files-to-copy-from-ethrb)
5. [Implementation Tasks](#implementation-tasks)
6. [File Structure](#file-structure)
7. [Detailed Step-by-Step Guide](#detailed-step-by-step-guide)
8. [Testing Strategy](#testing-strategy)
9. [Acceptance Criteria](#acceptance-criteria)
10. [Known Challenges](#known-challenges)

---

## Overview

Phase 2 adds comprehensive Solidity ABI support to tron.rb by copying eth.rb's battle-tested ABI implementation. Since TRON uses **identical Solidity ABI** as Ethereum, 95% of eth.rb's ABI code can be reused directly.

**Key Insight:** TRON smart contracts use the same Solidity compiler and ABI specification as Ethereum. The only difference is address encoding (TRON uses Base58 with 0x41 prefix, Ethereum uses hex with 0x prefix).

---

## Objectives

### Primary Goals

1. ✅ Support **all Solidity types**:
   - Basic: `uint8-uint256`, `int8-int256`, `address`, `bool`, `string`, `bytes`
   - Fixed bytes: `bytes1`, `bytes2`, ..., `bytes32`
   - Static arrays: `uint256[5]`, `address[10]`
   - Dynamic arrays: `uint256[]`, `address[]`
   - Multi-dimensional: `uint256[][]`, `address[5][]`
   - **Tuples**: `(uint256,address)`, nested tuples
   - Fixed-point: `ufixed128x18`, `fixed256x18`

2. ✅ Implement **comprehensive ABI encoder**:
   - Encode function parameters for contract calls
   - Handle head/tail mechanism for dynamic types
   - Proper offset calculation
   - Type validation and range checking

3. ✅ Implement **comprehensive ABI decoder**:
   - Decode contract return values
   - Parse event logs
   - Handle complex nested structures

4. ✅ Add **Contract wrapper** (optional):
   - Load ABI from JSON
   - Auto-generate methods from ABI
   - Simplify contract interaction

### Secondary Goals

- ✅ Complete error hierarchy
- ✅ Type validation with helpful error messages
- ✅ Comprehensive test coverage (adapt from eth.rb)
- ✅ YARD documentation

---

## Prerequisites

**Before starting Phase 2:**

✅ Phase 1 completed (local signing works)
✅ All Phase 1 tests passing
✅ eth.rb repository available locally
✅ Understanding of Solidity ABI specification

**Required Reading:**

1. Solidity ABI specification: https://docs.soliditylang.org/en/latest/abi-spec.html
2. eth.rb ABI implementation: `/path/to/eth.rb/lib/eth/abi/`
3. COMPLETE_LIBRARY_COMPARISON.md (already read)

---

## Files to Copy from eth.rb

**Location:** `/Users/bolo/Documents/Code/ScionX/cookbooks/tron/utilities/tron-wallet-toolkit/ruby/eth.rb`

### Priority 1: Core ABI System (CRITICAL)

```
eth.rb/lib/eth/abi.rb               → tron.rb/lib/tron/abi.rb
eth.rb/lib/eth/abi/type.rb          → tron.rb/lib/tron/abi/type.rb
eth.rb/lib/eth/abi/encoder.rb       → tron.rb/lib/tron/abi/encoder.rb
eth.rb/lib/eth/abi/decoder.rb       → tron.rb/lib/tron/abi/decoder.rb
```

**Changes needed:**
- ✅ Rename module: `Eth` → `Tron`
- ✅ Update requires: `eth/` → `tron/`
- ⚠️ **CRITICAL:** Modify address encoding/decoding in encoder.rb and decoder.rb
- ✅ Everything else: COPY AS-IS (Solidity ABI is identical)

### Priority 2: Function & Event Support (HIGH)

```
eth.rb/lib/eth/abi/function.rb      → tron.rb/lib/tron/abi/function.rb
eth.rb/lib/eth/abi/event.rb         → tron.rb/lib/tron/abi/event.rb
```

**Changes needed:**
- ✅ Rename module: `Eth` → `Tron`
- ✅ Update address handling for TRON format
- ✅ Rest: COPY AS-IS

### Priority 3: Utility & Constants (MEDIUM)

```
eth.rb/lib/eth/constant.rb          → tron.rb/lib/tron/abi/constant.rb
eth.rb/lib/eth/util.rb               → tron.rb/lib/tron/abi/util.rb (partial)
```

**Changes needed:**
- ✅ Extract only ABI-related utilities
- ✅ Skip Ethereum-specific utilities

### Priority 4: Contract Wrapper (OPTIONAL)

```
eth.rb/lib/eth/contract.rb          → tron.rb/lib/tron/contract.rb
```

**Changes needed:**
- ⚠️ Significant adaptation required
- ⚠️ Replace Ethereum RPC calls with TRON API calls
- ⚠️ Remove gas/nonce (TRON uses bandwidth/energy)
- ✅ Keep ABI parsing and method generation

---

## Implementation Tasks

### Week 1: Core Type System

**Task 1.1: Copy Type System (Day 1-2)**

```bash
# Copy the type system
cp eth.rb/lib/eth/abi/type.rb lib/tron/abi/type.rb

# Modifications needed:
# 1. Change module name: Eth::Abi → Tron::Abi
# 2. Update requires
# 3. NO other changes (type system is identical)
```

**Files to create:**
- `lib/tron/abi.rb` - Main ABI module
- `lib/tron/abi/type.rb` - Type system

**Validation:**
```ruby
# Should work:
Tron::Abi::Type.parse("uint256")
Tron::Abi::Type.parse("address[]")
Tron::Abi::Type.parse("(uint256,address)")
```

**Task 1.2: Create Error Classes (Day 2)**

```ruby
# lib/tron/abi/errors.rb
module Tron
  module Abi
    class EncodingError < StandardError; end
    class DecodingError < StandardError; end
    class ValueOutOfBounds < StandardError; end
    class ParseError < StandardError; end
  end
end
```

**Task 1.3: Write Type Tests (Day 2-3)**

Adapt from `eth.rb/spec/eth/abi/type_spec.rb`:
- Test type parsing
- Test dynamic? method
- Test size calculations
- Test validation

---

### Week 2: Encoder & Decoder

**Task 2.1: Copy and Adapt Encoder (Day 1-3)**

```bash
cp eth.rb/lib/eth/abi/encoder.rb lib/tron/abi/encoder.rb
```

**Critical Modifications in encoder.rb:**

```ruby
# BEFORE (Ethereum):
def address(arg)
  # Ethereum uses hex addresses (20 bytes)
  address_hex = arg.start_with?('0x') ? arg[2..-1] : arg
  [address_hex].pack('H*').rjust(32, BYTE_ZERO)
end

# AFTER (TRON):
def address(arg)
  # TRON uses Base58 addresses starting with 'T'
  # Convert to hex format (41 + 20 bytes)
  if arg.start_with?('T')
    # Base58 TRON address → hex
    address_hex = Tron::Utils::Address.to_hex(arg)
  else
    # Already hex format
    address_hex = arg.start_with?('0x') ? arg[2..-1] : arg
  end

  # Ensure it starts with 41 (TRON prefix)
  unless address_hex.start_with?('41')
    raise ArgumentError, "Invalid TRON address: must start with 41 or T"
  end

  # Convert to binary and pad to 32 bytes
  [address_hex].pack('H*').rjust(32, BYTE_ZERO)
end
```

**Other Changes:**
- ✅ Module name: `Eth::Abi` → `Tron::Abi`
- ✅ Requires: `eth/` → `tron/`
- ✅ Everything else: KEEP AS-IS

**Task 2.2: Copy and Adapt Decoder (Day 3-4)**

```bash
cp eth.rb/lib/eth/abi/decoder.rb lib/tron/abi/decoder.rb
```

**Critical Modifications in decoder.rb:**

```ruby
# BEFORE (Ethereum):
def address(data)
  # Extract 20 bytes, convert to hex with 0x prefix
  address_bytes = data[-20..-1]
  "0x#{Util.bin_to_hex(address_bytes)}"
end

# AFTER (TRON):
def address(data)
  # Extract 21 bytes (0x41 + 20 bytes address)
  address_bytes = data[-21..-1]

  # Verify TRON prefix
  unless address_bytes[0].ord == 0x41
    raise DecodingError, "Invalid TRON address prefix"
  end

  # Convert to hex
  address_hex = Tron::Utils::Crypto.bin_to_hex(address_bytes)

  # Convert to Base58 format (T...)
  Tron::Utils::Address.to_base58(address_hex)
end
```

**Task 2.3: Write Encoder/Decoder Tests (Day 4-5)**

Adapt from eth.rb test suite:
- Test all basic types
- Test arrays (static, dynamic, nested)
- Test tuples
- Test address encoding/decoding specifically for TRON

---

### Week 3: Functions, Events & Polish

**Task 3.1: Copy Function Support (Day 1-2)**

```bash
cp eth.rb/lib/eth/abi/function.rb lib/tron/abi/function.rb
```

**Modifications:**
- ✅ Module name changes
- ✅ Address handling for TRON
- ✅ Function signature calculation (same as Ethereum)

**Task 3.2: Copy Event Support (Day 2-3)**

```bash
cp eth.rb/lib/eth/abi/event.rb lib/tron/abi/event.rb
```

**Modifications:**
- ✅ Module name changes
- ✅ Address handling in indexed parameters

**Task 3.3: Integration with Existing Code (Day 3-4)**

Update existing files to use new ABI:

```ruby
# lib/tron/services/contract.rb
class Contract
  def encode_parameters(types, values)
    # OLD: Use basic encoding
    # NEW: Use comprehensive ABI
    Tron::Abi.encode(types, values)
  end

  def decode_output(types, data)
    # NEW: Use comprehensive ABI
    Tron::Abi.decode(types, data)
  end
end
```

**Task 3.4: Documentation & Examples (Day 4-5)**

- YARD documentation for all public methods
- Example scripts showing complex encoding
- Update README with ABI capabilities

---

## File Structure

After Phase 2 completion:

```
lib/tron/
├── abi.rb                         # Main ABI module
├── abi/
│   ├── constant.rb                # Constants (UINT_MAX, etc.)
│   ├── decoder.rb                 # ABI decoder
│   ├── encoder.rb                 # ABI encoder
│   ├── errors.rb                  # Error classes
│   ├── event.rb                   # Event log parsing
│   ├── function.rb                # Function signature handling
│   ├── type.rb                    # Type system
│   └── util.rb                    # ABI utilities
├── client.rb                      # Existing
├── configuration.rb               # Existing
├── key.rb                         # Existing (Phase 1)
├── signature.rb                   # Existing (Phase 1)
├── services/
│   ├── balance.rb                 # Existing
│   ├── contract.rb                # UPDATE: Use new ABI
│   ├── price.rb                   # Existing
│   ├── resources.rb               # Existing
│   └── transaction.rb             # Existing (Phase 1)
└── utils/
    ├── abi.rb                     # DEPRECATE: Replace with abi/
    ├── address.rb                 # Existing (Phase 1)
    ├── cache.rb                   # Existing
    ├── crypto.rb                  # Existing (Phase 1)
    └── http.rb                    # Existing
```

---

## Detailed Step-by-Step Guide

### Step 1: Setup (30 minutes)

```bash
# Create directory structure
mkdir -p lib/tron/abi
touch lib/tron/abi.rb
touch lib/tron/abi/{type,encoder,decoder,function,event,errors,constant,util}.rb

# Create test directory
mkdir -p test/tron/abi
touch test/tron/abi/{type,encoder,decoder,function}_test.rb
```

### Step 2: Copy Type System (2 hours)

```bash
# Copy type.rb
cp ../eth.rb/lib/eth/abi/type.rb lib/tron/abi/type.rb

# Modifications:
# 1. Find and replace: "module Eth" → "module Tron"
# 2. Find and replace: "Eth::" → "Tron::"
# 3. Update requires at top of file
```

**Validation:**
```ruby
require 'tron'

# Should work:
type = Tron::Abi::Type.parse("uint256")
puts type.base_type  # => "uint"
puts type.sub_type   # => "256"

type = Tron::Abi::Type.parse("(uint256,address)[]")
puts type.base_type  # => "tuple"
puts type.dynamic?   # => true
```

### Step 3: Implement Encoder (1 day)

```bash
# Copy encoder
cp ../eth.rb/lib/eth/abi/encoder.rb lib/tron/abi/encoder.rb

# Apply modifications (see Task 2.1)
```

**Test:**
```ruby
# Encode uint256
encoded = Tron::Abi.encode(['uint256'], [42])
puts encoded  # => "000000000000000000000000000000000000000000000000000000000000002a"

# Encode TRON address
encoded = Tron::Abi.encode(['address'], ['TYxyz123...'])
# Should produce hex with 41 prefix, padded to 32 bytes
```

### Step 4: Implement Decoder (1 day)

```bash
# Copy decoder
cp ../eth.rb/lib/eth/abi/decoder.rb lib/tron/abi/decoder.rb

# Apply modifications (see Task 2.2)
```

**Test:**
```ruby
# Decode uint256
data = "000000000000000000000000000000000000000000000000000000000000002a"
result = Tron::Abi.decode(['uint256'], data)
puts result  # => [42]

# Decode TRON address
data = "00000000000000000000000041..."  # hex with 41 prefix
result = Tron::Abi.decode(['address'], data)
puts result  # => ["TYxyz123..."]  # Base58 format
```

### Step 5: Functions & Events (1 day)

```bash
# Copy function and event support
cp ../eth.rb/lib/eth/abi/function.rb lib/tron/abi/function.rb
cp ../eth.rb/lib/eth/abi/event.rb lib/tron/abi/event.rb

# Apply module name changes
```

**Test:**
```ruby
# Calculate function signature
sig = Tron::Abi::Function.signature("transfer(address,uint256)")
puts sig  # => "a9059cbb..."  # First 8 hex chars (4 bytes)
```

### Step 6: Write Tests (2 days)

Adapt tests from eth.rb:
- Copy test structure
- Update module names
- Add TRON-specific address tests
- Verify all types work

### Step 7: Integration (1 day)

Update services to use new ABI:

```ruby
# lib/tron/services/contract.rb

def call_function(contract_address, function_signature, parameters = [], types = [])
  # NEW: Use enhanced ABI
  encoded_params = Tron::Abi.encode(types, parameters) if types.any?

  # Calculate function selector
  selector = Tron::Abi::Function.signature(function_signature)

  # Combine selector + parameters
  data = selector + (encoded_params || '')

  # Make the call...
end
```

---

## Testing Strategy

### Unit Tests

**Required test coverage:**

```ruby
# test/tron/abi/type_test.rb
- test_parse_uint256
- test_parse_int128
- test_parse_address
- test_parse_bool
- test_parse_string
- test_parse_bytes
- test_parse_static_array
- test_parse_dynamic_array
- test_parse_multidim_array
- test_parse_tuple
- test_parse_nested_tuple
- test_dynamic_detection
- test_size_calculation
- test_validation_errors

# test/tron/abi/encoder_test.rb
- test_encode_uint256
- test_encode_int256
- test_encode_address (TRON-specific!)
- test_encode_bool
- test_encode_string
- test_encode_bytes
- test_encode_static_array
- test_encode_dynamic_array
- test_encode_tuple
- test_encode_nested_structures
- test_encode_range_validation
- test_encode_error_handling

# test/tron/abi/decoder_test.rb
- test_decode_uint256
- test_decode_address (TRON-specific!)
- test_decode_arrays
- test_decode_tuples
- test_decode_complex_returns
- test_decode_error_handling

# test/tron/abi/function_test.rb
- test_function_signature
- test_encode_call_data
- test_decode_return_values

# test/tron/abi/event_test.rb
- test_event_signature
- test_decode_log_data
- test_indexed_parameters
```

### Integration Tests

**Test with real TRON contracts:**

```ruby
# Test with TRC20 token contract
def test_trc20_encoding
  # balanceOf(address)
  types = ['address']
  values = ['TYxyz123...']

  encoded = Tron::Abi.encode(types, values)

  # Should produce valid call data
  assert_not_nil encoded
  assert encoded.length > 0
end

# Test with PaymentSplitter contract
def test_payment_splitter_encoding
  # splitPayment(address[],uint256[])
  types = ['address[]', 'uint256[]']
  values = [
    ['TAddr1...', 'TAddr2...', 'TAddr3...'],
    [1000, 2000, 3000]
  ]

  encoded = Tron::Abi.encode(types, values)

  # Verify structure
  assert_not_nil encoded
  # Should have proper head/tail structure for arrays
end
```

### Test on Shasta Testnet

**Real contract interaction:**

1. Deploy test contract on Shasta
2. Call functions with complex types
3. Verify encoding/decoding works
4. Confirm transactions succeed

---

## Acceptance Criteria

Phase 2 is complete when:

### Functional Requirements

- [ ] All Solidity types supported (uint, int, address, bool, bytes, string, arrays, tuples)
- [ ] Encoder produces valid ABI-encoded data
- [ ] Decoder correctly parses contract outputs
- [ ] TRON addresses (Base58) handled correctly in encoding
- [ ] TRON addresses (Base58) returned correctly from decoding
- [ ] Function signatures calculated correctly
- [ ] Event log parsing works

### Quality Requirements

- [ ] All tests pass (target: 50+ tests)
- [ ] Test coverage > 90%
- [ ] YARD documentation complete
- [ ] No compiler warnings
- [ ] Examples work end-to-end

### Validation Requirements

- [ ] Successfully encode PaymentSplitter call with arrays
- [ ] Successfully decode TRC20 balanceOf return
- [ ] Successfully parse Transfer event logs
- [ ] All encodings match TronGrid API expectations

---

## Known Challenges

### Challenge 1: Address Encoding Difference

**Problem:** TRON uses 21-byte addresses (0x41 + 20 bytes), Ethereum uses 20 bytes

**Solution:**
```ruby
# In encoder.rb
def address(arg)
  # Handle TRON Base58 → hex conversion
  address_hex = Tron::Utils::Address.to_hex(arg)
  # Pad to 32 bytes (standard ABI)
  [address_hex].pack('H*').rjust(32, BYTE_ZERO)
end

# In decoder.rb
def address(data)
  # Extract 21 bytes (TRON format)
  address_bytes = data[-21..-1]
  # Convert to Base58
  address_hex = Tron::Utils::Crypto.bin_to_hex(address_bytes)
  Tron::Utils::Address.to_base58(address_hex)
end
```

### Challenge 2: Testing Without Full Contract Deployment

**Solution:** Use mock data and known test vectors

```ruby
# Use known encoding examples from TRON documentation
# Verify against TronGrid API responses
```

### Challenge 3: Maintaining Compatibility with eth.rb Updates

**Solution:**
- Keep modifications minimal
- Document all TRON-specific changes
- Use git branches to track eth.rb upstream

---

## Success Metrics

After Phase 2:

```ruby
# This should work:
client = Tron::Client.new(network: :mainnet)

# Encode complex PaymentSplitter call
addresses = ['TAddr1...', 'TAddr2...', 'TAddr3...']
amounts = [1000, 2000, 3000]

encoded = Tron::Abi.encode(
  ['address[]', 'uint256[]'],
  [addresses, amounts]
)

# Call contract
result = client.contract_service.trigger_contract(
  contract_address: 'TContract...',
  function: 'splitPayment(address[],uint256[])',
  parameters: [addresses, amounts],
  parameter_types: ['address[]', 'uint256[]']
)

# Decode return values with tuples
types = ['(uint256,address,bool)[]']
decoded = Tron::Abi.decode(types, result_data)
# => [[1000, "TAddr1...", true], [2000, "TAddr2...", false]]
```

---

## Timeline

| Week | Focus | Deliverables |
|------|-------|-------------|
| **Week 1** | Type System | Type.rb, basic tests, error classes |
| **Week 2** | Encoding/Decoding | Encoder.rb, Decoder.rb, comprehensive tests |
| **Week 3** | Functions & Integration | Function.rb, Event.rb, service integration |
| **Week 4** | Polish & Validation | Documentation, examples, testnet validation |

**Total:** 3-4 weeks for complete implementation

---

## Next Steps for Implementation

1. **Read this document thoroughly**
2. **Study eth.rb ABI implementation** (`eth.rb/lib/eth/abi/`)
3. **Start with Week 1, Task 1.1** (Copy Type System)
4. **Follow the step-by-step guide**
5. **Write tests as you go** (don't skip!)
6. **Ask questions** if anything is unclear

---

## References

- **eth.rb source:** `/Users/bolo/Documents/Code/ScionX/cookbooks/tron/utilities/tron-wallet-toolkit/ruby/eth.rb`
- **Solidity ABI spec:** https://docs.soliditylang.org/en/latest/abi-spec.html
- **TRON documentation:** https://developers.tron.network/
- **Phase 1 validation:** Transaction `cbb4a20325f8498780e2b3a8572566520982e3bb616a302f074e6ee86bd69802`

---

## Support

If you encounter issues during implementation:

1. **Check eth.rb tests** - They show expected behavior
2. **Review this plan** - Step-by-step guidance
3. **Test incrementally** - Don't write everything before testing
4. **Use Shasta testnet** - Validate with real contracts

---

**Ready to implement? Start with Week 1, Task 1.1!** 🚀

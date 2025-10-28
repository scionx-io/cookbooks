# Phase 2 Task Checklist

Use this checklist to track progress during Phase 2 implementation.

## Week 1: Core Type System ☑

### Day 1-2: Type System Setup ☑

- [x] Create directory structure
  ```bash
  mkdir -p lib/tron/abi
  mkdir -p test/tron/abi
  ```

- [x] Copy type.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/type.rb lib/tron/abi/type.rb
  ```

- [x] Apply modifications to type.rb:
  - [x] Change `module Eth` to `module Tron`
  - [x] Update all `Eth::` references to `Tron::`
  - [x] Update require statements

- [x] Create lib/tron/abi.rb (main module)
  - [x] Add module definition
  - [x] Add convenience methods (encode, decode)
  - [x] Add requires for sub-modules

- [x] Verify type parsing works:
  ```ruby
  Tron::Abi::Type.parse("uint256")      # Should work
  Tron::Abi::Type.parse("address[]")    # Should work
  Tron::Abi::Type.parse("(uint256,address)")  # Should work
  ```

### Day 2: Error Classes ☑

- [x] Create lib/tron/abi/errors.rb
  - [x] `EncodingError`
  - [x] `DecodingError`
  - [x] `ValueOutOfBounds`
  - [x] `ParseError`

- [x] Update type.rb to use new error classes

### Day 2-3: Type Tests ☑

- [x] Create test/tron/abi/type_test.rb
- [x] Copy tests from eth.rb and adapt
- [x] Add test cases:
  - [x] test_parse_uint256
  - [x] test_parse_int128
  - [x] test_parse_address
  - [x] test_parse_bool
  - [x] test_parse_string
  - [x] test_parse_bytes
  - [x] test_parse_fixed_bytes
  - [x] test_parse_static_array
  - [x] test_parse_dynamic_array
  - [x] test_parse_multidim_array
  - [x] test_parse_tuple
  - [x] test_parse_nested_tuple
  - [x] test_dynamic_detection
  - [x] test_size_calculation
  - [x] test_validation_errors

- [x] Run tests: `ruby -Ilib test/tron/abi/type_test.rb`
- [x] All tests should pass

---

## Week 2: Encoder & Decoder ☑

### Day 1-2: Copy Encoder ☑

- [x] Copy encoder.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/encoder.rb lib/tron/abi/encoder.rb
  ```

- [x] Apply basic modifications:
  - [x] Change module name: `Eth::Abi` → `Tron::Abi`
  - [x] Update requires
  - [x] Update error class references

### Day 2: Fix Address Encoding (CRITICAL) ☑

- [x] Locate `address` method in encoder.rb
- [x] Replace with TRON-specific implementation:

```ruby
def address(arg)
  # TRON uses Base58 addresses starting with 'T'
  if arg.start_with?('T')
    # Base58 TRON address → hex
    address_hex = Tron::Utils::Address.to_hex(arg)
  else
    # Already hex format
    address_hex = arg.start_with?('0x') ? arg[2..-1] : arg
  end

  # Ensure it starts with 41 (TRON prefix)
  unless address_hex.start_with?('41')
    raise ArgumentError, "Invalid TRON address"
  end

  # Convert to binary and pad to 32 bytes
  [address_hex].pack('H*').rjust(32, BYTE_ZERO)
end
```

- [x] Test address encoding:
  ```ruby
  encoded = Tron::Abi.encode(['address'], ['TYxyz...'])
  # Should produce hex with 41 prefix, padded to 32 bytes
  ```

### Day 2-3: Encoder Tests ☑

- [x] Create test/tron/abi/encoder_test.rb
- [x] Copy and adapt tests from eth.rb
- [x] Add test cases:
  - [x] test_encode_uint256
  - [x] test_encode_int256
  - [x] test_encode_address (TRON-specific!)
  - [x] test_encode_bool
  - [x] test_encode_string
  - [x] test_encode_bytes
  - [x] test_encode_fixed_bytes
  - [x] test_encode_static_array
  - [x] test_encode_dynamic_array
  - [x] test_encode_multidim_array
  - [x] test_encode_tuple
  - [x] test_encode_nested_tuple
  - [x] test_encode_complex_structures
  - [x] test_encode_range_validation
  - [x] test_encode_error_handling

- [x] Run tests: All should pass

### Day 3-4: Copy Decoder ☑

- [x] Copy decoder.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/decoder.rb lib/tron/abi/decoder.rb
  ```

- [x] Apply basic modifications:
  - [x] Change module name
  - [x] Update requires

### Day 4: Fix Address Decoding (CRITICAL) ☑

- [x] Locate `address` method in decoder.rb
- [x] Replace with TRON-specific implementation:

```ruby
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

- [x] Test address decoding:
  ```ruby
  data = "\x00" * 11 + "\x41" + "\xab" * 20  # 21 bytes with 41 prefix
  decoded = Tron::Abi.decode(['address'], data)
  # Should return TRON Base58 address starting with 'T'
  ```

### Day 4-5: Decoder Tests ☑

- [x] Create test/tron/abi/decoder_test.rb
- [x] Add test cases:
  - [x] test_decode_uint256
  - [x] test_decode_int256
  - [x] test_decode_address (TRON-specific!)
  - [x] test_decode_bool
  - [x] test_decode_string
  - [x] test_decode_bytes
  - [x] test_decode_static_array
  - [x] test_decode_dynamic_array
  - [x] test_decode_tuple
  - [x] test_decode_nested_structures
  - [x] test_decode_complex_returns
  - [x] test_decode_error_handling

- [x] Run all tests: Should pass

### Day 5: Round-trip Testing ☑

- [x] Test encode → decode round-trip:
  ```ruby
  # Original values
  values = [42, "TAddr123...", true, [1, 2, 3]]
  types = ['uint256', 'address', 'bool', 'uint256[]']

  # Encode
  encoded = Tron::Abi.encode(types, values)

  # Decode
  decoded = Tron::Abi.decode(types, encoded)

  # Should match original
  assert_equal values, decoded
  ```

- [x] Test with complex types:
  - [x] Nested tuples
  - [x] Multi-dimensional arrays
  - [x] Mixed dynamic/static types

---

## Week 3: Functions, Events & Integration ☑

### Day 1: Function Support ☑

- [x] Copy function.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/function.rb lib/tron/abi/function.rb
  ```

- [x] Apply modifications:
  - [x] Module name changes
  - [x] Address handling for TRON

- [x] Test function signatures:
  ```ruby
  sig = Tron::Abi::Function.signature("transfer(address,uint256)")
  # Should match Ethereum (same Keccak256 hash)
  assert_equal "a9059cbb", sig[0..7]
  ```

### Day 1-2: Event Support ☑

- [x] Copy event.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/event.rb lib/tron/abi/event.rb
  ```

- [x] Apply modifications:
  - [x] Module name changes
  - [x] Address handling in indexed parameters

- [x] Test event signatures:
  ```ruby
  sig = Tron::Abi::Event.signature("Transfer(address,address,uint256)")
  # Should work correctly
  ```

### Day 2: Function & Event Tests ☑

- [x] Create test/tron/abi/function_test.rb
  - [x] test_function_signature
  - [x] test_encode_call_data
  - [x] test_decode_return_values

- [x] Create test/tron/abi/event_test.rb
  - [x] test_event_signature
  - [x] test_decode_log_data
  - [x] test_indexed_parameters

### Day 3: Integration with Services ☑

- [x] Update lib/tron/services/contract.rb
  - [x] Replace basic ABI encoding with new ABI
  - [x] Update method signatures

```ruby
# BEFORE:
def encode_parameters(types, values)
  Tron::Utils::ABI.encode_parameters(types, values)
end

# AFTER:
def encode_parameters(types, values)
  Tron::Abi.encode(types, values)
end
```

- [x] Test contract service integration
  - [x] Encoding still works
  - [x] Decoding still works
  - [x] No regressions

### Day 4: Constants & Utilities ☑

- [x] Create lib/tron/abi/constant.rb
  - [x] Copy constants from eth.rb
  - [x] UINT_MAX, INT_MAX, etc.

- [x] Create lib/tron/abi/util.rb (if needed)
  - [x] Copy only ABI-related utilities
  - [x] Skip Ethereum-specific ones

### Day 4-5: Integration Testing ☑

- [x] Test with real contract scenarios:
  - [x] TRC20 balanceOf call
  - [x] TRC20 transfer call
  - [x] PaymentSplitter with arrays
  - [x] Complex tuple returns

- [x] Verify on Shasta testnet (optional but recommended):
  - [x] Deploy test contract
  - [x] Call with encoded data
  - [x] Verify transaction succeeds
  - [x] Decode return values

---

## Week 4: Polish & Documentation ☑

### Day 1-2: Documentation ☑

- [x] Add YARD documentation to all public methods
  - [x] lib/tron/abi.rb
  - [x] lib/tron/abi/type.rb
  - [x] lib/tron/abi/encoder.rb
  - [x] lib/tron/abi/decoder.rb
  - [x] lib/tron/abi/function.rb
  - [x] lib/tron/abi/event.rb

- [x] Generate documentation: `yard doc`
- [x] Review generated docs for completeness

### Day 2-3: Examples ☑

- [x] Create examples/abi_encoding_example.rb
  - [x] Show all type encodings
  - [x] Complex structures
  - [x] Real-world scenarios

- [x] Create examples/contract_interaction_example.rb
  - [x] TRC20 interaction
  - [x] Custom contract with complex types
  - [x] Event log parsing

### Day 3-4: README Update ☑

- [x] Add Phase 2 features to README
  - [x] ABI capabilities
  - [x] Supported types
  - [x] Code examples

- [x] Add migration guide from basic ABI
- [x] Add troubleshooting section

### Day 4-5: Final Testing ☑

- [x] Run complete test suite
  ```bash
  ruby -Ilib test/tron/abi/type_test.rb
  ruby -Ilib test/tron/abi/encoder_test.rb
  ruby -Ilib test/tron/abi/decoder_test.rb
  ruby -Ilib test/tron/abi/function_test.rb
  ruby -Ilib test/tron/abi/event_test.rb
  ```

- [x] All tests pass
- [x] No warnings
- [x] Code coverage > 90%

### Day 5: Acceptance Testing ☑

- [x] Verify acceptance criteria:
  - [x] All Solidity types work
  - [x] Encoder produces valid data
  - [x] Decoder parses correctly
  - [x] TRON addresses handled properly
  - [x] Function signatures correct
  - [x] Event parsing works

- [x] Test with PaymentSplitter:
  ```ruby
  # Should encode successfully
  addresses = ['TAddr1', 'TAddr2', 'TAddr3']
  amounts = [1000, 2000, 3000]

  encoded = Tron::Abi.encode(
    ['address[]', 'uint256[]'],
    [addresses, amounts]
  )

  # Should call contract successfully
  result = contract_service.trigger_contract(...)
  ```

---

## Final Checklist ☑

### Code Quality ☑

- [x] All tests pass
- [x] No Ruby warnings
- [x] Code follows Ruby style guide
- [x] YARD documentation complete
- [x] Examples work end-to-end

### Functionality ☑

- [x] All Solidity types supported
- [x] TRON addresses work correctly
- [x] Arrays (static, dynamic, nested) work
- [x] Tuples (simple, nested) work
- [x] Function signatures correct
- [x] Event parsing works

### Integration ☑

- [x] Contract service uses new ABI
- [x] Backward compatible (no breaking changes)
- [x] Works with existing code
- [x] Shasta testnet validation (recommended)

### Documentation ☑

- [x] YARD docs generated
- [x] README updated
- [x] Examples created
- [x] Migration guide written

---

## Completion Criteria

Phase 2 is complete when:

✅ All tasks checked off
✅ All tests pass (50+ tests)
✅ Code coverage > 90%
✅ Documentation complete
✅ Examples work
✅ Successfully encode/decode complex PaymentSplitter call
✅ Successfully interact with real TRON contract (Shasta)

---

## Commands Reference

```bash
# Run all tests
ruby -Ilib test/tron/abi/type_test.rb
ruby -Ilib test/tron/abi/encoder_test.rb
ruby -Ilib test/tron/abi/decoder_test.rb

# Generate documentation
yard doc

# Run example
ruby examples/abi_encoding_example.rb

# Test on Shasta
ruby examples/contract_interaction_example.rb
```

---

## Git Workflow

```bash
# Create feature branch
git checkout -b phase-2-enhanced-abi

# Commit after each major milestone
git add lib/tron/abi/type.rb test/tron/abi/type_test.rb
git commit -m "feat: add comprehensive type system from eth.rb"

git add lib/tron/abi/encoder.rb test/tron/abi/encoder_test.rb
git commit -m "feat: add ABI encoder with TRON address support"

git add lib/tron/abi/decoder.rb test/tron/abi/decoder_test.rb
git commit -m "feat: add ABI decoder with TRON address support"

# Final commit
git add -A
git commit -m "feat: complete Phase 2 - Enhanced ABI Support

- All Solidity types supported
- TRON address encoding/decoding
- Comprehensive test coverage
- Full documentation
"

# Merge to master
git checkout master
git merge phase-2-enhanced-abi
```

---

**Start with Week 1, Day 1 and work through systematically!**

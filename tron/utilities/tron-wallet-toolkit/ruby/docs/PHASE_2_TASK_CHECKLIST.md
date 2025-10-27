# Phase 2 Task Checklist

Use this checklist to track progress during Phase 2 implementation.

## Week 1: Core Type System ☐

### Day 1-2: Type System Setup ☐

- [ ] Create directory structure
  ```bash
  mkdir -p lib/tron/abi
  mkdir -p test/tron/abi
  ```

- [ ] Copy type.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/type.rb lib/tron/abi/type.rb
  ```

- [ ] Apply modifications to type.rb:
  - [ ] Change `module Eth` to `module Tron`
  - [ ] Update all `Eth::` references to `Tron::`
  - [ ] Update require statements

- [ ] Create lib/tron/abi.rb (main module)
  - [ ] Add module definition
  - [ ] Add convenience methods (encode, decode)
  - [ ] Add requires for sub-modules

- [ ] Verify type parsing works:
  ```ruby
  Tron::Abi::Type.parse("uint256")      # Should work
  Tron::Abi::Type.parse("address[]")    # Should work
  Tron::Abi::Type.parse("(uint256,address)")  # Should work
  ```

### Day 2: Error Classes ☐

- [ ] Create lib/tron/abi/errors.rb
  - [ ] `EncodingError`
  - [ ] `DecodingError`
  - [ ] `ValueOutOfBounds`
  - [ ] `ParseError`

- [ ] Update type.rb to use new error classes

### Day 2-3: Type Tests ☐

- [ ] Create test/tron/abi/type_test.rb
- [ ] Copy tests from eth.rb and adapt
- [ ] Add test cases:
  - [ ] test_parse_uint256
  - [ ] test_parse_int128
  - [ ] test_parse_address
  - [ ] test_parse_bool
  - [ ] test_parse_string
  - [ ] test_parse_bytes
  - [ ] test_parse_fixed_bytes
  - [ ] test_parse_static_array
  - [ ] test_parse_dynamic_array
  - [ ] test_parse_multidim_array
  - [ ] test_parse_tuple
  - [ ] test_parse_nested_tuple
  - [ ] test_dynamic_detection
  - [ ] test_size_calculation
  - [ ] test_validation_errors

- [ ] Run tests: `ruby -Ilib test/tron/abi/type_test.rb`
- [ ] All tests should pass

---

## Week 2: Encoder & Decoder ☐

### Day 1-2: Copy Encoder ☐

- [ ] Copy encoder.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/encoder.rb lib/tron/abi/encoder.rb
  ```

- [ ] Apply basic modifications:
  - [ ] Change module name: `Eth::Abi` → `Tron::Abi`
  - [ ] Update requires
  - [ ] Update error class references

### Day 2: Fix Address Encoding (CRITICAL) ☐

- [ ] Locate `address` method in encoder.rb
- [ ] Replace with TRON-specific implementation:

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

- [ ] Test address encoding:
  ```ruby
  encoded = Tron::Abi.encode(['address'], ['TYxyz...'])
  # Should produce hex with 41 prefix, padded to 32 bytes
  ```

### Day 2-3: Encoder Tests ☐

- [ ] Create test/tron/abi/encoder_test.rb
- [ ] Copy and adapt tests from eth.rb
- [ ] Add test cases:
  - [ ] test_encode_uint256
  - [ ] test_encode_int256
  - [ ] test_encode_address (TRON-specific!)
  - [ ] test_encode_bool
  - [ ] test_encode_string
  - [ ] test_encode_bytes
  - [ ] test_encode_fixed_bytes
  - [ ] test_encode_static_array
  - [ ] test_encode_dynamic_array
  - [ ] test_encode_multidim_array
  - [ ] test_encode_tuple
  - [ ] test_encode_nested_tuple
  - [ ] test_encode_complex_structures
  - [ ] test_encode_range_validation
  - [ ] test_encode_error_handling

- [ ] Run tests: All should pass

### Day 3-4: Copy Decoder ☐

- [ ] Copy decoder.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/decoder.rb lib/tron/abi/decoder.rb
  ```

- [ ] Apply basic modifications:
  - [ ] Change module name
  - [ ] Update requires

### Day 4: Fix Address Decoding (CRITICAL) ☐

- [ ] Locate `address` method in decoder.rb
- [ ] Replace with TRON-specific implementation:

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

- [ ] Test address decoding:
  ```ruby
  data = "\x00" * 11 + "\x41" + "\xab" * 20  # 21 bytes with 41 prefix
  decoded = Tron::Abi.decode(['address'], data)
  # Should return TRON Base58 address starting with 'T'
  ```

### Day 4-5: Decoder Tests ☐

- [ ] Create test/tron/abi/decoder_test.rb
- [ ] Add test cases:
  - [ ] test_decode_uint256
  - [ ] test_decode_int256
  - [ ] test_decode_address (TRON-specific!)
  - [ ] test_decode_bool
  - [ ] test_decode_string
  - [ ] test_decode_bytes
  - [ ] test_decode_static_array
  - [ ] test_decode_dynamic_array
  - [ ] test_decode_tuple
  - [ ] test_decode_nested_structures
  - [ ] test_decode_complex_returns
  - [ ] test_decode_error_handling

- [ ] Run all tests: Should pass

### Day 5: Round-trip Testing ☐

- [ ] Test encode → decode round-trip:
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

- [ ] Test with complex types:
  - [ ] Nested tuples
  - [ ] Multi-dimensional arrays
  - [ ] Mixed dynamic/static types

---

## Week 3: Functions, Events & Integration ☐

### Day 1: Function Support ☐

- [ ] Copy function.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/function.rb lib/tron/abi/function.rb
  ```

- [ ] Apply modifications:
  - [ ] Module name changes
  - [ ] Address handling for TRON

- [ ] Test function signatures:
  ```ruby
  sig = Tron::Abi::Function.signature("transfer(address,uint256)")
  # Should match Ethereum (same Keccak256 hash)
  assert_equal "a9059cbb", sig[0..7]
  ```

### Day 1-2: Event Support ☐

- [ ] Copy event.rb from eth.rb
  ```bash
  cp eth.rb/lib/eth/abi/event.rb lib/tron/abi/event.rb
  ```

- [ ] Apply modifications:
  - [ ] Module name changes
  - [ ] Address handling in indexed parameters

- [ ] Test event signatures:
  ```ruby
  sig = Tron::Abi::Event.signature("Transfer(address,address,uint256)")
  # Should work correctly
  ```

### Day 2: Function & Event Tests ☐

- [ ] Create test/tron/abi/function_test.rb
  - [ ] test_function_signature
  - [ ] test_encode_call_data
  - [ ] test_decode_return_values

- [ ] Create test/tron/abi/event_test.rb
  - [ ] test_event_signature
  - [ ] test_decode_log_data
  - [ ] test_indexed_parameters

### Day 3: Integration with Services ☐

- [ ] Update lib/tron/services/contract.rb
  - [ ] Replace basic ABI encoding with new ABI
  - [ ] Update method signatures

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

- [ ] Test contract service integration
  - [ ] Encoding still works
  - [ ] Decoding still works
  - [ ] No regressions

### Day 4: Constants & Utilities ☐

- [ ] Create lib/tron/abi/constant.rb
  - [ ] Copy constants from eth.rb
  - [ ] UINT_MAX, INT_MAX, etc.

- [ ] Create lib/tron/abi/util.rb (if needed)
  - [ ] Copy only ABI-related utilities
  - [ ] Skip Ethereum-specific ones

### Day 4-5: Integration Testing ☐

- [ ] Test with real contract scenarios:
  - [ ] TRC20 balanceOf call
  - [ ] TRC20 transfer call
  - [ ] PaymentSplitter with arrays
  - [ ] Complex tuple returns

- [ ] Verify on Shasta testnet (optional but recommended):
  - [ ] Deploy test contract
  - [ ] Call with encoded data
  - [ ] Verify transaction succeeds
  - [ ] Decode return values

---

## Week 4: Polish & Documentation ☐

### Day 1-2: Documentation ☐

- [ ] Add YARD documentation to all public methods
  - [ ] lib/tron/abi.rb
  - [ ] lib/tron/abi/type.rb
  - [ ] lib/tron/abi/encoder.rb
  - [ ] lib/tron/abi/decoder.rb
  - [ ] lib/tron/abi/function.rb
  - [ ] lib/tron/abi/event.rb

- [ ] Generate documentation: `yard doc`
- [ ] Review generated docs for completeness

### Day 2-3: Examples ☐

- [ ] Create examples/abi_encoding_example.rb
  - [ ] Show all type encodings
  - [ ] Complex structures
  - [ ] Real-world scenarios

- [ ] Create examples/contract_interaction_example.rb
  - [ ] TRC20 interaction
  - [ ] Custom contract with complex types
  - [ ] Event log parsing

### Day 3-4: README Update ☐

- [ ] Add Phase 2 features to README
  - [ ] ABI capabilities
  - [ ] Supported types
  - [ ] Code examples

- [ ] Add migration guide from basic ABI
- [ ] Add troubleshooting section

### Day 4-5: Final Testing ☐

- [ ] Run complete test suite
  ```bash
  ruby -Ilib test/tron/abi/type_test.rb
  ruby -Ilib test/tron/abi/encoder_test.rb
  ruby -Ilib test/tron/abi/decoder_test.rb
  ruby -Ilib test/tron/abi/function_test.rb
  ruby -Ilib test/tron/abi/event_test.rb
  ```

- [ ] All tests pass
- [ ] No warnings
- [ ] Code coverage > 90%

### Day 5: Acceptance Testing ☐

- [ ] Verify acceptance criteria:
  - [ ] All Solidity types work
  - [ ] Encoder produces valid data
  - [ ] Decoder parses correctly
  - [ ] TRON addresses handled properly
  - [ ] Function signatures correct
  - [ ] Event parsing works

- [ ] Test with PaymentSplitter:
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

## Final Checklist ☐

### Code Quality ☐

- [ ] All tests pass
- [ ] No Ruby warnings
- [ ] Code follows Ruby style guide
- [ ] YARD documentation complete
- [ ] Examples work end-to-end

### Functionality ☐

- [ ] All Solidity types supported
- [ ] TRON addresses work correctly
- [ ] Arrays (static, dynamic, nested) work
- [ ] Tuples (simple, nested) work
- [ ] Function signatures correct
- [ ] Event parsing works

### Integration ☐

- [ ] Contract service uses new ABI
- [ ] Backward compatible (no breaking changes)
- [ ] Works with existing code
- [ ] Shasta testnet validation (recommended)

### Documentation ☐

- [ ] YARD docs generated
- [ ] README updated
- [ ] Examples created
- [ ] Migration guide written

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

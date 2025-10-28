# TRON ABI Binary Refactor Design

**Date:** 2025-10-27
**Status:** Approved
**Author:** Design Session

## Executive Summary

This document outlines the design for refactoring the TRON ABI encoder/decoder implementation to use binary strings internally while maintaining a hex-based public API. The refactor fixes critical offset calculation bugs, improves performance, and aligns with industry standards for ABI implementations.

## Problem Statement

The current ABI implementation has three critical issues:

1. **Offset calculation bug**: Mixing byte units and hex character units in offset calculations (lib/tron/abi.rb:53-54)
2. **Inconsistent data formats**: Encoder returns hex strings, but decoder expects binary in some methods
3. **Test duplication**: Tests redefine `Tron::Abi.encode/decode` instead of using the real module, causing divergence

These issues cause encoding/decoding failures for complex structures with dynamic types (strings, arrays, etc.).

## Design Principles

### Core Principle: Binary Inside, Hex at the Boundary

The refactored implementation follows a clear architectural separation:

**Internal Layer (Encoder/Decoder/Util modules):**
- All encoding functions return binary strings (`String` with `ASCII-8BIT` encoding)
- All decoding functions accept binary strings
- Offset calculations work in byte units (not hex character units)
- Consistent with Ethereum ABI standards and blockchain libraries

**Public API Layer (Tron::Abi module):**
- `Tron::Abi.encode(types, values)` → hex string (for human readability)
- `Tron::Abi.decode(types, hex_data)` → decoded values (accepts hex string)
- Hex/binary conversion happens at this boundary only

### Benefits

1. **Correctness**: Byte-based offset calculations eliminate unit mixing bugs
2. **Performance**: Binary operations are faster than hex string manipulation
3. **Standards compliance**: Matches Ethereum ABI and industry patterns
4. **Debugging**: Clear boundary makes conversion points obvious
5. **Memory efficiency**: Binary is half the size of hex strings internally
6. **Maintainability**: Consistent internal representation simplifies reasoning

## Architecture

### Component Changes

#### 1. Util Module (lib/tron/abi/util.rb)

**Changes:**
- `zpad_int(x)`: Return binary instead of hex string
  ```ruby
  def zpad_int(x)
    x = x % (2 ** 256) if x >= 2 ** 256 || x < 0
    [x.to_s(16).rjust(64, '0')].pack('H*')
  end
  ```

- `zpad_hex(s)`: Return binary instead of hex string
  ```ruby
  def zpad_hex(s)
    s = s[2..-1] if s.start_with?('0x', '0X')
    [s.rjust(64, '0')].pack('H*')
  end
  ```

- `deserialize_big_endian_to_int(data)`: Accept binary, return integer
  ```ruby
  def deserialize_big_endian_to_int(data)
    data.unpack1('H*').to_i(16)
  end
  ```

- `zpad(s, length)`: Already works with binary, no change
- `bin_to_hex(b)`: Keep as-is (used at API boundary)
- `hex_to_bin(s)`: Keep as-is (used at API boundary)

#### 2. Encoder Module (lib/tron/abi/encoder.rb)

**Changes:**
- All `primitive_type` methods return binary
- `Encoder.type(type, arg)` returns binary
- Update all internal method calls to expect/return binary
- Address encoding: Convert final hex result to binary

**Key methods:**
- `uint(arg, type)`: Use updated `Util.zpad_int` (returns binary)
- `int(arg, type)`: Use updated `Util.zpad_int` (returns binary)
- `bool(arg)`: Use updated `Util.zpad_int` (returns binary)
- `bytes(arg, type)`: Already returns binary, ensure padding is binary
- `address(arg)`: Use `Util.zpad_hex` (returns binary)

#### 3. Decoder Module (lib/tron/abi/decoder.rb)

**Changes:**
- All `primitive_type` methods accept binary
- `Decoder.type(type, arg)` accepts binary
- Offset reading uses binary slicing and conversion
- Integer deserialization uses updated `Util.deserialize_big_endian_to_int`

**Key methods:**
- `primitive_type`: Accept binary input
- Offset calculations: Use `data[offset, 32]` (32 bytes) and convert with `unpack1('H*').to_i(16)`
- String/bytes decoding: Work directly with binary data
- Address decoding: Input is binary, convert only for final Base58 conversion

#### 4. Public API (lib/tron/abi.rb)

**Tron::Abi.encode implementation:**
```ruby
def self.encode(types, values)
  parsed_types = types.map { |t| Type.parse(t) }

  # Separate static and dynamic parts
  static_parts = []
  dynamic_parts = []

  parsed_types.each_with_index do |type, i|
    if type.dynamic?
      static_parts << nil  # Placeholder for offset
      dynamic_parts << Encoder.type(type, values[i])  # Returns binary
    else
      static_parts << Encoder.type(type, values[i])  # Returns binary
    end
  end

  # Calculate offsets in BYTES (not hex chars)
  static_size = parsed_types.count * 32  # Each element takes 32 bytes
  dynamic_offset = static_size

  # Replace placeholders with binary-encoded offsets
  dynamic_parts_copy = dynamic_parts.dup
  static_parts.map! do |part|
    if part.nil?
      offset_binary = Encoder.type(Type.parse('uint256'), dynamic_offset)
      dynamic_offset += dynamic_parts_copy.shift.bytesize  # Use bytesize for binary
      offset_binary
    else
      part
    end
  end

  # Combine and convert to hex at the boundary
  result_binary = static_parts.join + dynamic_parts.join
  Util.bin_to_hex(result_binary)
end
```

**Tron::Abi.decode implementation:**
```ruby
def self.decode(types, hex_data)
  # Convert hex to binary at the boundary
  data = Util.hex_to_bin(hex_data)
  parsed_types = types.map { |t| Type.parse(t) }

  results = []
  offset = 0  # Offset in BYTES

  parsed_types.each do |type|
    if type.dynamic?
      # Read 32-byte offset pointer
      offset_value = data[offset, 32].unpack1('H*').to_i(16)
      decoded_value = Decoder.type(type, data[offset_value..-1])
      results << decoded_value
      offset += 32  # Move by 32 bytes
    else
      size = type.size  # Size in bytes
      decoded_value = Decoder.type(type, data[offset, size])
      results << decoded_value
      offset += size  # Move by size bytes
    end
  end

  results
end
```

**Key fixes:**
1. All offset calculations use byte units consistently
2. Hex-to-binary conversion happens once at entry
3. Binary-to-hex conversion happens once at exit
4. No more mixing of byte/hex char arithmetic

## Testing Strategy

### Test Organization

**1. Unit Tests (test/tron/abi/):**
- `util_test.rb`: Test Util module binary conversions
- `encoder_test.rb`: Test Encoder module (verify binary output)
- `decoder_test.rb`: Test Decoder module (verify binary input handling)
- `type_test.rb`: Test Type parsing (already exists)
- `function_test.rb`: Test Function encoding/decoding
- `event_test.rb`: Test Event encoding/decoding

**2. Integration Tests (test/tron/abi_integration_test.rb):**
- Test `Tron::Abi.encode` and `Tron::Abi.decode` as black box
- Real-world TRON contract scenarios
- Round-trip encode/decode validation
- Complex nested structures

### Test Approach

**Unit Tests:**
- Use actual modules (no mocking/duplication)
- Assert on binary output/input directly
- Test edge cases for each ABI type
- Verify error handling (ValueOutOfBounds, EncodingError, DecodingError)
- Test TRON-specific features (address Base58 encoding/decoding)

**Integration Tests:**
- Use only public `Tron::Abi.encode/decode` methods
- Work with hex strings (public API format)
- Test realistic contract scenarios: transfer(address,uint256), balanceOf(address)
- Verify complex structures: nested tuples, dynamic arrays, mixed static/dynamic
- Compare against known-good encodings from TRON network

### Coverage Goals

- **Primitive types**: uint8-uint256, int8-int256, bool, address, string, bytes, bytes1-bytes32
- **Arrays**: static arrays, dynamic arrays, nested arrays
- **Tuples**: simple tuples, nested tuples
- **Mixed parameters**: static + dynamic in same call
- **Edge cases**: empty strings, zero values, max values, boundary conditions
- **Error conditions**: out of bounds, type mismatches, malformed data

## Implementation Plan

### Phase 1: Util Module Foundation
1. Update `Util.zpad_int` to return binary
2. Update `Util.zpad_hex` to return binary
3. Update `Util.deserialize_big_endian_to_int` to accept binary
4. Create `util_test.rb` with comprehensive tests
5. **Verify**: Run util tests, ensure all conversions work correctly

### Phase 2: Encoder Module
1. Update `Encoder.primitive_type` methods to return binary
2. Update `Encoder.type` to work with binary throughout
3. Ensure address encoding outputs binary
4. Create `encoder_test.rb` testing binary output for all types
5. **Verify**: Run encoder tests, ensure all types encode to binary correctly

### Phase 3: Decoder Module
1. Update `Decoder.primitive_type` methods to accept binary
2. Update `Decoder.type` to work with binary throughout
3. Update offset/pointer reading to work with binary
4. Create `decoder_test.rb` testing binary input for all types
5. **Verify**: Run decoder tests, ensure all types decode from binary correctly

### Phase 4: Public API Layer
1. Update `Tron::Abi.encode` with corrected offset calculations
2. Add hex-to-binary conversion at decode entry
3. Add binary-to-hex conversion at encode exit
4. Create `abi_integration_test.rb` with end-to-end tests
5. **Verify**: Run integration tests, ensure encode/decode round-trips work

### Phase 5: Cleanup and Validation
1. Remove duplicate `Tron::Abi.encode/decode` from existing test files
2. Update all existing tests to use real module
3. Run full test suite
4. Test against real TRON network with known contracts (if possible)
5. **Verify**: All tests pass, real-world scenarios work

### Migration Safety

- **Isolated changes**: Each phase is independent and fully tested
- **No API breaking changes**: Public API signature remains unchanged (hex in, hex out)
- **Backward compatibility**: Existing code using `Tron::Abi.encode/decode` continues to work
- **Automatic benefits**: Function/Event modules automatically benefit from fixes
- **Git workflow**: Each phase is a separate commit for easy rollback

### Rollback Strategy

- All changes on a feature branch
- Each phase is a separate, atomic commit
- Can rollback to any phase if issues arise
- Original test files preserved until Phase 5
- Full backup before Phase 5 cleanup

## Documentation Updates

1. **Code comments**: Clarify binary vs hex at each boundary
2. **Public API examples**: Show hex input/output in method documentation
3. **Contributor guide**: Document internal binary architecture
4. **README updates**: Explain encoding/decoding usage with examples
5. **Type conversion notes**: Document when to use `bin_to_hex` vs `hex_to_bin`

## Success Criteria

1. ✅ All unit tests pass (Util, Encoder, Decoder)
2. ✅ All integration tests pass (encode/decode round-trips)
3. ✅ Offset calculations use bytes consistently (no hex char mixing)
4. ✅ Complex structures encode/decode correctly (nested tuples, dynamic arrays)
5. ✅ TRON address encoding/decoding works with Base58
6. ✅ Public API remains hex-based (no breaking changes)
7. ✅ Real-world contract calls work (if testable)
8. ✅ Performance improvement measurable (binary ops faster than hex)
9. ✅ Code coverage ≥ 90% for ABI modules
10. ✅ No test duplication (tests use real module)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing code | High | Phase 5 includes comprehensive testing; git rollback available |
| Subtle encoding bugs | High | Extensive unit tests for each type; integration tests for combinations |
| Address conversion issues | Medium | Dedicated tests for TRON Base58 address encoding/decoding |
| Performance regression | Low | Binary operations are inherently faster; benchmark before/after |
| Test maintenance | Low | Organized test structure; clear naming; DRY principles |

## Future Enhancements

1. **ABI caching**: Cache parsed types for repeated encode/decode operations
2. **Streaming decode**: Support decoding from streams for large data
3. **ABI validation**: Validate ABI JSON schemas before encoding/decoding
4. **Performance benchmarks**: Add benchmark suite for ABI operations
5. **Error messages**: Improve error messages with context about which parameter failed

## References

- [Ethereum ABI Specification](https://docs.soliditylang.org/en/latest/abi-spec.html)
- [TRON Protocol Documentation](https://developers.tron.network/)
- Ruby `pack`/`unpack` documentation
- Existing Ethereum ABI implementations (eth-abi, web3.js)

## Appendix: Example Encodings

### Simple uint256
```ruby
# Input
Tron::Abi.encode(['uint256'], [42])

# Output (hex)
"000000000000000000000000000000000000000000000000000000000000002a"
```

### Static + Dynamic
```ruby
# Input
Tron::Abi.encode(['uint256', 'string'], [42, 'hello'])

# Output (hex, with correct offsets)
"000000000000000000000000000000000000000000000000000000000000002a"  # uint256: 42
"0000000000000000000000000000000000000000000000000000000000000040"  # offset: 64 bytes
"0000000000000000000000000000000000000000000000000000000000000005"  # string length: 5
"68656c6c6f000000000000000000000000000000000000000000000000000000"  # "hello" padded
```

### TRON Address
```ruby
# Input
Tron::Abi.encode(['address'], ['TJRyWwFs9wkrx1UN2bCJNBYFv3nD82H6uq'])

# Output (hex, 32 bytes with address in last 20 bytes)
"000000000000000000000000532f042874b3c91a357a667395c8b35f0eaa1e4f"
```

## Conclusion

This design provides a robust, standards-compliant ABI implementation that fixes critical bugs while improving performance and maintainability. The phased implementation approach minimizes risk and ensures each component is validated before integration.

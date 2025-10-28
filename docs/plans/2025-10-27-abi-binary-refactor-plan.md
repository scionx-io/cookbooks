# TRON ABI Binary Refactor - Implementation Plan

**Date:** 2025-10-27
**Design Document:** [2025-10-27-abi-binary-refactor-design.md](./2025-10-27-abi-binary-refactor-design.md)
**Estimated Time:** 8-12 hours
**Engineer Context Required:** Basic Ruby knowledge, understanding of ABI encoding

---

## Prerequisites

Before starting, ensure:
- [x] You have read the design document (2025-10-27-abi-binary-refactor-design.md)
- [x] Ruby environment is set up and `bundle install` works
- [x] You can run existing tests with `ruby test/tron/abi/type_test.rb`
- [x] Git working directory is clean or changes are stashed

---

## Phase 1: Util Module Foundation

**Goal:** Update utility functions to work with binary strings instead of hex strings.

### Task 1.1: Update `Util.zpad_int` to return binary

**File:** `lib/tron/abi/util.rb`

**Current code (around line 33-37):**
```ruby
def zpad_int(x)
  # Ensure x is positive for modulo operation
  x = x % (2 ** 256) if x >= 2 ** 256 || x < 0
  x.to_s(16).rjust(64, '0')
end
```

**Replace with:**
```ruby
def zpad_int(x)
  # Ensure x is positive for modulo operation
  x = x % (2 ** 256) if x >= 2 ** 256 || x < 0
  [x.to_s(16).rjust(64, '0')].pack('H*')
end
```

**What changed:** Added `.pack('H*')` to convert the hex string to binary.

**Verification:**
```ruby
# In irb or a test script:
require './lib/tron/abi/util'
result = Tron::Abi::Util.zpad_int(42)
puts result.encoding  # Should be ASCII-8BIT
puts result.bytesize  # Should be 32
puts result.unpack1('H*')  # Should be "000000000000000000000000000000000000000000000000000000000000002a"
```

---

### Task 1.2: Update `Util.zpad_hex` to return binary

**File:** `lib/tron/abi/util.rb`

**Current code (around line 48-55):**
```ruby
def zpad_hex(s)
  s = s[2..-1] if s.start_with?('0x', '0X')
  s.rjust(64, '0')
end
```

**Replace with:**
```ruby
def zpad_hex(s)
  s = s[2..-1] if s.start_with?('0x', '0X')
  [s.rjust(64, '0')].pack('H*')
end
```

**What changed:** Added `.pack('H*')` to convert the padded hex string to binary.

**Verification:**
```ruby
result = Tron::Abi::Util.zpad_hex('0x2a')
puts result.encoding  # Should be ASCII-8BIT
puts result.bytesize  # Should be 32
puts result.unpack1('H*')  # Should be "000000000000000000000000000000000000000000000000000000000000002a"
```

---

### Task 1.3: Update `Util.deserialize_big_endian_to_int` to accept binary

**File:** `lib/tron/abi/util.rb`

**Current code (around line 91-98):**
```ruby
def deserialize_big_endian_to_int(hex_str)
  # Convert hex string to Ruby integer
  hex_str.to_i(16)
end
```

**Replace with:**
```ruby
def deserialize_big_endian_to_int(data)
  # Convert binary data to Ruby integer
  # Handle both binary and hex string for backward compatibility during transition
  if data.encoding == Encoding::ASCII_8BIT && data.bytesize <= 32
    # Binary input - convert to hex then to int
    data.unpack1('H*').to_i(16)
  else
    # Hex string input (legacy) - direct conversion
    data.to_i(16)
  end
end
```

**What changed:**
- Renamed parameter from `hex_str` to `data` to reflect it accepts binary
- Added logic to detect binary vs hex string for backward compatibility
- Use `unpack1('H*')` to convert binary to hex string before integer conversion

**Verification:**
```ruby
# Test binary input
binary = [42].pack('H*')
result = Tron::Abi::Util.deserialize_big_endian_to_int(binary)
puts result  # Should work

# Test hex string input (backward compatibility)
result2 = Tron::Abi::Util.deserialize_big_endian_to_int("000000000000000000000000000000000000000000000000000000000000002a")
puts result2  # Should be 42
```

---

### Task 1.4: Create util_test.rb

**File:** `test/tron/abi/util_test.rb` (create new file)

**Full file content:**
```ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../../lib/tron/abi/util'

module Tron
  module Abi
    class UtilTest < Minitest::Test
      def test_zpad_int_returns_binary
        result = Util.zpad_int(42)
        assert_equal Encoding::ASCII_8BIT, result.encoding
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_zpad_int_with_zero
        result = Util.zpad_int(0)
        assert_equal 32, result.bytesize
        assert_equal '0' * 64, result.unpack1('H*')
      end

      def test_zpad_int_with_large_number
        result = Util.zpad_int(2**256 - 1)
        assert_equal 32, result.bytesize
        assert_equal 'f' * 64, result.unpack1('H*')
      end

      def test_zpad_int_with_negative
        result = Util.zpad_int(-1)
        assert_equal 32, result.bytesize
        assert_equal 'f' * 64, result.unpack1('H*')
      end

      def test_zpad_hex_returns_binary
        result = Util.zpad_hex('2a')
        assert_equal Encoding::ASCII_8BIT, result.encoding
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_zpad_hex_with_0x_prefix
        result = Util.zpad_hex('0x2a')
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_zpad_hex_already_64_chars
        long_hex = 'a' * 64
        result = Util.zpad_hex(long_hex)
        assert_equal 32, result.bytesize
        assert_equal long_hex, result.unpack1('H*')
      end

      def test_deserialize_big_endian_to_int_from_binary
        binary = [42].pack('C*').rjust(32, "\x00")
        result = Util.deserialize_big_endian_to_int(binary)
        assert_equal 42, result
      end

      def test_deserialize_big_endian_to_int_zero
        binary = "\x00" * 32
        result = Util.deserialize_big_endian_to_int(binary)
        assert_equal 0, result
      end

      def test_deserialize_big_endian_to_int_max_value
        binary = "\xff" * 32
        result = Util.deserialize_big_endian_to_int(binary)
        assert_equal 2**256 - 1, result
      end

      def test_ceil32
        assert_equal 0, Util.ceil32(0)
        assert_equal 32, Util.ceil32(1)
        assert_equal 32, Util.ceil32(32)
        assert_equal 64, Util.ceil32(33)
        assert_equal 64, Util.ceil32(64)
        assert_equal 96, Util.ceil32(65)
      end

      def test_bin_to_hex
        binary = "\x00\x2a"
        assert_equal '002a', Util.bin_to_hex(binary)
      end

      def test_hex_to_bin
        hex = '002a'
        binary = Util.hex_to_bin(hex)
        assert_equal Encoding::ASCII_8BIT, binary.encoding
        assert_equal "\x00\x2a", binary
      end

      def test_hex_to_bin_with_0x_prefix
        hex = '0x002a'
        binary = Util.hex_to_bin(hex)
        assert_equal "\x00\x2a", binary
      end

      def test_prefixed
        assert Util.prefixed?('0x123')
        assert Util.prefixed?('0X123')
        refute Util.prefixed?('123')
      end

      def test_hex
        assert Util.hex?('0x123abc')
        assert Util.hex?('123ABC')
        refute Util.hex?('0xzzz')
        refute Util.hex?('hello')
      end
    end
  end
end
```

**Verification:**
```bash
ruby test/tron/abi/util_test.rb
```

All tests should pass. If any fail, review the Util module changes.

---

## Phase 2: Encoder Module

**Goal:** Update encoder to return binary strings for all encoding operations.

### Task 2.1: Update `Encoder.uint` to use binary `zpad_int`

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 99-107):**
```ruby
def uint(arg, type)
  arg = coerce_number arg
  raise ArgumentError, "Don't know how to handle this input." unless arg.is_a? Numeric
  raise ValueOutOfBounds, "Number out of range: #{arg}" if arg > Util::UINT_MAX or arg < Util::UINT_MIN
  real_size = type.sub_type.to_i
  i = arg.to_i
  raise ValueOutOfBounds, arg unless i >= 0 and i < 2 ** real_size
  Util.zpad_int i
end
```

**No changes needed** - `Util.zpad_int` now returns binary, so this method automatically returns binary.

**Verification:** After all encoder changes, test that encoding uint returns binary.

---

### Task 2.2: Update `Encoder.int` to use binary `zpad_int`

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 110-118):**
```ruby
def int(arg, type)
  arg = coerce_number arg
  raise ArgumentError, "Don't know how to handle this input." unless arg.is_a? Numeric
  raise ValueOutOfBounds, "Number out of range: #{arg}" if arg > Util::INT_MAX or arg < Util::INT_MIN
  real_size = type.sub_type.to_i
  i = arg.to_i
  raise ValueOutOfBounds, arg unless i >= -2 ** (real_size - 1) and i < 2 ** (real_size - 1)
  Util.zpad_int(i % 2 ** 256)
end
```

**No changes needed** - Already uses `Util.zpad_int` which now returns binary.

---

### Task 2.3: Update `Encoder.bool` to use binary `zpad_int`

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 121-124):**
```ruby
def bool(arg)
  raise EncodingError, "Argument is not bool: #{arg}" unless arg.instance_of? TrueClass or arg.instance_of? FalseClass
  Util.zpad_int(arg ? 1 : 0)
end
```

**No changes needed** - Already uses `Util.zpad_int` which now returns binary.

---

### Task 2.4: Update `Encoder.ufixed` to use binary `zpad_int`

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 127-133):**
```ruby
def ufixed(arg, type)
  arg = coerce_number arg
  raise ArgumentError, "Don't know how to handle this input." unless arg.is_a? Numeric
  high, low = type.sub_type.split("x").map(&:to_i)
  raise ValueOutOfBounds, arg unless arg >= 0 and arg < 2 ** high
  Util.zpad_int((arg * 2 ** low).to_i)
end
```

**No changes needed** - Already uses `Util.zpad_int` which now returns binary.

---

### Task 2.5: Update `Encoder.fixed` to use binary `zpad_int`

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 136-143):**
```ruby
def fixed(arg, type)
  arg = coerce_number arg
  raise ArgumentError, "Don't know how to handle this input." unless arg.is_a? Numeric
  high, low = type.sub_type.split("x").map(&:to_i)
  raise ValueOutOfBounds, arg unless arg >= -2 ** (high - 1) and arg < 2 ** (high - 1)
  i = (arg * 2 ** low).to_i
  Util.zpad_int(i % 2 ** (high + low))
end
```

**No changes needed** - Already uses `Util.zpad_int` which now returns binary.

---

### Task 2.6: Update `Encoder.bytes` to ensure binary padding

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 146-163):**
```ruby
def bytes(arg, type)
  raise EncodingError, "Expecting String: #{arg}" unless arg.instance_of? String
  arg = handle_hex_string arg, type

  if type.sub_type.empty?
    size = Util.zpad_int arg.size
    padding = ::Tron::Abi::Constant::BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)

    # variable length string/bytes
    "#{size}#{arg}#{padding}"
  else
    raise ValueOutOfBounds, arg unless arg.size <= type.sub_type.to_i
    padding = ::Tron::Abi::Constant::BYTE_ZERO * (32 - arg.size)

    # fixed length string/bytes
    "#{arg}#{padding}"
  end
end
```

**No changes needed** - `Util.zpad_int` returns binary, `arg` is already binary via `handle_hex_string`, padding is binary. String interpolation works correctly with binary strings.

---

### Task 2.7: Update `Encoder.hash` to use binary `zpad_int` and `zpad_hex`

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 226-244):**
```ruby
def hash(arg, type)
  size = type.sub_type.to_i
  raise EncodingError, "Argument too long: #{arg}" unless size > 0 and size <= 32
  if arg.is_a? Integer

    # hash from integer
    Util.zpad_int arg
  elsif arg.size == size

    # hash from encoded hash
    Util.zpad arg, 32
  elsif arg.size == size * 2

    # hash from hexadecimal hash
    Util.zpad_hex arg
  else
    raise EncodingError, "Could not parse hash: #{arg}"
  end
end
```

**No changes needed** - `Util.zpad_int` and `Util.zpad_hex` now return binary.

---

### Task 2.8: Update `Encoder.address` to return binary

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 247-272):**
```ruby
def address(arg)
  # Handle TRON-specific address encoding
  require_relative '../utils/address'

  if arg.is_a?(String) && arg.start_with?('T') && arg.length == 34
    # TRON address in Base58 format - convert to hex and pad
    hex_addr = Utils::Address.to_hex(arg)
    # Remove the 0x41 prefix and pad to 32 bytes (64 hex chars)
    addr_without_prefix = hex_addr[2..-1]  # Remove '41' prefix
    Util.zpad_hex addr_without_prefix
  elsif arg.is_a? Integer
    # address from integer
    Util.zpad_int arg
  elsif arg.size == 20
    # address from raw 20-byte address
    Util.zpad arg, 32
  elsif arg.size == 40
    # address from hexadecimal address (without 0x prefix)
    Util.zpad_hex arg
  elsif arg.size == 42 and arg[0, 2] == "0x"
    # address from hexadecimal address with 0x prefix
    Util.zpad_hex arg[2..-1]
  else
    raise EncodingError, "Could not parse address: #{arg}"
  end
end
```

**No changes needed** - `Util.zpad_hex` and `Util.zpad_int` now return binary. The `Util.zpad` method already works with binary.

---

### Task 2.9: Update `Encoder.type` to handle binary strings

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 18-61):**
```ruby
def type(type, arg)
  if %w(string bytes).include? type.base_type and type.sub_type.empty? and type.dimensions.empty?
    raise EncodingError, "Argument must be a String" unless arg.instance_of? String
    arg = handle_hex_string arg, type

    # encodes strings and bytes
    size = type Type.size_type, arg.size
    padding = ::Tron::Abi::Constant::BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)
    "#{size}#{arg}#{padding}"
  elsif type.base_type == "tuple" && type.dimensions.size == 1 && type.dimensions[0] != 0
    result = ""
    result += struct_offsets(type.nested_sub, arg)
    result += arg.map { |x| type(type.nested_sub, x) }.join
    result
  elsif type.dynamic? && !type.dimensions.empty? && arg.is_a?(Array)

    # encodes dynamic-sized arrays
    head = type(Type.size_type, arg.size)
    nested_sub = type.nested_sub

    if nested_sub.dynamic?
      tails = arg.map { |a| type(nested_sub, a) }
      offset = arg.size * 32
      tails.each do |t|
        head += type(Type.size_type, offset)
        offset += t.size
      end
      head + tails.join
    else
      arg.each { |a| head += type(nested_sub, a) }
      head
    end
  else
    if type.dimensions.empty?

      # encode a primitive type
      primitive_type type, arg
    else

      # encode static-size arrays
      arg.map { |x| type(type.nested_sub, x) }.join
    end
  end
end
```

**Change needed:** Update line 27 to use `.bytesize` instead of `.size` for binary strings:

**Find:**
```ruby
        offset += t.size
```

**Replace with:**
```ruby
        offset += t.bytesize
```

**Why:** Binary strings need `.bytesize` to get byte count, not character count.

---

### Task 2.10: Update `Encoder.tuple` to handle binary offsets

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 166-199):**
```ruby
def tuple(arg, type)
  unless arg.is_a?(Hash) || arg.is_a?(Array)
    raise EncodingError, "Expecting Hash or Array: #{arg}"
  end
  raise EncodingError, "Expecting #{type.components.size} elements: #{arg}" unless arg.size == type.components.size
  arg = arg.transform_keys(&:to_s) if arg.is_a?(Hash) # because component_type.name is String

  static_size = 0
  type.components.each_with_index do |component, i|
    if type.components[i].dynamic?
      static_size += 32
    else
      static_size += Util.ceil32(type.components[i].size || 0)
    end
  end

  dynamic_offset = static_size
  offsets_and_static_values = []
  dynamic_values = []

  type.components.each_with_index do |component, i|
    component_type = type.components[i]
    if component_type.dynamic?
      offsets_and_static_values << type(Type.size_type, dynamic_offset)
      dynamic_value = type(component_type, arg.is_a?(Array) ? arg[i] : arg[component_type.name])
      dynamic_values << dynamic_value
      dynamic_offset += dynamic_value.size
    else
      offsets_and_static_values << type(component_type, arg.is_a?(Array) ? arg[i] : arg.fetch(component_type.name))
    end
  end

  offsets_and_static_values.join + dynamic_values.join
end
```

**Change needed:** Update line 192 to use `.bytesize`:

**Find:**
```ruby
      dynamic_offset += dynamic_value.size
```

**Replace with:**
```ruby
      dynamic_offset += dynamic_value.bytesize
```

---

### Task 2.11: Update `Encoder.struct_offsets` to handle binary sizes

**File:** `lib/tron/abi/encoder.rb`

**Current code (around line 209-223):**
```ruby
def struct_offsets(type, arg)
  result = ""
  offset = arg.size
  tails_encoding = arg.map { |a| type(type, a) }
  arg.size.times do |i|
    if i == 0
      offset *= 32
    else
      offset += tails_encoding[i - 1].size
    end
    offset_string = type(Type.size_type, offset)
    result += offset_string
  end
  result
end
```

**Change needed:** Update line 218 to use `.bytesize`:

**Find:**
```ruby
      offset += tails_encoding[i - 1].size
```

**Replace with:**
```ruby
      offset += tails_encoding[i - 1].bytesize
```

---

### Task 2.12: Create encoder_test.rb

**File:** `test/tron/abi/encoder_test.rb` (create new file)

**Full file content:**
```ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../../lib/tron/abi'

module Tron
  module Abi
    class EncoderTest < Minitest::Test
      def test_encode_uint256_returns_binary
        result = Encoder.type(Type.parse('uint256'), 42)
        assert_equal Encoding::ASCII_8BIT, result.encoding
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_encode_uint8
        result = Encoder.type(Type.parse('uint8'), 255)
        assert_equal 32, result.bytesize
        assert_equal '00000000000000000000000000000000000000000000000000000000000000ff', result.unpack1('H*')
      end

      def test_encode_uint256_zero
        result = Encoder.type(Type.parse('uint256'), 0)
        assert_equal 32, result.bytesize
        assert_equal '0' * 64, result.unpack1('H*')
      end

      def test_encode_int256_positive
        result = Encoder.type(Type.parse('int256'), 42)
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_encode_int256_negative
        result = Encoder.type(Type.parse('int256'), -1)
        assert_equal 32, result.bytesize
        assert_equal 'f' * 64, result.unpack1('H*')
      end

      def test_encode_bool_true
        result = Encoder.type(Type.parse('bool'), true)
        assert_equal 32, result.bytesize
        assert_equal '0000000000000000000000000000000000000000000000000000000000000001', result.unpack1('H*')
      end

      def test_encode_bool_false
        result = Encoder.type(Type.parse('bool'), false)
        assert_equal 32, result.bytesize
        assert_equal '0' * 64, result.unpack1('H*')
      end

      def test_encode_string_returns_binary
        result = Encoder.type(Type.parse('string'), 'hello')
        assert_equal Encoding::ASCII_8BIT, result.encoding
        # Length (32 bytes) + padded data (32 bytes) = 64 bytes
        assert_equal 64, result.bytesize

        # Check length encoding (first 32 bytes should encode 5)
        length_hex = result[0, 32].unpack1('H*')
        assert_equal '0000000000000000000000000000000000000000000000000000000000000005', length_hex

        # Check data encoding (next 32 bytes should be "hello" padded)
        data_hex = result[32, 32].unpack1('H*')
        assert_equal '68656c6c6f' + '0' * 54, data_hex
      end

      def test_encode_bytes_returns_binary
        result = Encoder.type(Type.parse('bytes'), 'test')
        assert_equal Encoding::ASCII_8BIT, result.encoding
        assert_equal 64, result.bytesize
      end

      def test_encode_bytes32_fixed
        data = 'a' * 32
        result = Encoder.type(Type.parse('bytes32'), data)
        assert_equal 32, result.bytesize
        assert_equal '61' * 32, result.unpack1('H*')
      end

      def test_encode_address_tron_format
        # Skip if address utilities not available
        skip unless defined?(Tron::Utils::Address)

        address = 'TJRyWwFs9wkrx1UN2bCJNBYFv3nD82H6uq'
        result = Encoder.type(Type.parse('address'), address)
        assert_equal 32, result.bytesize
        assert_equal Encoding::ASCII_8BIT, result.encoding
      end

      def test_encode_static_array
        result = Encoder.type(Type.parse('uint256[3]'), [1, 2, 3])
        assert_equal 96, result.bytesize  # 3 * 32 bytes
        assert_equal Encoding::ASCII_8BIT, result.encoding
      end

      def test_encode_dynamic_array
        result = Encoder.type(Type.parse('uint256[]'), [1, 2, 3])
        # Length (32) + 3 values (96) = 128 bytes
        assert_equal 128, result.bytesize
        assert_equal Encoding::ASCII_8BIT, result.encoding
      end

      def test_encode_value_out_of_bounds
        assert_raises(ValueOutOfBounds) do
          Encoder.type(Type.parse('uint8'), 300)
        end
      end

      def test_encode_wrong_type
        assert_raises(EncodingError) do
          Encoder.type(Type.parse('bool'), 'not a bool')
        end
      end
    end
  end
end
```

**Verification:**
```bash
ruby test/tron/abi/encoder_test.rb
```

All tests should pass.

---

## Phase 3: Decoder Module

**Goal:** Update decoder to accept binary strings for all decoding operations.

### Task 3.1: Update `Decoder.primitive_type` address decoding

**File:** `lib/tron/abi/decoder.rb`

**Current code (around line 115-124):**
```ruby
when "address"
  # Handle TRON-specific address decoding
  # Addresses are 32 bytes (256 bits) with the last 20 bytes being the actual address
  # The TRON prefix is 0x41, so the address part without prefix should be 40 hex chars
  addr_bytes = data[-20..-1]  # Get last 20 bytes
  addr_hex = Util.bin_to_hex(addr_bytes)

  require_relative '../utils/address'
  # Convert 40 hex chars (20 bytes) to TRON address
  Utils::Address.to_base58(Tron::Key::ADDRESS_PREFIX + addr_hex)
```

**No changes needed** - Already works with binary input via `data[-20..-1]`.

---

### Task 3.2: Update `Decoder.primitive_type` for uint/int/bool

**File:** `lib/tron/abi/decoder.rb`

**Current code (around lines 142-168):**
```ruby
when "uint"

  # decoded unsigned integer
  Util.deserialize_big_endian_to_int data
when "int"
  u = Util.deserialize_big_endian_to_int data
  i = u >= 2 ** (type.sub_type.to_i - 1) ? (u - 2 ** 256) : u

  # decoded integer
  i
# ... more cases ...
when "bool"

  # decoded boolean
  data[-1] == ::Tron::Abi::Constant::BYTE_ONE
```

**No changes needed** - `Util.deserialize_big_endian_to_int` now accepts binary. Boolean check works with binary.

---

### Task 3.3: Update `Decoder.type` to use binary slicing

**File:** `lib/tron/abi/decoder.rb`

**Current code (around lines 17-105)** - The entire `type` method needs careful review.

**Key changes needed:**

1. Line 21 - offset reading from binary:
**Find:**
```ruby
l = Util.deserialize_big_endian_to_int arg[0, 32]
```
**Already correct** - `arg[0, 32]` gets 32 bytes of binary, `deserialize_big_endian_to_int` handles it.

2. Line 34 - pointer reading:
**Find:**
```ruby
pointer = Util.deserialize_big_endian_to_int arg[i * 32, 32]
```
**Already correct** - Gets 32 bytes starting at offset `i * 32`.

3. Line 47 - dynamic tuple offset reading:
**Find:**
```ruby
pointer = Util.deserialize_big_endian_to_int arg[offset, 32]
```
**Already correct**.

4. Line 71 - dynamic array offset reading:
**Find:**
```ruby
off = Util.deserialize_big_endian_to_int arg[32 + 32 * i, 32]
```
**Already correct**.

5. Line 88 - static array with dynamic elements:
**Find:**
```ruby
off = Util.deserialize_big_endian_to_int arg[32 * i, 32]
```
**Already correct**.

**Verification:** All offset calculations are already in bytes. No changes needed if `Util.deserialize_big_endian_to_int` works correctly with binary.

---

### Task 3.4: Create decoder_test.rb

**File:** `test/tron/abi/decoder_test.rb` (create new file)

**Full file content:**
```ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../../lib/tron/abi'

module Tron
  module Abi
    class DecoderTest < Minitest::Test
      def test_decode_uint256_from_binary
        # Encode 42 as binary
        binary = Util.zpad_int(42)
        result = Decoder.type(Type.parse('uint256'), binary)
        assert_equal 42, result
      end

      def test_decode_uint8
        binary = Util.zpad_int(255)
        result = Decoder.type(Type.parse('uint8'), binary)
        assert_equal 255, result
      end

      def test_decode_uint256_zero
        binary = Util.zpad_int(0)
        result = Decoder.type(Type.parse('uint256'), binary)
        assert_equal 0, result
      end

      def test_decode_int256_positive
        binary = Util.zpad_int(42)
        result = Decoder.type(Type.parse('int256'), binary)
        assert_equal 42, result
      end

      def test_decode_int256_negative
        binary = Util.zpad_int(-1)
        result = Decoder.type(Type.parse('int256'), binary)
        assert_equal -1, result
      end

      def test_decode_bool_true
        binary = Util.zpad_int(1)
        result = Decoder.type(Type.parse('bool'), binary)
        assert_equal true, result
      end

      def test_decode_bool_false
        binary = Util.zpad_int(0)
        result = Decoder.type(Type.parse('bool'), binary)
        assert_equal false, result
      end

      def test_decode_string_from_binary
        # Manually construct binary: length (5) + "hello" padded to 32 bytes
        length = Util.zpad_int(5)
        data = "hello".b + ("\x00" * 27)
        binary = length + data

        result = Decoder.type(Type.parse('string'), binary)
        assert_equal 'hello', result
      end

      def test_decode_bytes_from_binary
        length = Util.zpad_int(4)
        data = "test".b + ("\x00" * 28)
        binary = length + data

        result = Decoder.type(Type.parse('bytes'), binary)
        assert_equal 'test', result
      end

      def test_decode_bytes32_fixed
        data = ('a' * 32).b + ("\x00" * 0)  # 32 bytes, no padding needed
        binary = data

        result = Decoder.type(Type.parse('bytes32'), binary)
        assert_equal 'a' * 32, result
      end

      def test_decode_static_array
        # Array of 3 uint256s: [1, 2, 3]
        binary = Util.zpad_int(1) + Util.zpad_int(2) + Util.zpad_int(3)
        result = Decoder.type(Type.parse('uint256[3]'), binary)
        assert_equal [1, 2, 3], result
      end

      def test_decode_dynamic_array
        # Array length (3) + three values [1, 2, 3]
        length = Util.zpad_int(3)
        values = Util.zpad_int(1) + Util.zpad_int(2) + Util.zpad_int(3)
        binary = length + values

        result = Decoder.type(Type.parse('uint256[]'), binary)
        assert_equal [1, 2, 3], result
      end

      def test_decode_empty_string
        length = Util.zpad_int(0)
        binary = length

        result = Decoder.type(Type.parse('string'), binary)
        assert_equal '', result
      end

      def test_decode_wrong_data_size
        # Insufficient data for uint256
        binary = "\x00" * 16  # Only 16 bytes instead of 32

        # This might not raise an error but return incorrect results
        # Actual behavior depends on implementation
      end
    end
  end
end
```

**Verification:**
```bash
ruby test/tron/abi/decoder_test.rb
```

All tests should pass.

---

## Phase 4: Public API Layer

**Goal:** Update `Tron::Abi.encode` and `Tron::Abi.decode` to convert between hex and binary at the boundary.

### Task 4.1: Update `Tron::Abi.encode` with corrected offset calculation

**File:** `lib/tron/abi.rb`

**Current code (around lines 27-73):**
```ruby
def self.encode(types, values)
  # Parse the types
  parsed_types = types.map { |t| Type.parse(t) }

  # Split into static and dynamic parts
  static_parts = []
  dynamic_parts = []
  dynamic_offsets = []
  offset_index = 0

  parsed_types.each_with_index do |type, i|
    if type.dynamic?
      # For dynamic types, store a placeholder offset and the actual data
      static_parts << nil  # Placeholder for offset
      dynamic_parts << Encoder.type(type, values[i])
      dynamic_offsets[offset_index] = dynamic_parts.length - 1
      offset_index += 1
    else
      # For static types, encode directly
      static_parts << Encoder.type(type, values[i])
    end
  end

  # Calculate actual offsets for dynamic parts
  # The offset is the position in the encoded result where the dynamic data begins
  # This is after all static parts and offset placeholders for dynamic parts
  static_size = static_parts.compact.map(&:size).sum  # Size of all static parts
  dynamic_offset = static_size  # Start of dynamic data

  # Replace the nil placeholders with actual offsets
  placeholders_replaced = 0
  static_parts.map! do |part|
    if part.nil?
      offset_value = dynamic_offset
      # Update offset for next dynamic part
      dynamic_part_idx = dynamic_offsets[placeholders_replaced]
      dynamic_offset += dynamic_parts[dynamic_part_idx].size
      placeholders_replaced += 1
      Encoder.type(Type.parse('uint256'), offset_value)
    else
      part
    end
  end

  # Combine static and dynamic parts
  static_parts.join + dynamic_parts.join
end
```

**Replace entire method with:**
```ruby
def self.encode(types, values)
  # Parse the types
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

**Key changes:**
1. Fixed static_size calculation: `parsed_types.count * 32` (each parameter slot is 32 bytes)
2. Use `.bytesize` instead of `.size` for binary strings
3. Convert result to hex at the end using `Util.bin_to_hex`

---

### Task 4.2: Update `Tron::Abi.decode` to convert hex to binary at entry

**File:** `lib/tron/abi.rb`

**Current code (around lines 76-109):**
```ruby
def self.decode(types, data)
  # Parse the types
  parsed_types = types.map { |t| Type.parse(t) }

  # Decode each value according to its type
  results = []
  offset = 0

  parsed_types.each do |type|
    if type.dynamic?
      # For dynamic types, read the offset first
      offset_ptr = data[offset, 64]  # 32 bytes = 64 hex chars
      actual_offset = Util.deserialize_big_endian_to_int(offset_ptr)

      # Then decode using the actual offset (convert byte offset to hex char offset)
      decoded_value = Decoder.type(type, data[actual_offset * 2..-1])
      results << decoded_value
      offset += 64  # Move by 64 hex chars (32 bytes) for the offset pointer
    else
      # For static types, decode directly from current offset
      size = type.size  # size in bytes
      if size
        hex_size = size * 2  # convert bytes to hex chars
        decoded_value = Decoder.type(type, data[offset, hex_size])
        results << decoded_value
        offset += hex_size  # Move by the number of hex chars
      else
        raise DecodingError, "Cannot decode static type without size"
      end
    end
  end

  results
end
```

**Replace entire method with:**
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
      offset_value = Util.deserialize_big_endian_to_int(data[offset, 32])
      decoded_value = Decoder.type(type, data[offset_value..-1])
      results << decoded_value
      offset += 32  # Move by 32 bytes
    else
      size = type.size  # Size in bytes
      if size
        decoded_value = Decoder.type(type, data[offset, size])
        results << decoded_value
        offset += size  # Move by size bytes
      else
        raise DecodingError, "Cannot decode static type without size"
      end
    end
  end

  results
end
```

**Key changes:**
1. Convert hex input to binary immediately using `Util.hex_to_bin`
2. Use byte offsets throughout (not hex char offsets)
3. Slice binary data using byte counts: `data[offset, 32]` gets 32 bytes
4. Pass binary data to `Decoder.type`

---

### Task 4.3: Create abi_integration_test.rb

**File:** `test/tron/abi_integration_test.rb` (create new file)

**Full file content:**
```ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../lib/tron/abi'

class AbiIntegrationTest < Minitest::Test
  def test_encode_returns_hex_string
    result = Tron::Abi.encode(['uint256'], [42])
    assert_kind_of String, result
    assert_match(/\A[0-9a-f]+\z/, result)
    assert_equal 64, result.length  # 32 bytes = 64 hex chars
  end

  def test_encode_decode_uint256_round_trip
    original = 42
    encoded = Tron::Abi.encode(['uint256'], [original])
    decoded = Tron::Abi.decode(['uint256'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_multiple_uints
    original = [1, 2, 3]
    encoded = Tron::Abi.encode(['uint256', 'uint256', 'uint256'], original)
    decoded = Tron::Abi.decode(['uint256', 'uint256', 'uint256'], encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_bool_round_trip
    encoded_true = Tron::Abi.encode(['bool'], [true])
    decoded_true = Tron::Abi.decode(['bool'], encoded_true)
    assert_equal [true], decoded_true

    encoded_false = Tron::Abi.encode(['bool'], [false])
    decoded_false = Tron::Abi.decode(['bool'], encoded_false)
    assert_equal [false], decoded_false
  end

  def test_encode_decode_string_round_trip
    original = 'hello'
    encoded = Tron::Abi.encode(['string'], [original])
    decoded = Tron::Abi.decode(['string'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_bytes_round_trip
    original = 'test data'
    encoded = Tron::Abi.encode(['bytes'], [original])
    decoded = Tron::Abi.decode(['bytes'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_static_array_round_trip
    original = [1, 2, 3]
    encoded = Tron::Abi.encode(['uint256[3]'], [original])
    decoded = Tron::Abi.decode(['uint256[3]'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_dynamic_array_round_trip
    original = [1, 2, 3, 4, 5]
    encoded = Tron::Abi.encode(['uint256[]'], [original])
    decoded = Tron::Abi.decode(['uint256[]'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_mixed_static_and_dynamic
    # uint256 (static) + string (dynamic)
    original = [42, 'hello']
    encoded = Tron::Abi.encode(['uint256', 'string'], original)
    decoded = Tron::Abi.decode(['uint256', 'string'], encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_multiple_dynamic_types
    # Two strings (both dynamic)
    original = ['hello', 'world']
    encoded = Tron::Abi.encode(['string', 'string'], original)
    decoded = Tron::Abi.decode(['string', 'string'], encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_complex_mixed
    # uint256 + string + bool + uint256[]
    original = [42, 'hello', true, [1, 2, 3]]
    types = ['uint256', 'string', 'bool', 'uint256[]']
    encoded = Tron::Abi.encode(types, original)
    decoded = Tron::Abi.decode(types, encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_empty_string
    original = ''
    encoded = Tron::Abi.encode(['string'], [original])
    decoded = Tron::Abi.decode(['string'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_empty_array
    original = []
    encoded = Tron::Abi.encode(['uint256[]'], [original])
    decoded = Tron::Abi.decode(['uint256[]'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_zero_values
    original = [0, false, '']
    types = ['uint256', 'bool', 'string']
    encoded = Tron::Abi.encode(types, original)
    decoded = Tron::Abi.decode(types, encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_max_uint256
    original = 2**256 - 1
    encoded = Tron::Abi.encode(['uint256'], [original])
    decoded = Tron::Abi.decode(['uint256'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_negative_int256
    original = -12345
    encoded = Tron::Abi.encode(['int256'], [original])
    decoded = Tron::Abi.decode(['int256'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_known_transfer_function
    # transfer(address,uint256) with test values
    # This is a real-world scenario
    address = 'TJRyWwFs9wkrx1UN2bCJNBYFv3nD82H6uq'
    amount = 1000000

    # Skip if address utilities not available
    skip unless defined?(Tron::Utils::Address)

    encoded = Tron::Abi.encode(['address', 'uint256'], [address, amount])
    decoded = Tron::Abi.decode(['address', 'uint256'], encoded)

    assert_equal address, decoded[0]
    assert_equal amount, decoded[1]
  end

  def test_encode_error_handling
    # Test that encoding wrong types raises errors
    assert_raises(Tron::Abi::EncodingError) do
      Tron::Abi.encode(['bool'], ['not a bool'])
    end
  end

  def test_decode_error_handling
    # Test that decoding invalid data raises errors
    assert_raises(Tron::Abi::DecodingError) do
      Tron::Abi.decode(['string'], '0000')  # Too short
    end
  end
end
```

**Verification:**
```bash
ruby test/tron/abi_integration_test.rb
```

All tests should pass, especially the round-trip tests.

---

## Phase 5: Cleanup and Validation

**Goal:** Remove test duplication and ensure everything works together.

### Task 5.1: Remove duplicate encode/decode from encoder_test.rb

**File:** `test/tron/abi/encoder_test.rb`

**Find and delete** (around lines 32-84):
```ruby
# Include the convenience methods that were defined in the main Abi module
module Tron
  module Abi
    # Convenience method for encoding
    def self.encode(types, values)
      # Parse the types
      parsed_types = types.map { |t| Type.parse(t) }

      # Encode each value according to its type
      encoded_values = []
      parsed_types.each_with_index do |type, i|
        encoded_values << Encoder.type(type, values[i])
      end

      encoded_values.join
    end

    # Convenience method for decoding
    def self.decode(types, data)
      # ... duplicate implementation ...
    end
  end
end
```

**Replace the test to use hex strings:**

Update the existing encoder test file to remove the duplicate module definition and adjust tests if needed.

---

### Task 5.2: Update existing test files to use real module

**Files to check:**
- `test/tron/abi/function_test.rb`
- `test/tron/abi/event_test.rb`
- Any other test files that might have duplicated code

**Action:**
Remove any duplicate `Tron::Abi.encode` or `Tron::Abi.decode` definitions.
Ensure all tests use `require_relative '../../../lib/tron/abi'` to load the real module.

---

### Task 5.3: Run full test suite

**Command:**
```bash
# Run all ABI tests
ruby test/tron/abi/util_test.rb
ruby test/tron/abi/encoder_test.rb
ruby test/tron/abi/decoder_test.rb
ruby test/tron/abi/type_test.rb
ruby test/tron/abi/function_test.rb
ruby test/tron/abi/event_test.rb
ruby test/tron/abi_integration_test.rb
```

**Or if using a test runner:**
```bash
rake test
# or
bundle exec rake test
```

**Expected result:** All tests pass.

**If tests fail:**
1. Read the error message carefully
2. Identify which phase the failure is in (Util, Encoder, Decoder, or API)
3. Review the corresponding task in this plan
4. Fix the issue
5. Re-run tests

**Status:** [x] Completed - All tests pass

---

### Task 5.4: Manual verification with real TRON data

**Script:** Create `test_real_tron.rb` in the project root:

```ruby
#!/usr/bin/env ruby
require_relative 'lib/tron/abi'

puts "Testing TRON ABI Implementation"
puts "=" * 50

# Test 1: Simple uint256
puts "\n1. Testing uint256 encoding/decoding:"
encoded = Tron::Abi.encode(['uint256'], [42])
puts "  Encoded 42: #{encoded}"
decoded = Tron::Abi.decode(['uint256'], encoded)
puts "  Decoded: #{decoded.first}"
puts "  ✓ Pass" if decoded.first == 42

# Test 2: Mixed static and dynamic
puts "\n2. Testing mixed static + dynamic:"
values = [123, 'hello world']
types = ['uint256', 'string']
encoded = Tron::Abi.encode(types, values)
puts "  Encoded [123, 'hello world']: #{encoded[0..63]}..."
decoded = Tron::Abi.decode(types, encoded)
puts "  Decoded: #{decoded.inspect}"
puts "  ✓ Pass" if decoded == values

# Test 3: Multiple dynamic types
puts "\n3. Testing multiple dynamic types:"
values = ['foo', 'bar', 'baz']
types = ['string', 'string', 'string']
encoded = Tron::Abi.encode(types, values)
puts "  Encoded ['foo', 'bar', 'baz']: #{encoded[0..63]}..."
decoded = Tron::Abi.decode(types, encoded)
puts "  Decoded: #{decoded.inspect}"
puts "  ✓ Pass" if decoded == values

# Test 4: Array
puts "\n4. Testing dynamic array:"
values = [[1, 2, 3, 4, 5]]
types = ['uint256[]']
encoded = Tron::Abi.encode(types, values)
puts "  Encoded [1,2,3,4,5]: #{encoded[0..63]}..."
decoded = Tron::Abi.decode(types, encoded)
puts "  Decoded: #{decoded.inspect}"
puts "  ✓ Pass" if decoded == values

puts "\n" + "=" * 50
puts "Manual verification complete!"
```

**Run:**
```bash
chmod +x test_real_tron.rb
./test_real_tron.rb
```

**Expected output:** All tests print "✓ Pass"

---

### Task 5.5: Test with TRON contract (if possible)

If you have access to a TRON testnet:

1. Deploy a simple contract with a function like:
   ```solidity
   function testFunction(uint256 a, string memory b) public returns (uint256) {
       return a;
   }
   ```

2. Encode the function call:
   ```ruby
   function = Tron::Abi::Function.new({
     'name' => 'testFunction',
     'inputs' => [
       {'type' => 'uint256'},
       {'type' => 'string'}
     ]
   })

   encoded = function.encode([42, 'test'])
   puts "Encoded function call: #{encoded}"
   ```

3. Send the transaction to TRON testnet
4. Verify the transaction succeeds and returns expected value

**Note:** This step is optional but highly recommended if you have testnet access.

---

## Final Checklist

Before considering this refactor complete, verify:

- [x] All util tests pass (`ruby test/tron/abi/util_test.rb`)
- [x] All encoder tests pass (`ruby test/tron/abi/encoder_test.rb`)
- [x] All decoder tests pass (`ruby test/tron/abi/decoder_test.rb`)
- [x] All integration tests pass (`ruby test/tron/abi_integration_test.rb`)
- [x] All existing tests still pass (type, function, event)
- [x] Manual verification script runs successfully
- [x] No duplicate `Tron::Abi.encode/decode` in test files
- [x] Encoder returns binary internally
- [x] Decoder accepts binary internally
- [x] Public API uses hex strings (input and output)
- [x] Offset calculations use byte units throughout
- [x] Documentation updated (if any README or doc files exist)
- [x] Git commits are clean and atomic

---

## Rollback Procedure

If something goes wrong and you need to rollback:

1. **Identify the last working phase:**
   ```bash
   git log --oneline
   ```

2. **Rollback to that commit:**
   ```bash
   git reset --hard <commit-hash>
   ```

3. **If you've already pushed to remote:**
   ```bash
   git revert <bad-commit-hash>
   git push
   ```

4. **Review the error and retry:**
   - Read the test failure messages
   - Identify which task caused the issue
   - Review the design document for clarity
   - Make corrections
   - Proceed from that phase

---

## Success Metrics

After completion, you should observe:

1. **Correctness:** All encode/decode operations work correctly for all types
2. **Performance:** Binary operations are faster (measureable in benchmarks)
3. **Maintainability:** Code is cleaner with consistent internal representation
4. **Standards:** Matches Ethereum ABI patterns (helpful for other developers)
5. **Test Coverage:** Comprehensive unit and integration tests
6. **No Duplication:** Tests use the real module, not duplicated code

---

## Support and Questions

If you encounter issues during implementation:

1. **Review the design document:** Most questions are answered there
2. **Check test output:** Error messages usually indicate what's wrong
3. **Verify intermediate steps:** Each phase has verification steps
4. **Use irb for debugging:** Load the module and test methods interactively
5. **Git diff:** Compare your changes against the plan

---

## Completion

Once all tasks are complete and all checks pass:

1. Commit your changes with a descriptive message
2. Update version number (if applicable)
3. Update CHANGELOG (if applicable)
4. Create a pull request (if working in a team)
5. Deploy to production (after thorough review)

**Congratulations on completing the TRON ABI Binary Refactor!**

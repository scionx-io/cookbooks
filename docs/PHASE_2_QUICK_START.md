# Phase 2 Quick Start Guide

**For:** Code generation (Qwen) or human implementation
**Goal:** Copy eth.rb's ABI to tron.rb with minimal changes
**Time:** 2-3 weeks
**Risk:** Low (using proven code)

---

## The One Thing You Must Know

**TRON and Ethereum use IDENTICAL Solidity ABI specification.**

The ONLY difference is address format:
- Ethereum: 20-byte hex (0x + 40 chars)
- TRON: 21-byte hex (41 + 40 chars) encoded as Base58 (T + 33 chars)

Therefore: Copy 95% from eth.rb, modify only address encoding/decoding.

---

## Critical Files to Modify

### 1. Encoder Address Method

**File:** `lib/tron/abi/encoder.rb`
**Location:** Inside `Encoder` class

**Find this:**
```ruby
def address(arg)
  # Ethereum version
end
```

**Replace with:**
```ruby
def address(arg)
  # TRON: Handle Base58 addresses (T...)
  if arg.start_with?('T')
    address_hex = Tron::Utils::Address.to_hex(arg)  # T... → 41...
  else
    address_hex = arg.start_with?('0x') ? arg[2..-1] : arg
  end

  # Verify TRON prefix
  unless address_hex.start_with?('41')
    raise ArgumentError, "Invalid TRON address: #{arg}"
  end

  # Standard ABI: pad to 32 bytes
  [address_hex].pack('H*').rjust(32, BYTE_ZERO)
end
```

### 2. Decoder Address Method

**File:** `lib/tron/abi/decoder.rb`
**Location:** Inside `Decoder` class

**Find this:**
```ruby
def address(data)
  # Ethereum version
end
```

**Replace with:**
```ruby
def address(data)
  # TRON: Extract 21 bytes (41 + 20 bytes)
  address_bytes = data[-21..-1]

  # Verify prefix
  unless address_bytes[0].ord == 0x41
    raise DecodingError, "Invalid TRON address in data"
  end

  # Convert to hex then Base58
  address_hex = Tron::Utils::Crypto.bin_to_hex(address_bytes)
  Tron::Utils::Address.to_base58(address_hex)  # 41... → T...
end
```

### 3. Module Names (All Files)

**Find and replace in ALL copied files:**
```ruby
# BEFORE:
module Eth
  module Abi
    # ...
  end
end

# AFTER:
module Tron
  module Abi
    # ...
  end
end
```

**Also replace:**
- `Eth::` → `Tron::`
- `require 'eth/` → `require 'tron/`
- `Eth.` → `Tron.`

---

## Copy These Files (In Order)

### Step 1: Type System (No modifications needed!)

```bash
# Just copy and rename module
cp eth.rb/lib/eth/abi/type.rb lib/tron/abi/type.rb

# Changes: ONLY module name (Eth → Tron)
# Everything else: IDENTICAL to Ethereum
```

### Step 2: Encoder

```bash
cp eth.rb/lib/eth/abi/encoder.rb lib/tron/abi/encoder.rb

# Changes:
# 1. Module name
# 2. Address method (see above)
# Everything else: IDENTICAL
```

### Step 3: Decoder

```bash
cp eth.rb/lib/eth/abi/decoder.rb lib/tron/abi/decoder.rb

# Changes:
# 1. Module name
# 2. Address method (see above)
# Everything else: IDENTICAL
```

### Step 4: Function & Event (Minimal changes)

```bash
cp eth.rb/lib/eth/abi/function.rb lib/tron/abi/function.rb
cp eth.rb/lib/eth/abi/event.rb lib/tron/abi/event.rb

# Changes:
# - Module name only
# - Function signatures are IDENTICAL (Keccak256 hash)
```

### Step 5: Main Module

Create `lib/tron/abi.rb`:

```ruby
require_relative 'abi/type'
require_relative 'abi/encoder'
require_relative 'abi/decoder'
require_relative 'abi/function'
require_relative 'abi/event'

module Tron
  module Abi
    # Convenience method for encoding
    def self.encode(types, values)
      Encoder.encode(types, values)
    end

    # Convenience method for decoding
    def self.decode(types, data)
      Decoder.decode(types, data)
    end
  end
end
```

---

## Test It Works

```ruby
# Test 1: Encode uint256 (should be identical to Ethereum)
encoded = Tron::Abi.encode(['uint256'], [42])
puts encoded
# => "000000000000000000000000000000000000000000000000000000000000002a"

# Test 2: Encode TRON address (DIFFERENT from Ethereum!)
encoded = Tron::Abi.encode(['address'], ['TYxyz123...'])
puts encoded
# => Should start with 41 after padding zeros

# Test 3: Decode TRON address
data = "\x00" * 11 + [0x41].pack('C') + "\xab" * 20
decoded = Tron::Abi.decode(['address'], data)
puts decoded
# => Should return "T..." Base58 address

# Test 4: Arrays (identical to Ethereum)
encoded = Tron::Abi.encode(['uint256[]'], [[1, 2, 3]])
decoded = Tron::Abi.decode(['uint256[]'], encoded)
puts decoded.inspect
# => [[1, 2, 3]]

# Test 5: Tuples (identical to Ethereum)
encoded = Tron::Abi.encode(['(uint256,bool)'], [[42, true]])
decoded = Tron::Abi.decode(['(uint256,bool)'], encoded)
puts decoded.inspect
# => [[42, true]]
```

---

## Common Pitfalls

### Pitfall 1: Forgetting TRON Address Prefix

```ruby
# WRONG:
address_bytes = data[-20..-1]  # Only 20 bytes

# RIGHT:
address_bytes = data[-21..-1]  # 21 bytes (0x41 + 20)
```

### Pitfall 2: Not Converting Base58 → Hex

```ruby
# WRONG:
def address(arg)
  # Trying to encode Base58 directly
  [arg].pack('H*')
end

# RIGHT:
def address(arg)
  # Convert T... → 41... first
  address_hex = Tron::Utils::Address.to_hex(arg)
  [address_hex].pack('H*').rjust(32, BYTE_ZERO)
end
```

### Pitfall 3: Modifying Type System

```ruby
# DON'T DO THIS:
# Type system is identical - don't modify it!

# DO THIS:
# Copy type.rb exactly, only change module name
```

---

## Validation Checklist

After copying files, verify:

- [ ] `Tron::Abi::Type.parse("uint256")` works
- [ ] `Tron::Abi::Type.parse("address[]")` works
- [ ] `Tron::Abi::Type.parse("(uint256,address)")` works
- [ ] Encoding uint256 produces same result as Ethereum
- [ ] Encoding TRON address (T...) produces 41-prefixed hex
- [ ] Decoding returns TRON address in Base58 format (T...)
- [ ] Arrays work (static and dynamic)
- [ ] Tuples work (simple and nested)

---

## File Structure After Phase 2

```
lib/tron/
├── abi.rb                    # Main module (NEW)
├── abi/
│   ├── type.rb               # From eth.rb, module renamed
│   ├── encoder.rb            # From eth.rb, address method modified
│   ├── decoder.rb            # From eth.rb, address method modified
│   ├── function.rb           # From eth.rb, module renamed
│   ├── event.rb              # From eth.rb, module renamed
│   ├── errors.rb             # New file (error classes)
│   ├── constant.rb           # From eth.rb (optional)
│   └── util.rb               # From eth.rb (optional)
├── services/
│   └── contract.rb           # UPDATE: Use Tron::Abi.encode/decode
└── utils/
    └── abi.rb                # DEPRECATE: Old basic ABI
```

---

## Testing Strategy

### Unit Tests (Copy from eth.rb)

```bash
# Copy test structure
cp -r eth.rb/spec/eth/abi/ test/tron/abi/

# Update in each test file:
# 1. Change Eth → Tron
# 2. Add TRON address tests
# 3. Update module paths
```

### Integration Test

```ruby
# Test with real TRON contract on Shasta
client = Tron::Client.new(network: :shasta)

# Encode TRC20 transfer
to_address = "TAddr123..."
amount = 1000

types = ['address', 'uint256']
values = [to_address, amount]

encoded = Tron::Abi.encode(types, values)

# Should work with TronGrid API
```

---

## Time Estimates

- **Type System:** 2 hours (copy + rename)
- **Encoder:** 4 hours (copy + modify address + test)
- **Decoder:** 4 hours (copy + modify address + test)
- **Function/Event:** 2 hours (copy + rename)
- **Tests:** 8 hours (adapt from eth.rb)
- **Integration:** 4 hours (update services)
- **Documentation:** 4 hours
- **Total:** ~30 hours = 1 week for experienced developer

---

## Success Criteria

Phase 2 is done when:

```ruby
# This complex call works:
addresses = ['TAddr1...', 'TAddr2...', 'TAddr3...']
amounts = [1000, 2000, 3000]

# Encode PaymentSplitter call with arrays
encoded = Tron::Abi.encode(
  ['address[]', 'uint256[]'],
  [addresses, amounts]
)

# Should produce valid ABI-encoded data
assert encoded.length > 0

# Should decode correctly
decoded = Tron::Abi.decode(
  ['address[]', 'uint256[]'],
  encoded
)

assert_equal addresses, decoded[0]
assert_equal amounts, decoded[1]

# Should work with real contract
result = client.contract_service.trigger_contract(
  contract_address: 'TContract...',
  function: 'splitPayment(address[],uint256[])',
  parameters: [addresses, amounts]
)

assert result['result'] == true
```

---

## Key Insight for Implementation

**Remember:** You're not implementing ABI from scratch. You're copying a battle-tested implementation (eth.rb) and making TWO changes:

1. Module names: `Eth` → `Tron`
2. Address format: Add TRON Base58 ↔ hex conversion

Everything else is **identical** because TRON uses the same Solidity compiler and ABI spec as Ethereum.

**Confidence Level:** High - This is a proven approach, low risk.

---

## Resources

- **eth.rb source:** `eth.rb/lib/eth/abi/`
- **Solidity ABI spec:** https://docs.soliditylang.org/en/latest/abi-spec.html
- **TRON address format:** Base58 with 0x41 prefix
- **Phase 1 success:** Transaction `cbb4a203...` on Shasta

---

**Start with type.rb, it's the easiest!** 🚀

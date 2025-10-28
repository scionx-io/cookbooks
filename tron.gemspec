# tron.gemspec
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tron/version'

Gem::Specification.new do |spec|
  spec.name          = 'tron.rb'
  spec.version       = Tron::VERSION
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']

  spec.summary       = 'Ruby wrapper for TRON blockchain APIs'
  spec.description   = 'A Ruby gem for interacting with TRON blockchain APIs, including balance checking, resource information, and token prices.'
  spec.homepage      = 'https://github.com/yourusername/tron'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.0'

  spec.files         = Dir['{lib,bin}/**/*', 'README.md', 'LICENSE']
  spec.bindir        = 'bin'
  spec.executables   = ['tron-wallet']
  spec.require_paths = ['lib']

  spec.add_dependency 'base58-alphabets', '~> 1.0'
  spec.add_dependency 'dotenv', '~> 2.7'
  spec.add_dependency 'keccak', '~> 1.3'       # For keccak256 (replaces digest-sha3)
  spec.add_dependency 'rbsecp256k1', '~> 5.1'  # For signing
  spec.add_dependency 'google-protobuf', '~> 3.22'  # For TRON Protocol Buffer serialization

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
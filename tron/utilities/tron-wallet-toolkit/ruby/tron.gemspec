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

  spec.required_ruby_version = '>= 2.5'

  spec.files         = Dir['{lib,bin}/**/*', 'README.md', 'LICENSE']
  spec.bindir        = 'bin'
  spec.executables   = ['tron-wallet']
  spec.require_paths = ['lib']

  spec.add_dependency 'base58', '~> 0.2'
  spec.add_dependency 'dotenv', '~> 2.7'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
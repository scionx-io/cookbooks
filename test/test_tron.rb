require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/tron'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class TestTron < Minitest::Test
  def test_that_gem_has_a_version
    refute_nil ::Tron::VERSION
  end

  def test_that_version_is_correct_format
    assert_match(/\A\d+\.\d+\.\d+\z/, ::Tron::VERSION)
  end
end
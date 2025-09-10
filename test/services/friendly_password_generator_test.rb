# frozen_string_literal: true

require "test_helper"

class FriendlyPasswordGeneratorTest < ActiveSupport::TestCase
  test "generate returns password with correct format" do
    password = FriendlyPasswordGenerator.generate

    assert_match(/\A[a-z]+\d{2}[a-z]+\z/, password)
  end

  test "generate creates unique passwords" do
    passwords = Array.new(10) { FriendlyPasswordGenerator.generate }

    assert_equal 10, passwords.uniq.length, "All passwords should be unique"
  end

  test "generate uses expected word lists" do
    passwords = Array.new(100) { FriendlyPasswordGenerator.generate }

    adjectives = passwords.map { |p| p.match(/\A([a-z]+)/)[1] }.uniq
    nouns = passwords.map { |p| p.match(/(\d{2})([a-z]+)\z/)[2] }.uniq

    assert_operator adjectives.length, :>, 1
    assert_operator nouns.length, :>, 1
  end
end

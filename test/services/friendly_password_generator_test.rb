# frozen_string_literal: true

require "test_helper"

class FriendlyPasswordGeneratorTest < ActiveSupport::TestCase
  test "generate returns password with correct format" do
    password = FriendlyPasswordGenerator.generate

    assert_match(/\A[a-z]+\d{2}[a-z]+\z/, password)
  end
end

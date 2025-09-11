# frozen_string_literal: true

require "test_helper"

class MemorablePasswordGeneratorTest < ActiveSupport::TestCase
  test "generate returns a password" do
    password = MemorablePasswordGenerator.generate

    assert password.length.positive?
  end
end

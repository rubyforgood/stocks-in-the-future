# frozen_string_literal: true

require "test_helper"

class MemorablePasswordGeneratorTest < ActiveSupport::TestCase
  test "generate returns a password" do
    password = MemorablePasswordGenerator.generate

    assert password.length.positive?
    assert password.match(/^\w+[0-9]+\w+$/)
  end
end

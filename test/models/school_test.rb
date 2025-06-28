# frozen_string_literal: true

require "test_helper"

class SchoolTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:school).validate!
  end
end

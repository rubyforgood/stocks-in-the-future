# frozen_string_literal: true

require "test_helper"

class SchoolYearTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:school_year).validate!
  end
end

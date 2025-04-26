require "test_helper"

class SchoolYearTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:school_year).validate!
  end

  test "destroy" do
    assert school_years(:armistead_elementary_current).destroy!
  end
end

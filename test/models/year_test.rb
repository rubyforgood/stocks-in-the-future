require "test_helper"

class YearTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:year).validate!
  end

  test "destroy" do
    assert years(:current).destroy!
  end

  test "year presence" do
    year = build(:year, year: nil)

    assert_not year.valid?
    assert year.errors.added?(:year, :blank)
  end

  test "year uniqueness" do
    taken_year_value = years(:current).year
    year = build(:year, year: taken_year_value)

    assert_not year.valid?
    assert year.errors.added?(:year, :taken, value: taken_year_value)
  end
end

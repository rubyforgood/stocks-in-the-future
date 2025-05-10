require "test_helper"

class YearTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:year).validate!
  end

  test "year presence" do
    year = build(:year, year: nil)

    assert_not year.valid?
    assert year.errors.added?(:year, :blank)
  end

  test "year uniqueness" do
    duplicate_year = 2025
    create(:year, year: duplicate_year)
    year = build(:year, year: duplicate_year)

    assert_not year.valid?
    assert year.errors.added?(:year, :taken, value: duplicate_year)
  end
end

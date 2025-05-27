require "test_helper"

class YearTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:year).validate!
  end

  test "year presence" do
    year = build(:year, name: nil)

    assert_not year.valid?
    assert year.errors.added?(:name, :blank)
  end

  test "year uniqueness" do
    duplicate_year = "2025 - 2026"
    create(:year, name: duplicate_year)
    year = build(:year, name: duplicate_year)

    assert_not year.valid?
    assert year.errors.added?(:name, :taken, value: duplicate_year)
  end
end

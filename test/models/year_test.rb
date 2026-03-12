# frozen_string_literal: true

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

  test "previous_year and next_year" do
    year2022_to2023 = create(:year, name: "2022 - 2023")
    year2023_to2024 = create(:year, name: "2023 - 2024")
    year2024_to2025 = create(:year, name: "2024 - 2025")

    assert_nil year2022_to2023.previous_year
    assert_equal year2023_to2024, year2022_to2023.next_year

    assert_equal year2022_to2023, year2023_to2024.previous_year
    assert_equal year2024_to2025, year2023_to2024.next_year

    assert_equal year2023_to2024, year2024_to2025.previous_year
    assert_nil year2024_to2025.next_year
  end

  test "current_school_year" do
    create(:year, name: "2025 - 2026")
    create(:year, name: "2026 - 2027")

    feb_date = Date.new(2026, 2, 28)
    assert_equal "2025 - 2026", Year.current_school_year(feb_date).first.name

    sep_date = Date.new(2026, 9, 1)
    assert_equal "2026 - 2027", Year.current_school_year(sep_date).first.name
  end
end

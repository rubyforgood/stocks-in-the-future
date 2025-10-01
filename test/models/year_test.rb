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
    year_2022_2023 = create(:year, name: "2022 - 2023")
    year_2023_2024 = create(:year, name: "2023 - 2024")
    year_2024_2025 = create(:year, name: "2024 - 2025")

    assert_nil year_2022_2023.previous_year
    assert_equal year_2023_2024, year_2022_2023.next_year

    assert_equal year_2022_2023, year_2023_2024.previous_year
    assert_equal year_2024_2025, year_2023_2024.next_year

    assert_equal year_2023_2024, year_2024_2025.previous_year
    assert_nil year_2024_2025.next_year
  end
end

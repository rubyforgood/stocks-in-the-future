# frozen_string_literal: true

# test/models/quarter_test.rb
require "test_helper"

class QuarterTest < ActiveSupport::TestCase
  test "factory is valid and assigns sequential numbers" do
    school_year = build(:school_year)
    q1 = build_stubbed(:quarter, school_year: school_year, number: 1)
    q2 = build_stubbed(:quarter, school_year: school_year, number: 2)
    assert q1.valid?
    assert q2.valid?
    assert_equal 1, q1.number
    assert_equal 2, q2.number
  end

  test "validates presence of number" do
    quarter = build_stubbed(:quarter, number: nil)
    assert_not quarter.valid?
    assert_includes quarter.errors[:number], "can't be blank"
  end

  test "validates inclusion of number in 1..4" do
    %w[0 5 10].each do |bad|
      quarter = build_stubbed(:quarter, number: bad.to_i)
      assert_not quarter.valid?, "#{bad} should be invalid"
      assert_includes quarter.errors[:number], "is not included in the list"
    end
  end

  test "validates uniqueness of number per school_year" do
    school_year = build(:school_year)
    create(:quarter, school_year: school_year, number: 1)
    dup = build(:quarter, school_year: school_year, number: 1)
    assert_not dup.valid?
    assert_includes dup.errors[:number], "has already been taken"
  end

  test "default scope orders by number" do
    school_year = build(:school_year)
    create(:quarter, school_year: school_year, number: 3)
    create(:quarter, school_year: school_year, number: 1)
    assert_equal [1, 3], school_year.quarters.ordered.pluck(:number)
  end

  test "next and previous helpers" do
    school_year = build(:school_year)
    q1 = create(:quarter, school_year: school_year, number: 1)
    q2 = create(:quarter, school_year: school_year, number: 2)
    assert_equal q2, q1.next
    assert_nil q1.previous
    assert_equal q1, q2.previous
    assert_nil q2.next
  end

  test "next and previous across school years" do
    school = build(:school)
    year1 = build(:year, name: "2023 - 2024")
    year2 = build(:year, name: "2024 - 2025")
    sy1 = build(:school_year, school: school, year: year1)
    sy2 = build(:school_year, school: school, year: year2)

    q4_y1 = create(:quarter, school_year: sy1, number: 4)
    q1_y2 = create(:quarter, school_year: sy2, number: 1)

    assert_equal q1_y2, q4_y1.next
    assert_equal q4_y1, q1_y2.previous

    # Edge cases where there is no next/previous year
    year4 = build(:year, name: "2026 - 2027")
    sy4 = build(:school_year, school: school, year: year4)
    q1_y4 = create(:quarter, school_year: sy4, number: 1)
    q4_y4 = create(:quarter, school_year: sy4, number: 4)

    assert_nil q1_y4.previous
    assert_nil q4_y4.next
  end
end

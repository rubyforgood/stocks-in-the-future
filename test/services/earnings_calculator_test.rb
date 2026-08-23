# frozen_string_literal: true

require "test_helper"

# The calculator is pure, so these run on unsaved entries with no grade book, no user
# and no portfolio. Amounts are cents, written as literals for the same reason as in
# distribute_earnings_characterisation_test.rb.
class EarningsCalculatorTest < ActiveSupport::TestCase
  def entry(attributes = {})
    GradeEntry.new(
      { attendance_days: 0, math_grade: nil, reading_grade: nil,
        is_perfect_attendance: false }.merge(attributes)
    )
  end

  test "calculates from unsaved entries and writes nothing" do
    assert_no_changes -> { PortfolioTransaction.count } do
      earnings = EarningsCalculator.execute(entry(attendance_days: 10, math_grade: "A"))

      assert_equal 200, earnings.attendance
      assert_equal 300, earnings.math
    end
  end

  test "attendance is twenty cents a day, plus a dollar for perfect attendance" do
    assert_equal 240, EarningsCalculator.execute(entry(attendance_days: 12)).attendance
    assert_equal 340, EarningsCalculator.execute(entry(attendance_days: 12, is_perfect_attendance: true)).attendance
    assert_equal 0, EarningsCalculator.execute(entry(attendance_days: nil)).attendance
  end

  test "grades pay three dollars for an A band and two for a B band, nothing below" do
    assert_equal 300, EarningsCalculator.execute(entry(math_grade: "A+")).math
    assert_equal 200, EarningsCalculator.execute(entry(math_grade: "B-")).math
    assert_equal 0, EarningsCalculator.execute(entry(math_grade: "C+")).math
    assert_equal 300, EarningsCalculator.execute(entry(reading_grade: "A-")).reading
  end

  test "improvement adds two dollars, per subject" do
    previous = entry(math_grade: "C", reading_grade: "B")
    earnings = EarningsCalculator.execute(entry(math_grade: "B", reading_grade: "B"), previous)

    assert_equal 400, earnings.math
    assert_equal 200, earnings.reading
  end

  test "no previous entry means no improvement" do
    assert_equal 200, EarningsCalculator.execute(entry(math_grade: "B")).math
    assert_equal 200, EarningsCalculator.execute(entry(math_grade: "B"), nil).math
  end

  test "total sums the three categories" do
    earnings = EarningsCalculator.execute(entry(attendance_days: 5, math_grade: "A", reading_grade: "B"))

    assert_equal 100, earnings.attendance
    assert_equal 600, earnings.total
  end

  test "by_reason uses real PortfolioTransaction reasons" do
    by_reason = EarningsCalculator.execute(entry(attendance_days: 1, math_grade: "A", reading_grade: "B")).by_reason

    assert_equal({ attendance_earnings: 20, math_earnings: 300, reading_earnings: 200 }, by_reason)
    assert_empty by_reason.keys.map(&:to_s) - PortfolioTransaction.reasons.keys
  end
end

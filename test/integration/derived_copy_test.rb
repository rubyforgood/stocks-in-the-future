# frozen_string_literal: true

require "test_helper"

# Copy that quotes a number has to derive it, or it becomes a lie the moment the number changes.
#
# design.md records this as a rule and the grade book already follows it - its hint interpolates every figure
# from `GradeEntry`'s constants. This file asserts the property for the other two places a rate reached the
# page, because a wrong figure here is worse than a missing one: a student reading "$1.00 trading fee" plans
# around it.
class DerivedCopyTest < ActionDispatch::IntegrationTest
  include ActionView::Helpers::NumberHelper

  setup do
    classroom = create(:classroom, :with_trading)
    @student = create(:student, :with_portfolio, classroom:)
    @student.reload
    sign_in(@student)
  end

  # The transactions page says what a pending order has and has not done. The fee in that sentence comes from
  # `TRANSACTION_FEE_CENTS`, so changing the constant changes the copy rather than contradicting it.
  test "the transactions page quotes the fee it actually charges" do
    get orders_path

    assert_response :success
    assert_select "main div.min-w-0 > p", /filled every 15 minutes/
    assert_select "main div.min-w-0 > p",
                  /#{Regexp.escape(number_to_currency(PortfolioTransaction::TRANSACTION_FEE_CENTS / 100.0))}/
  end

  # And it is derived, not typed: with a different constant the page must say the different number.
  test "the fee in the copy follows the constant" do
    original = PortfolioTransaction::TRANSACTION_FEE_CENTS
    PortfolioTransaction.send(:remove_const, :TRANSACTION_FEE_CENTS)
    PortfolioTransaction.const_set(:TRANSACTION_FEE_CENTS, 250)

    get orders_path

    assert_response :success
    assert_select "main div.min-w-0 > p", /\$2\.50/
  ensure
    PortfolioTransaction.send(:remove_const, :TRANSACTION_FEE_CENTS)
    PortfolioTransaction.const_set(:TRANSACTION_FEE_CENTS, original)
  end

  # The grade book's hint is the case this rule came from: every figure in it is interpolated from the model's
  # constants, so a teacher cannot be shown a rate the app does not pay.
  test "the grade book hint quotes the rates it pays" do
    classroom = create(:classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    # With a student on the roster: the rates sit on the grades section's header, and an empty grade book
    # renders its empty state instead - a fixture that renders the empty state tests the empty state.
    student = create(:student, :with_portfolio, classroom:)
    grade_book = classroom.grade_books.first
    create(:grade_entry, grade_book:, user: student)
    sign_in(teacher)

    get classroom_grade_book_path(classroom, grade_book)

    assert_response :success
    per_day = number_to_currency(GradeEntry::EARNINGS_PER_DAY_ATTENDANCE / 100.0)

    assert_select "p", { text: /#{Regexp.escape(per_day)}/ },
                  "the grade book states a per-day rate that is not the one GradeEntry pays"
  end
end

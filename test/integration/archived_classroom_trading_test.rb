# frozen_string_literal: true

require "test_helper"

# An archived classroom is not open for trading.
#
# Archiving takes a class out of the teacher's list and stops them opening it - `ClassroomPolicy::Scope` is
# `.active` for a teacher, and `check_classroom_eligibility` redirects a non-admin. It did nothing at all to
# the students in it. Measured before this existed: a student in an archived classroom signed in, opened the
# trading floor and placed a buy. The class was over, the teacher could no longer see it or reach its
# trading switch, and the students went on trading in it.
#
# The switch's own position is still `trading_enabled?` - that is what the admin badge and the classroom
# form show. `trading_open?` is the question a gate asks.
class ArchivedClassroomTradingTest < ActionDispatch::IntegrationTest
  def a_funded_student_in(classroom)
    student = create(:student, :with_portfolio, classroom:, password: "password123")
    student.reload.portfolio.portfolio_transactions.create!(amount_cents: 10_000, transaction_type: :deposit)
    student
  end

  test "a student in an archived classroom cannot place an order" do
    classroom = create(:classroom, :with_trading)
    student = a_funded_student_in(classroom)
    stock = create(:stock, price_cents: 100)
    classroom.update!(archived: true)
    sign_in(student)

    assert_no_difference("Order.count") do
      post orders_path, params: { order: { stock_id: stock.id, shares: 1, action: :buy } }
    end
  end

  test "and is told why, rather than seeing a Buy button that fails" do
    classroom = create(:classroom, :with_trading)
    student = a_funded_student_in(classroom)
    create(:stock)
    classroom.update!(archived: true)
    sign_in(student)

    get stocks_path

    assert_response :success
    assert_select "a", { text: "Buy", count: 0 },
                  "an archived classroom offers no Buy, because the order behind it would be refused"
  end

  test "the same student can trade while the classroom is live" do
    classroom = create(:classroom, :with_trading)
    student = a_funded_student_in(classroom)
    stock = create(:stock, price_cents: 100)
    sign_in(student)

    assert_difference("Order.count", 1) do
      post orders_path, params: { order: { stock_id: stock.id, shares: 1, action: :buy } }
    end
  end

  # The switch and the gate are different questions, and the admin badge reads the switch.
  test "archiving does not move the trading switch itself" do
    classroom = create(:classroom, :with_trading)
    classroom.update!(archived: true)

    assert_predicate classroom, :trading_enabled?
    assert_not classroom.trading_open?
  end
end

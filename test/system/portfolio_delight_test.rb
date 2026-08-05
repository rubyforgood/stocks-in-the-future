# frozen_string_literal: true

require "application_system_test_case"

# The six delight features on the student portfolio, and - as importantly - that each is withheld
# when it has nothing true to say. A card reading "Best month yet: $0.00" is worse than no card.
class PortfolioDelightTest < ApplicationSystemTestCase
  def student_with_history
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    p = student.portfolio
    create(:portfolio_transaction, :deposit, portfolio: p, amount_cents: 100_000)
    create(
      :portfolio_transaction, portfolio: p, transaction_type: :deposit,
                              reason: :attendance_earnings, amount_cents: 1_500
    )
    ko = create(:stock, ticker: "KO", company_name: "Coca-Cola Company", price_cents: 15_000)
    create(:portfolio_stock, portfolio: p, stock: ko, shares: 2)
    create(:portfolio_snapshot, portfolio: p, date: 1.month.ago.to_date, worth_cents: 90_000)
    student
  end

  def new_student
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 2_400)
    student
  end

  test "the headline figure carries a comparison, with its direction spelled out" do
    student = student_with_history
    sign_in(student)

    visit user_portfolio_path(student, student.portfolio)

    within "[data-testid='portfolio-value']" do
      # The sign and the arrow, not only the colour: a loss must not depend on telling red from
      # green. One svg is the trend arrow.
      assert_text(/\+\$[\d,.]+ \([\d.]+%\) since last month/)
      assert_selector "svg"
    end
  end

  test "a new student gets no comparison rather than a change of zero" do
    student = new_student
    sign_in(student)

    visit user_portfolio_path(student, student.portfolio)

    within("[data-testid='portfolio-value']") { assert_no_text "since last month" }
  end

  test "the first-share message shows once and stays dismissed" do
    student = student_with_history
    sign_in(student)

    visit user_portfolio_path(student, student.portfolio)

    assert_selector "[data-testid='first-share']", text: "You own part of a company"

    within("[data-testid='first-share']") { click_on "Dismiss" }

    assert_no_selector "[data-testid='first-share']"

    visit user_portfolio_path(student, student.portfolio)

    # The dismissal has to persist, or it is not a once-ever moment.
    assert_no_selector "[data-testid='first-share']"
  end

  test "the first-share message does not show before there is a share" do
    student = new_student
    sign_in(student)

    visit user_portfolio_path(student, student.portfolio)

    assert_no_selector "[data-testid='first-share']"
  end

  test "the summary sentence reads out the figures already on the page" do
    student = student_with_history
    sign_in(student)

    visit user_portfolio_path(student, student.portfolio)

    assert_text "Your money at work"
    # "1 company", never "1 companies".
    assert_text(/You put \$[\d,.]+ into 1 company,/)
  end

  # The companies a student owns are the holdings table, and there is exactly one of them. A
  # separate card of logos was a second list of the same companies - the duplication this page was
  # rebuilt to remove - and a wall of unlabelled logos only works if you recognise the brands.
  test "a holding is identified by its name as well as its ticker" do
    student = student_with_history
    sign_in(student)

    visit user_portfolio_path(student, student.portfolio)

    within "[data-testid='holdings-table']" do
      assert_text "Coca-Cola Company"
      assert_text "KO"
      # The logo is decorative, because the name is beside it.
      assert_selector "img[alt='']"
    end

    assert_no_text "Companies you own"
  end

  test "the personal best is the student's own, and withheld until they have earned" do
    student = student_with_history
    sign_in(student)
    visit user_portfolio_path(student, student.portfolio)

    assert_selector "[data-testid='best-month']", text: "Best month yet"

    fresh = new_student
    sign_in(fresh)
    visit user_portfolio_path(fresh, fresh.portfolio)

    assert_no_selector "[data-testid='best-month']"
    assert_no_text "Your money at work"
  end

  test "the empty state leads with the student's own balance" do
    student = new_student
    sign_in(student)

    visit user_portfolio_path(student, student.portfolio)

    assert_text "You have $24.00 ready to invest"
    assert_link "See the companies"
  end

  # Someone else's portfolio is not theirs to be invited to spend from.
  test "a teacher viewing a student's portfolio sees the plain empty state" do
    student = new_student
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom: student.classroom)
    sign_in(teacher)

    visit user_portfolio_path(student, student.portfolio)

    assert_text "No holdings yet"
    assert_no_text "ready to invest"
    assert_no_selector "[data-testid='first-share']"
  end
end

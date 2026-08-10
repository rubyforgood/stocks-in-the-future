# frozen_string_literal: true

require "application_system_test_case"

# The trading floor's Held by column, and the sentence that makes it readable.
#
# Before this, a teacher's /stocks was two columns - Company and Last price - because
# StockPolicy#show_holdings? requires a student with a persisted portfolio, so the holdings column and
# the Buy/Sell cell were both removed and what was left was the buy list with the buying taken out.
# Nobody designed that page. A teacher cannot open /admin/stocks either, so it was their only view of
# the catalogue, and nothing in the app aggregated holdings by stock at all.
class ClassHoldingsTest < ApplicationSystemTestCase
  def setup_classroom(name: "Test class")
    classroom = create(:classroom, :with_trading, name:)
    stock = create(
      :stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241,
              stock_exchange: "NYSE", industry: "Beverages"
    )
    [classroom, stock]
  end

  def buy(student, stock, shares)
    student.portfolio.portfolio_stocks.create!(stock:, shares:, purchase_price: stock.current_price)
  end

  def teaching(classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    teacher
  end

  test "a teacher sees who in their classrooms owns each stock, and what the figure counts" do
    classroom, stock = setup_classroom
    owner = create(:student, :with_portfolio, classroom:)
    create(:student, :with_portfolio, classroom:)
    buy(owner.reload, stock, 3)

    sign_in teaching(classroom)
    visit stocks_path

    assert_selector "th", text: "Held by"
    assert_selector "td", text: "1 of 2"
    assert_selector "td", text: "3 shares"

    # The sentence is the point: "1 of 2" is unreadable without knowing which two.
    assert_text "Held by shows how many of your students own each one."
    assert_text "Companies your students can buy shares in right now"
  end

  test "a teacher's figure counts only their own classrooms" do
    mine, stock = setup_classroom(name: "Mine")
    theirs = create(:classroom, :with_trading, name: "Theirs")

    buy(create(:student, :with_portfolio, classroom: mine).reload, stock, 1)
    buy(create(:student, :with_portfolio, classroom: theirs).reload, stock, 5)

    sign_in teaching(mine)
    visit stocks_path

    # One holder of one investor, not two of two: the other classroom is outside ClassroomPolicy::Scope.
    assert_selector "td", text: "1 of 1"
    assert_no_selector "td", text: "2 of 2"
    assert_text "Held by shows how many of your students own each one."
  end

  test "an admin reads the same column across every classroom" do
    mine, stock = setup_classroom(name: "Mine")
    theirs = create(:classroom, :with_trading, name: "Theirs")
    buy(create(:student, :with_portfolio, classroom: mine).reload, stock, 1)
    buy(create(:student, :with_portfolio, classroom: theirs).reload, stock, 5)

    sign_in create(:admin)
    visit stocks_path

    assert_selector "td", text: "2 of 2"
    assert_selector "td", text: "6 shares"
    assert_text "Held by shows how many students own each one, across every classroom."
  end

  test "an archived student is off the roster, so they are off this count too" do
    classroom, stock = setup_classroom
    owner = create(:student, :with_portfolio, classroom:)
    leaver = create(:student, :with_portfolio, classroom:)
    buy(owner.reload, stock, 1)
    buy(leaver.reload, stock, 4)
    leaver.discard

    sign_in teaching(classroom)
    visit stocks_path

    # Classroom#students is scoped `-> { kept }`, so the roster shows one student. A denominator that
    # counted portfolios instead showed "1 of 2" beside a roster of one, and the leaver's four shares
    # were in the total - two numbers for one class, disagreeing.
    assert_selector "td", text: "1 of 1"
    assert_no_selector "td", text: "of 2"
    assert_no_selector "td", text: "5 shares"
  end

  test "one share is one share" do
    classroom, stock = setup_classroom
    owner = create(:student, :with_portfolio, classroom:)
    buy(owner.reload, stock, 1)

    sign_in teaching(classroom)
    visit stocks_path

    assert_selector "td", text: "1 share"
    assert_no_selector "td", text: "1 shares"
  end

  test "a stock nobody owns says so rather than leaving the cell blank" do
    classroom, = setup_classroom
    create(:stock, ticker: "ZZZ", company_name: "Nobody Inc", price_cents: 100)
    create(:student, :with_portfolio, classroom:)

    sign_in teaching(classroom)
    visit stocks_path

    assert_selector "td", text: "None"
  end

  test "a viewer with nobody to count gets no column and no sentence" do
    setup_classroom
    sign_in create(:teacher)
    visit stocks_path

    # A column that can only ever report "None" is not a column - the same rule that removed the
    # trailing column of dashes from a teacher's classrooms table.
    assert_no_selector "th", text: "Held by"
    assert_no_text "Held by shows"
  end

  test "a student's page is unchanged" do
    classroom, stock = setup_classroom
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    buy(student, stock, 2)

    sign_in student
    visit stocks_path

    assert_selector "th", text: "Your holdings"
    assert_no_selector "th", text: "Held by"
    assert_text "Companies you can buy shares in right now"
    assert_selector "a", text: "Buy"
  end

  test "the identity cell carries the exchange and the industry" do
    classroom, = setup_classroom
    create(:student, :with_portfolio, classroom:)

    sign_in teaching(classroom)
    visit stocks_path

    # The header has said "Company (exchange)" since it was written; the cell never held one.
    assert_selector "td", text: "NYSE"
    assert_selector "td", text: "Beverages"
  end

  test "the figure survives a phone, in the primary cell" do
    classroom, stock = setup_classroom
    owner = create(:student, :with_portfolio, classroom:)
    buy(owner.reload, stock, 3)

    sign_in teaching(classroom)

    in_phone_viewport do
      visit stocks_path

      # The trailing columns are hidden at this width, so the figure moves into the cell that is always
      # on screen - the same move a student's holdings line already makes.
      assert_text "Held by 1 of 1 \u00b7 3 shares"

      overflow = page.evaluate_script(
        "document.querySelector('main').scrollWidth - document.querySelector('main').clientWidth"
      )

      assert_equal 0, overflow, "the trading floor scrolls sideways at 375px"
    end
  end
end

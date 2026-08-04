# frozen_string_literal: true

require "application_system_test_case"

# A trade is hard to undo once executed, so the order form now has a review step
# before it submits. These cover the review itself: that it reports the figures
# accurately, that it shows the balance the student will be left with, that going
# back is possible, and that an unaffordable order is flagged before submission
# while still reaching the server for its authoritative check.
class OrderConfirmationTest < ApplicationSystemTestCase
  FEE = PortfolioTransaction::TRANSACTION_FEE_CENTS

  def setup_student(deposit_cents:, price_cents:)
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: deposit_cents)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: price_cents)
    [student, stock]
  end

  test "review step reports shares, total and the balance afterwards" do
    student, stock = setup_student(deposit_cents: 100_000, price_cents: 15_000)
    sign_in(student)

    visit stocks_path
    within "tr", text: stock.company_name do
      click_on "Buy"
    end

    fill_in "Number of shares", with: 2
    click_button "Review order"

    assert_text "Check this is right"

    # 2 shares at $150.00 plus the $1.00 fee is $301.00, leaving $699.00 of $1000.
    within "[data-order-form-target='reviewShares']" do
      assert_text "2"
    end
    within "[data-order-form-target='reviewTotal']" do
      assert_text "$301.00"
    end
    within "[data-order-form-target='reviewBalance']" do
      assert_text "$699.00"
    end

    sign_out(student)
  end

  test "the order is only created after confirming" do
    student, stock = setup_student(deposit_cents: 100_000, price_cents: 15_000)
    sign_in(student)

    visit stocks_path
    within "tr", text: stock.company_name do
      click_on "Buy"
    end

    fill_in "Number of shares", with: 1

    # Reaching the review must not create anything on its own.
    assert_no_difference("Order.count") do
      click_button "Review order"
      assert_text "Check this is right"
    end

    assert_difference("Order.buy.pending.count", +1) do
      click_button "Buy shares"
      assert_text "Order was successfully created"
    end

    sign_out(student)
  end

  test "going back from review allows editing the quantity again" do
    student, stock = setup_student(deposit_cents: 100_000, price_cents: 15_000)
    sign_in(student)

    visit stocks_path
    within "tr", text: stock.company_name do
      click_on "Buy"
    end

    fill_in "Number of shares", with: 4
    click_button "Review order"
    assert_text "Check this is right"

    click_button "Back"
    assert_no_text "Check this is right"

    fill_in "Number of shares", with: 1
    click_button "Review order"

    within "[data-order-form-target='reviewShares']" do
      assert_text "1"
    end

    sign_out(student)
  end

  test "an unaffordable order is flagged at review and still refused by the server" do
    student, stock = setup_student(deposit_cents: 10_000, price_cents: 25_000)
    sign_in(student)

    visit stocks_path
    within "tr", text: stock.company_name do
      click_on "Buy"
    end

    fill_in "Number of shares", with: 1
    click_button "Review order"

    assert_text "That is more than you have available"

    # The warning is a nudge, not a gate: the server remains authoritative.
    assert_no_difference("Order.buy.pending.count") do
      click_button "Buy shares"
      assert_text "Insufficient funds"
    end

    sign_out(student)
  end

  test "selling shows the proceeds added to the balance" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 50_000)
    stock = create(:stock, ticker: "GOOGL", company_name: "Google LLC", price_cents: 10_000)
    create(:portfolio_stock, portfolio: student.portfolio, stock: stock, shares: 5)

    sign_in(student)

    visit stocks_path
    within "tr", text: stock.company_name do
      click_on "Sell"
    end

    fill_in "Number of shares", with: 2
    click_button "Review order"

    # 2 shares at $100.00 is $200.00, less the $1.00 fee that is still withheld,
    # so net proceeds are $199.00. The fee is not added to what you receive.
    assert_text "Check this is right"
    within "[data-order-form-target='reviewTotal']" do
      assert_text "$199.00"
    end

    sign_out(student)
  end
end

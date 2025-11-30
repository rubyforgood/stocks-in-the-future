# frozen_string_literal: true

require "application_system_test_case"

class StudentTradingFlowTest < ApplicationSystemTestCase
  test "student buys a stock" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    shares_to_buy = 2

    sign_in(student)

    visit stocks_path

    assert_text "Trading Floor"
    assert_text stock.ticker
    assert_text stock.company_name

    within "tr", text: stock.company_name do
      click_on "Buy"
    end

    assert_text "Buy #{stock.ticker}"

    fill_in "Number of shares", with: shares_to_buy

    assert_difference("Order.buy.pending.count", +1) do
      click_button "Buy Shares"

      assert_text "Order was successfully created"
    end

    order = Order.buy.pending.find_by(user: student, stock: stock)
    assert_equal shares_to_buy, order.shares
    assert_equal stock.id, order.stock_id
    assert order.buy?
    assert order.pending?

    sign_out(student)
  end

  test "student sells a stock" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio
    stock = create(:stock, ticker: "GOOGL", company_name: "Google LLC", price_cents: 10_000)
    shares_owned = 5
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: shares_owned)
    shares_to_sell = 2

    sign_in(student)

    visit stocks_path

    assert_text "Trading Floor"
    assert_text stock.ticker
    assert_text stock.company_name

    within "tr", text: stock.company_name do
      click_on "Sell"
    end

    assert_text "Sell #{stock.ticker}"

    within "[data-testid='shares-owned-value']" do
      assert_text shares_owned.to_s
    end

    fill_in "Number of shares", with: shares_to_sell

    assert_difference("Order.sell.pending.count", +1) do
      click_button "Sell Shares"

      assert_text "Order was successfully created"
    end

    order = Order.sell.pending.find_by(user: student, stock: stock)
    assert_equal shares_to_sell, order.shares
    assert_equal stock.id, order.stock_id
    assert order.sell?
    assert order.pending?

    sign_out(student)
  end

  test "student updates pending order" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio
    stock = create(:stock, ticker: "TSLA", company_name: "Tesla Inc.", price_cents: 25_000)
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 200_000)

    # create buy order beforehand
    initial_shares = 4
    updated_shares = 2
    order = create(:order, :pending, action: :buy, user: student, stock: stock, shares: initial_shares)

    sign_in(student)

    visit orders_path

    within "tr", text: stock.ticker do
      find("[data-testid='edit-order-button']").click
    end

    fill_in "Number of shares", with: updated_shares

    assert_no_difference("Order.buy.pending.count") do
      click_button "Buy Shares"

      assert_text "Order was successfully updated"
    end

    order.reload
    assert_equal updated_shares, order.shares
    assert order.pending?

    sign_out(student)
  end

  test "student cancels pending order" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio
    stock = create(:stock, ticker: "NFLX", company_name: "Netflix", price_cents: 30_000)
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 150_000)

    # create pending order beforehand
    shares = 3
    order = create(:order, :pending, action: :buy, user: student, stock: stock, shares: shares)

    sign_in(student)

    visit orders_path

    assert_difference -> { Order.pending.count } => -1, -> { Order.canceled.count } => +1 do
      accept_confirm do
        within "tr", text: stock.ticker do
          find("[data-testid='cancel-order-button']").click
        end
      end

      assert_text "Order was successfully canceled"
    end

    order.reload
    assert order.canceled?
    assert_equal shares, order.shares

    sign_out(student)
  end

  test "student cannot buy with insufficient funds" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio
    fund = 10_000
    stock_price = 25_000
    shares_to_buy = 1
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: fund)
    stock = create(:stock, ticker: "TSLA", company_name: "Tesla Inc.", price_cents: stock_price)

    assert stock_price > fund, "cannot buy with insufficient funds"

    sign_in(student)

    visit stocks_path

    within "tr", text: stock.company_name do
      click_on "Buy"
    end

    fill_in "Number of shares", with: shares_to_buy

    assert_no_difference("Order.buy.pending.count") do
      click_button "Buy Shares"

      assert_text "Insufficient funds"
    end

    sign_out(student)
  end

  test "student cannot sell more shares than owned" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio
    stock = create(:stock, ticker: "AMZN", company_name: "Amazon", price_cents: 20_000)
    shares_owned = 3
    shares_to_sell = 5
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: shares_owned)

    assert shares_to_sell > shares_owned, "cannot sell more shares than owned"

    sign_in(student)

    visit stocks_path

    within "tr", text: stock.company_name do
      click_on "Sell"
    end

    within "[data-testid='shares-owned-value']" do
      assert_text shares_owned.to_s
    end

    fill_in "Number of shares", with: shares_to_sell

    assert_no_difference("Order.sell.pending.count") do
      click_button "Sell Shares"

      assert_text "Cannot sell more shares than you own"
    end

    sign_out(student)
  end
end

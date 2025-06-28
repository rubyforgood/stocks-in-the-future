# frozen_string_literal: true

require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio).validate!
  end

  test "#cash_balance" do
    portfolio = create(:portfolio)
    create(:portfolio_transaction, :deposit, portfolio:, amount_cents: 1000)
    create(:portfolio_transaction, :withdrawal, portfolio:, amount_cents: -500)

    result = portfolio.cash_balance

    assert_equal 5.0, result
  end
end

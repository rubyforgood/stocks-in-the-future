require 'test_helper'

class PortfolioTest < ActiveSupport::TestCase
  fixtures :portfolios
  test '#cash_balance' do
    portfolio = portfolios(:one)
    assert_equal BigDecimal('25.50'), portfolio.cash_balance
  end
end

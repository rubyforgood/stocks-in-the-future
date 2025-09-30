# frozen_string_literal: true

require "test_helper"

class PortfolioStockTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio_stock).validate!
  end
end

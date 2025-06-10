# frozen_string_literal: true

require 'test_helper'

class PortfolioTransactionTest < ActiveSupport::TestCase
  test 'factory' do
    assert build(:portfolio_transaction).validate!
  end
end

# frozen_string_literal: true

require 'test_helper'

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  test 'show' do
    portfolio = create(:portfolio)
    sign_in(portfolio.user)

    get portfolio_path(portfolio)

    assert_response :success
  end
end

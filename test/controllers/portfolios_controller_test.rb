require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    portfolio = portfolios(:one)
    get student_portfolio_url(portfolio.user.id)
    assert_response :success
  end
end

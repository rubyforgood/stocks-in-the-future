require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  test "show" do
    portfolio = create(:portfolio)

    get portfolio_path(portfolio)

    assert_response :success
  end
end

require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get portfolios_show_url
    assert_response :success
  end
end

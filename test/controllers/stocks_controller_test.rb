require "test_helper"

class StocksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    admin = create(:admin)
    sign_in admin

    get stocks_url

    assert_response :success
  end

  test "should get show" do
    stock = create(:stock)
    admin = create(:admin)
    sign_in admin

    get stock_url(stock)

    assert_response :success
  end
end

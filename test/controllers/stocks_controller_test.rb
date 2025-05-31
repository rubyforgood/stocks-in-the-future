require "test_helper"

class StocksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    user = create(:user)
    sign_in user

    get stocks_url

    assert_response :success
  end

  test "should get show" do
    stock = create(:stock)
    user = create(:user)
    sign_in user

    get stock_url(stock)

    assert_response :success
  end
end

require "test_helper"

class StocksControllerTest < ActionDispatch::IntegrationTest

  test "should get index" do
    @stock = create(:stock)
    @user = create(:user)
    sign_in @user
    get stocks_url
    assert_response :success
  end

  test "should get show" do
    @stock = create(:stock)
    @user = create(:user)
    sign_in @user
    get stock_url(@stock)
    assert_response :success
  end

  test "should get index json" do
    @stock = create(:stock)
    @user = create(:user)
    sign_in @user
    get stocks_url, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_instance_of Array, json_response
    assert_equal Stock.count, json_response.size
  end

  test "should get show json" do
    @stock = create(:stock)
    @user = create(:user)
    sign_in @user
    get stock_url(@stock), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal @stock.id, json_response["id"]
    assert_equal @stock.ticker, json_response["ticker"]
    assert_equal @stock.stock_exchange, json_response["stock_exchange"]
    assert_equal @stock.company_name, json_response["company_name"]
    assert_equal @stock.company_website, json_response["company_website"]
    assert_not_nil json_response["created_at"]
    assert_not_nil json_response["updated_at"]
    assert_not_nil json_response["url"]
  end
end

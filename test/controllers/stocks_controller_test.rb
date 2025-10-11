# frozen_string_literal: true

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

  test "trade stock button links to trading floor for students" do
    stock = create(:stock)
    student = create(:student)
    create(:portfolio, user: student)
    sign_in student

    get stock_url(stock)

    assert_select "a[href='#{stocks_path}']", text: "Trade Stock"
  end
end

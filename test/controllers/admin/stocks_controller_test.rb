# frozen_string_literal: true

require "test_helper"

module Admin
  class StocksControllerTest < ActionDispatch::IntegrationTest
    test "new" do
      admin = create(:admin)
      sign_in(admin)

      get new_admin_stock_path

      assert_response :success
    end

    test "create" do
      params = { stock: { company_name: "Apple Inc." } }
      admin = create(:admin)
      sign_in(admin)

      assert_difference "Stock.count", 1 do
        post(admin_stocks_path, params:)
      end

      assert_redirected_to admin_stock_path(Stock.last)
      assert_equal "Stock was successfully created.", flash[:notice]
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module AdminV2
  class StocksControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin, admin: true)
      sign_in(@admin)

      @stock1 = Stock.create!(ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000, archived: false)
      @stock2 = Stock.create!(ticker: "GOOGL", company_name: "Alphabet Inc.", price_cents: 14_000, archived: false)
      @stock3 = Stock.create!(ticker: "MSFT", company_name: "Microsoft Corp.", price_cents: 38_000, archived: true)
    end

    # Index tests
    test "should get index" do
      get admin_v2_stocks_path

      assert_response :success
      assert_select "h3", "Stocks"
    end

    test "index shows all stocks" do
      get admin_v2_stocks_path

      assert_response :success
      assert_select "tbody tr", count: 3
    end

    # Show tests
    test "should show stock" do
      get admin_v2_stock_path(@stock1)

      assert_response :success
      assert_select "h2", @stock1.ticker
    end

    test "should show stock price information" do
      get admin_v2_stock_path(@stock1)

      assert_response :success
      assert_select "h3", "Price Information"
      assert_select "dt", text: "Current Price"
    end

    # New tests
    test "should get new" do
      get new_admin_v2_stock_path

      assert_response :success
      assert_select "h1", "New Stock"
    end

    # Create tests
    test "should create stock" do
      assert_difference("Stock.count") do
        post admin_v2_stocks_path, params: {
          stock: {
            ticker: "TSLA",
            company_name: "Tesla Inc.",
            company_website: "https://www.tesla.com",
            price_cents: 25_000,
            yesterday_price_cents: 24_000,
            archived: false
          }
        }
      end

      assert_redirected_to admin_v2_stock_path(Stock.last)
      assert_equal "Stock created successfully.", flash[:notice]
    end

    test "should not create stock with invalid params" do
      assert_no_difference("Stock.count") do
        post admin_v2_stocks_path, params: {
          stock: {
            ticker: "",
            company_name: ""
          }
        }
      end

      assert_response :unprocessable_content
    end

    test "should not create stock with invalid website URL" do
      assert_no_difference("Stock.count") do
        post admin_v2_stocks_path, params: {
          stock: {
            ticker: "TEST",
            company_name: "Test Company",
            company_website: "not-a-valid-url"
          }
        }
      end

      assert_response :unprocessable_content
    end

    # Edit tests
    test "should get edit" do
      get edit_admin_v2_stock_path(@stock1)

      assert_response :success
      assert_select "h1", "Edit Stock"
    end

    # Update tests
    test "should update stock" do
      patch admin_v2_stock_path(@stock1), params: {
        stock: {
          company_name: "Apple Incorporated"
        }
      }

      assert_redirected_to admin_v2_stock_path(@stock1)
      assert_equal "Stock updated successfully.", flash[:notice]
      assert_equal "Apple Incorporated", @stock1.reload.company_name
    end

    test "should not update stock with invalid params" do
      patch admin_v2_stock_path(@stock1), params: {
        stock: {
          ticker: ""
        }
      }

      assert_response :unprocessable_content
    end

    # Destroy tests
    test "should destroy stock" do
      assert_difference("Stock.count", -1) do
        delete admin_v2_stock_path(@stock1)
      end

      assert_redirected_to admin_v2_stocks_path
      assert_equal "Stock deleted successfully.", flash[:notice]
    end

    # Authorization tests
    test "non-admin cannot access index" do
      sign_out(@admin)
      classroom = create(:classroom)
      student = User.create!(username: "student", type: "Student", password: "password", classroom: classroom)
      sign_in(student)

      get admin_v2_stocks_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "non-admin cannot create stock" do
      sign_out(@admin)
      teacher = create(:teacher)
      sign_in(teacher)

      post admin_v2_stocks_path, params: {
        stock: {
          ticker: "TEST",
          company_name: "Test"
        }
      }

      assert_redirected_to root_path
    end
  end
end

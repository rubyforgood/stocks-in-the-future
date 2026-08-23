# frozen_string_literal: true

require "test_helper"

module Admin
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
      get admin_stocks_path

      assert_response :success
      assert_select "h1", "Stocks"
    end

    test "index shows all stocks" do
      get admin_stocks_path

      assert_response :success
      assert_select "tbody tr", count: 3
    end

    # Show tests
    # The company name, not the ticker: a record page's h1 is what the record is called, and the ticker is in
    # the breadcrumb and the form's first field.
    test "should show stock" do
      get admin_stock_path(@stock1)

      assert_response :success
      assert_select "h1", @stock1.company_name
    end

    # **No "Price information" card.** The form edits both prices, so a read-only card of them was the same
    # numbers twice - once changeable and once not. The derived figure, which the form cannot express, is the
    # header's summary line, and the editable values are fields.
    test "the price is a header summary and a pair of fields, not a read-only card" do
      get admin_stock_path(@stock1)

      assert_response :success
      assert_select "h2", text: "Price information", count: 0
      assert_select "p", text: /#{Regexp.escape(ActiveSupport::NumberHelper.number_to_currency(@stock1.current_price))}/
      assert_select "input[name=?]", "stock[price_cents]"
      assert_select "input[name=?]", "stock[yesterday_price_cents]"
    end

    # **The holders fact is a metadata line, not a section.** It was one line in a card at the foot of a
    # 3468px page, so reaching it meant scrolling past seventeen form fields. A section earns a heading when it
    # holds a collection you can scan or act on. Stated either way, because "nobody holds this" is the fact
    # that makes archiving safe.
    test "whether the stock is held is stated in the header, not a section" do
      get admin_stock_path(@stock1)

      assert_select "h2", text: "Held by", count: 0
      assert_select "p", text: /not held by any student/
    end

    test "and it names the number when somebody does hold it" do
      classroom = create(:classroom, :with_trading)
      student = create(:student, :with_portfolio, classroom:)
      create(
        :portfolio_stock, portfolio: student.portfolio, stock: @stock1, shares: 2,
                          purchase_price: @stock1.price_cents
      )

      get admin_stock_path(@stock1)

      assert_select "p", text: /held in 1 portfolio/
    end

    # New tests
    test "should get new" do
      get new_admin_stock_path

      assert_response :success
      assert_select "h1", "New stock"
    end

    # Create tests
    test "should create stock" do
      assert_difference("Stock.count") do
        post admin_stocks_path, params: {
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

      assert_redirected_to admin_stock_path(Stock.last)
      assert_equal "Stock created successfully.", flash[:notice]
    end

    test "should not create stock with invalid params" do
      assert_no_difference("Stock.count") do
        post admin_stocks_path, params: {
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
        post admin_stocks_path, params: {
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
      get edit_admin_stock_path(@stock1)

      assert_response :success
      # The record's page edits in place, so its heading is the record's name.
      assert_select "h1", @stock1.company_name
    end

    # Update tests
    test "should update stock" do
      patch admin_stock_path(@stock1), params: {
        stock: {
          company_name: "Apple Incorporated"
        }
      }

      assert_redirected_to admin_stock_path(@stock1)
      assert_equal "Stock updated successfully.", flash[:notice]
      assert_equal "Apple Incorporated", @stock1.reload.company_name
    end

    test "should not update stock with invalid params" do
      patch admin_stock_path(@stock1), params: {
        stock: {
          ticker: ""
        }
      }

      assert_response :unprocessable_content
    end

    # Destroy tests
    test "should destroy stock" do
      assert_difference("Stock.count", -1) do
        delete admin_stock_path(@stock1)
      end

      assert_redirected_to admin_stocks_path
      assert_equal "Stock deleted successfully.", flash[:notice]
    end

    # Authorization tests
    test "non-admin cannot access index" do
      sign_out(@admin)
      classroom = create(:classroom)
      student = User.create!(username: "student", type: "Student", password: "password", classroom: classroom)
      sign_in(student)

      get admin_stocks_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "non-admin cannot create stock" do
      sign_out(@admin)
      teacher = create(:teacher)
      sign_in(teacher)

      post admin_stocks_path, params: {
        stock: {
          ticker: "TEST",
          company_name: "Test"
        }
      }

      assert_redirected_to root_path
    end
  end
end

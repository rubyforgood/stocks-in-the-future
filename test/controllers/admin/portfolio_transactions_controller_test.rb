# frozen_string_literal: true

require "test_helper"

module Admin
  class PortfolioTransactionsControllerTest < ActionDispatch::IntegrationTest
    # `?user_id=` is where a student record page's truncated list sends you, so it has to narrow the rows and
    # **say that it did**. A page quietly showing one person's transactions under the heading "Portfolio
    # transactions" is the same class of error as a summary describing a bucket it no longer matches.
    test "index narrows to one student and says whose" do
      student = create(:student, name: "Ada Lovelace")
      other = create(:student)
      create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500)
      create(:portfolio_transaction, :deposit, portfolio: other.portfolio, amount_cents: 700)
      sign_in(create(:admin, admin: true, classroom: nil))

      get admin_portfolio_transactions_path(user_id: student.id)

      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "p", text: /Only Ada Lovelace's transactions/
      assert_select "a[href=?]", admin_portfolio_transactions_path, text: "Show all transactions"
    end

    test "index without a filter lists everybody and claims no filter" do
      student = create(:student)
      other = create(:student)
      create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500)
      create(:portfolio_transaction, :deposit, portfolio: other.portfolio, amount_cents: 700)
      sign_in(create(:admin, admin: true, classroom: nil))

      get admin_portfolio_transactions_path

      assert_response :success
      assert_select "tbody tr", count: 2
      assert_select "p", text: /Only/, count: 0
      assert_select "a", text: "Show all transactions", count: 0
    end

    # An id that resolves to nobody is ignored rather than rendered as an empty filtered list - and because
    # the notice is driven by the same object, the page cannot claim a filter it did not apply.
    test "index ignores a user_id that matches nobody" do
      student = create(:student)
      create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500)
      sign_in(create(:admin, admin: true, classroom: nil))

      get admin_portfolio_transactions_path(user_id: 0)

      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "p", text: /Only/, count: 0
    end

    test "show" do
      portfolio = build(:portfolio)
      create(:student, portfolio:)
      portfolio_transaction = create(:portfolio_transaction, portfolio:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_portfolio_transaction_path(portfolio_transaction)

      assert_response :success
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_portfolio_transaction_path

      assert_response :success
    end

    test "create" do
      portfolio = build(:portfolio)
      create(:student, portfolio:)
      params = {
        portfolio_transaction: {
          portfolio_id: portfolio.id,
          transaction_type: "deposit",
          reason: "awards",
          description: "LSP's royal allowance",
          amount_cents: 5000
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("PortfolioTransaction.count") do
        post(admin_portfolio_transactions_path, params:)
      end
      portfolio_transaction = PortfolioTransaction.last

      assert_redirected_to(
        admin_portfolio_transaction_path(portfolio_transaction)
      )
      assert_equal(
        "Portfolio transaction created successfully.",
        flash[:notice]
      )
    end

    test "create with invalid params" do
      params = { portfolio_transaction: { portfolio_id: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("PortfolioTransaction.count") do
        post(admin_portfolio_transactions_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      portfolio = build(:portfolio)
      create(:student, portfolio:)
      portfolio_transaction = create(:portfolio_transaction, portfolio:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_portfolio_transaction_path(portfolio_transaction)

      assert_response :success
    end

    test "update" do
      description = "Finn's dungeon loot"
      amount_cents = 7_500
      portfolio = build(:portfolio)
      create(:student, portfolio:)
      portfolio_transaction = create(:portfolio_transaction, portfolio:)
      params = { portfolio_transaction: { description:, amount_cents: } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_portfolio_transaction_path(portfolio_transaction), params:)
      portfolio_transaction.reload

      assert_redirected_to(
        admin_portfolio_transaction_path(portfolio_transaction)
      )
      assert_equal(
        "Portfolio transaction updated successfully.",
        flash[:notice]
      )
      assert_equal description, portfolio_transaction.description
      assert_equal amount_cents, portfolio_transaction.amount_cents
    end

    test "update with invalid params" do
      portfolio = build(:portfolio)
      create(:student, portfolio:)
      portfolio_transaction = create(:portfolio_transaction, portfolio:)
      params = { portfolio_transaction: { portfolio_id: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_portfolio_transaction_path(portfolio_transaction), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      portfolio = build(:portfolio)
      create(:student, portfolio:)
      portfolio_transaction = create(:portfolio_transaction, portfolio:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("PortfolioTransaction.count", -1) do
        delete admin_portfolio_transaction_path(portfolio_transaction)
      end

      # The transactions list, not the dashboard: a row action returns you to the list you acted from
      assert_redirected_to admin_portfolio_transactions_path
      assert_equal "Portfolio transaction deleted successfully.", flash[:notice]
    end
  end
end

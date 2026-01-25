# frozen_string_literal: true

require "test_helper"

module AdminV2
  class PortfolioTransactionsControllerTest < ActionDispatch::IntegrationTest
    test "show" do
      portfolio = build(:portfolio)
      create(:student, portfolio:)
      portfolio_transaction = create(:portfolio_transaction, portfolio:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_portfolio_transaction_path(portfolio_transaction)

      assert_response :success
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_v2_portfolio_transaction_path

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
        post(admin_v2_portfolio_transactions_path, params:)
      end
      portfolio_transaction = PortfolioTransaction.last

      assert_redirected_to(
        admin_v2_portfolio_transaction_path(portfolio_transaction)
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
        post(admin_v2_portfolio_transactions_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      portfolio = build(:portfolio)
      create(:student, portfolio:)
      portfolio_transaction = create(:portfolio_transaction, portfolio:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_v2_portfolio_transaction_path(portfolio_transaction)

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

      patch(admin_v2_portfolio_transaction_path(portfolio_transaction), params:)
      portfolio_transaction.reload

      assert_redirected_to(
        admin_v2_portfolio_transaction_path(portfolio_transaction)
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

      patch(admin_v2_portfolio_transaction_path(portfolio_transaction), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      portfolio = build(:portfolio)
      create(:student, portfolio:)
      portfolio_transaction = create(:portfolio_transaction, portfolio:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("PortfolioTransaction.count", -1) do
        delete admin_v2_portfolio_transaction_path(portfolio_transaction)
      end

      assert_redirected_to admin_v2_root_path
      assert_equal "Portfolio transaction deleted successfully.", flash[:notice]
    end
  end
end

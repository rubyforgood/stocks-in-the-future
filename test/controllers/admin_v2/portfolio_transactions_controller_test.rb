# frozen_string_literal: true

require "test_helper"

module AdminV2
  class PortfolioTransactionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin)
      @student = create(:student)
      @portfolio = @student.portfolio
      @portfolio_transaction = create(:portfolio_transaction, portfolio: @portfolio)
      sign_in @admin
    end

    test "should get show" do
      get admin_v2_portfolio_transaction_url(@portfolio_transaction)
      assert_response :success
    end

    test "should get new" do
      get new_admin_v2_portfolio_transaction_url
      assert_response :success
    end

    test "should create portfolio_transaction" do
      assert_difference("PortfolioTransaction.count") do
        post admin_v2_portfolio_transactions_url, params: {
          portfolio_transaction: {
            portfolio_id: @portfolio.id,
            transaction_type: "deposit",
            reason: "awards",
            description: "Test transaction",
            amount_cents: 5000
          }
        }
      end

      assert_redirected_to admin_v2_portfolio_transaction_url(PortfolioTransaction.last)
      assert_equal "Portfolio transaction created successfully.", flash[:notice]
    end

    test "should not create portfolio_transaction with invalid params" do
      assert_no_difference("PortfolioTransaction.count") do
        post admin_v2_portfolio_transactions_url, params: {
          portfolio_transaction: {
            portfolio_id: nil,
            transaction_type: nil,
            amount_cents: nil
          }
        }
      end

      assert_response :unprocessable_entity
    end

    test "should get edit" do
      get edit_admin_v2_portfolio_transaction_url(@portfolio_transaction)
      assert_response :success
    end

    test "should update portfolio_transaction" do
      patch admin_v2_portfolio_transaction_url(@portfolio_transaction), params: {
        portfolio_transaction: {
          description: "Updated description",
          amount_cents: 7500
        }
      }

      assert_redirected_to admin_v2_portfolio_transaction_url(@portfolio_transaction)
      assert_equal "Portfolio transaction updated successfully.", flash[:notice]

      @portfolio_transaction.reload
      assert_equal "Updated description", @portfolio_transaction.description
      assert_equal 7500, @portfolio_transaction.amount_cents
    end

    test "should not update portfolio_transaction with invalid params" do
      original_amount = @portfolio_transaction.amount_cents

      patch admin_v2_portfolio_transaction_url(@portfolio_transaction), params: {
        portfolio_transaction: {
          portfolio_id: nil
        }
      }

      assert_response :unprocessable_entity
      @portfolio_transaction.reload
      assert_equal original_amount, @portfolio_transaction.amount_cents
    end

    test "should destroy portfolio_transaction" do
      assert_difference("PortfolioTransaction.count", -1) do
        delete admin_v2_portfolio_transaction_url(@portfolio_transaction)
      end

      assert_redirected_to admin_v2_root_url
      assert_equal "Portfolio transaction deleted successfully.", flash[:notice]
    end

    test "should redirect non-admin users" do
      sign_out @admin
      non_admin = create(:teacher)
      sign_in non_admin

      get admin_v2_portfolio_transaction_url(@portfolio_transaction)
      assert_redirected_to root_url
    end

    test "should require authentication" do
      sign_out @admin

      get admin_v2_portfolio_transaction_url(@portfolio_transaction)
      assert_redirected_to new_user_session_url
    end

    test "should handle different transaction types" do
      %w[deposit withdrawal credit debit fee].each do |type|
        assert_difference("PortfolioTransaction.count") do
          post admin_v2_portfolio_transactions_url, params: {
            portfolio_transaction: {
              portfolio_id: @portfolio.id,
              transaction_type: type,
              amount_cents: 1000
            }
          }
        end

        transaction = PortfolioTransaction.last
        assert_equal type, transaction.transaction_type
      end
    end

    test "should handle different reasons" do
      %w[math_earnings reading_earnings attendance_earnings awards administrative_adjustments].each do |reason|
        assert_difference("PortfolioTransaction.count") do
          post admin_v2_portfolio_transactions_url, params: {
            portfolio_transaction: {
              portfolio_id: @portfolio.id,
              transaction_type: "deposit",
              reason: reason,
              amount_cents: 1000
            }
          }
        end

        transaction = PortfolioTransaction.last
        assert_equal reason, transaction.reason
      end
    end

    test "should allow nil reason" do
      assert_difference("PortfolioTransaction.count") do
        post admin_v2_portfolio_transactions_url, params: {
          portfolio_transaction: {
            portfolio_id: @portfolio.id,
            transaction_type: "deposit",
            reason: nil,
            amount_cents: 1000
          }
        }
      end

      transaction = PortfolioTransaction.last
      assert_nil transaction.reason
    end
  end
end

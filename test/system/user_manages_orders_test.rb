# frozen_string_literal: true

require "application_system_test_case"

class UserManagesOrdersTest < ApplicationSystemTestCase
  # TODO: Add test for creating a new order
  # TODO: Add test for updating an order

  test "canceling an order" do
    student = create(:student)
    sign_in(student)
    portfolio = create(:portfolio, user: student)
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 500_00)
    order = create(:order, :pending, action: :buy, user: student)

    visit orders_path

    accept_confirm do
      within "tr", text: order.stock.company_name do
        find("[data-testid='cancel-order-button']").click
      end
    end

    assert_text "Order was successfully canceled"
    assert_text "Canceled"
  end

  test "canceling an order with modal" do
    student = create(:student)
    sign_in(student)
    portfolio = create(:portfolio, user: student)
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 500_00)
    order = create(:order, :pending, action: :buy, user: student)

    visit orders_path

    accept_confirm do
      within "tr", text: order.stock.company_name do
        find("[data-testid='cancel-order-button']").click
      end
    end

    assert_text "Order was successfully canceled"
    within "tr", text: order.stock.company_name do
      assert_text "Canceled"
    end
  end
end

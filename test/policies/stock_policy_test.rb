# frozen_string_literal: true

require "test_helper"

class StockPolicyTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:stock).validate!
  end

  test "student with portfolio can see holdings and trading links for active stocks" do
    student = create(:student)
    # ensure portfolio created for student factory
    portfolio = create(:portfolio, user: student)
    stock = create(:stock, archived: false)

    assert_permit student, stock, :show_trading_link
    assert_permit student, stock, :show_holdings
  end

  test "student without portfolio cannot see holdings or trading links" do
    # create a student but do not create a portfolio for them
    student = create(:student)
    # remove any auto-created portfolio if present
    student.portfolio&.destroy

    stock = create(:stock, archived: false)

    refute_permit student, stock, :show_trading_link
    refute_permit student, stock, :show_holdings
  end

  test "teacher and admin cannot see trading links or holdings" do
    teacher = create(:teacher)
    admin = create(:admin)
    stock = create(:stock, archived: false)

    refute_permit teacher, stock, :show_trading_link
    refute_permit teacher, stock, :show_holdings

    refute_permit admin, stock, :show_trading_link
    refute_permit admin, stock, :show_holdings
  end

  test "archived stock hides trading links even for students with portfolio" do
    student = create(:student)
    create(:portfolio, user: student)
    stock = create(:stock, archived: true)

    refute_permit student, stock, :show_trading_link
    # holdings may still be shown depending on policy; our policy hides only trading links
    assert_permit student, stock, :show_holdings
  end
end

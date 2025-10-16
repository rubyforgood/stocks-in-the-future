# frozen_string_literal: true

require "test_helper"

class OrderPolicyTest < ActiveSupport::TestCase
  test "index?" do
    order = build(:order, :buy)

    assert_permit create(:admin), order, :index
    assert_permit create(:teacher), order, :index
    assert_permit create(:student), order, :index
    refute_permit nil, order, :index
  end

  test "create? allows user to create order for their own portfolio" do
    student = create(:student)
    order = build(:order, :buy, user: student)

    assert_permit student, order, :create
  end

  test "create? denies user from creating order for another user's portfolio" do
    student1 = create(:student)
    student2 = create(:student)
    order = build(:order, :buy, user: student2)

    refute_permit student1, order, :create
  end

  test "update? allows user to update their own order" do
    stock = create(:stock)
    student = create(:student)
    portfolio = create(:portfolio, user: student)
    create(:portfolio_stock, portfolio:, shares: 10, stock:)
    order = create(:order, :sell, user: student, stock:)

    assert_permit student, order, :update
  end

  test "update? denies user from updating another user's order" do
    stock = create(:stock)
    student1 = create(:student)
    student2 = create(:student)
    portfolio = create(:portfolio, user: student2)
    create(:portfolio_stock, portfolio:, stock:, shares: 10)
    order = create(:order, :sell, user: student2, stock:)

    refute_permit student1, order, :update
  end

  test "cancel? allows user to cancel their own order" do
    stock = create(:stock)
    student = create(:student)
    portfolio = create(:portfolio, user: student)
    create(:portfolio_stock, portfolio:, stock:, shares: 10)
    order = create(:order, :sell, user: student, stock:)

    assert_permit student, order, :cancel
  end

  test "cancel? denies user from canceling another user's order" do
    stock = create(:stock)
    student1 = create(:student)
    student2 = create(:student)
    portfolio = create(:portfolio, user: student2)
    create(:portfolio_stock, portfolio:, stock:, shares: 10)
    order = create(:order, :sell, user: student2, stock:)

    refute_permit student1, order, :cancel
  end

  test "Scope#resolve calls scope.all for admin" do
    admin = create(:admin)

    Order.expects(:all)

    OrderPolicy::Scope.new(admin, Order).resolve
  end

  test "Scope#resolve calls scope.for_student for student" do
    student = create(:student)

    Order.expects(:for_student).with(student)

    OrderPolicy::Scope.new(student, Order).resolve
  end

  test "Scope#resolve calls scope.for_teacher for teacher" do
    teacher = create(:teacher)

    Order.expects(:for_teacher).with(teacher)

    OrderPolicy::Scope.new(teacher, Order).resolve
  end

  test "Scope#resolve calls scope.none for nil user" do
    Order.expects(:none)

    OrderPolicy::Scope.new(nil, Order).resolve
  end

  test "Scope#resolve calls scope.none for user without recognized role" do
    user = build(:student)
    user.stubs(:student?).returns(false)

    Order.expects(:none)

    OrderPolicy::Scope.new(user, Order).resolve
  end
end

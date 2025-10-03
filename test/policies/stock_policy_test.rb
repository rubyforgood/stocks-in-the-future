# frozen_string_literal: true

require "test_helper"

class StockPolicyTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:stock).validate!
  end

  test "student with portfolio can see holdings and trading links for active stocks" do
    student = create(:student)
    # ensure portfolio created for student factory
    create(:portfolio, user: student)
    stock = create(:stock, archived: false)

    assert_permit student, stock, :show_trading_link
    assert_permit student, stock, :show_holdings
  end

  test "student without portfolio cannot see holdings or trading links" do
    # create a student but do not create a portfolio for them
    student = create(:student)
    # remove any auto-created portfolio if present
    student.portfolio&.destroy
    student.association(:portfolio).reset

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
  test "index? allows any logged-in user and denies guests" do
    stock = build(:stock)

    assert_permit create(:admin), stock, :index
    assert_permit create(:teacher), stock, :index
    assert_permit create(:student), stock, :index

    refute_permit nil, stock, :index
  end

  test "show? allows admins and teachers to view any stock" do
    active_stock = create(:stock, archived: false)
    archived_stock = create(:stock, archived: true)

    admin = create(:admin)
    teacher = create(:teacher)

    assert_permit admin, active_stock, :show
    assert_permit admin, archived_stock, :show

    assert_permit teacher, active_stock, :show
    assert_permit teacher, archived_stock, :show
  end

  test "show? allows students to view all stocks and denies guests" do
    active_stock = create(:stock, archived: false)
    archived_stock = create(:stock, archived: true)

    student = create(:student)

    assert_permit student, active_stock, :show
    assert_permit student, archived_stock, :show

    refute_permit nil, active_stock, :show
    refute_permit nil, archived_stock, :show
  end

  test "CRUD actions are allowed only for admins" do
    stock = build(:stock)

    admin = create(:admin)
    teacher = create(:teacher)
    student = create(:student)

    %i[new create edit update destroy].each do |action|
      assert_permit admin, stock, action

      refute_permit teacher, stock, action
      refute_permit student, stock, action
      refute_permit nil, stock, action
    end
  end

  test "Scope resolves: admins and teachers see all; others see active only" do
    admin = create(:admin)
    teacher = create(:teacher)
    student = create(:student)

    active1 = create(:stock, archived: false)
    active2 = create(:stock, archived: false)
    archived = create(:stock, archived: true)

    admin_scope = StockPolicy::Scope.new(admin, Stock.all).resolve
    assert_includes admin_scope, active1
    assert_includes admin_scope, active2
    assert_includes admin_scope, archived

    teacher_scope = StockPolicy::Scope.new(teacher, Stock.all).resolve
    assert_includes teacher_scope, active1
    assert_includes teacher_scope, active2
    assert_includes teacher_scope, archived

    student_scope = StockPolicy::Scope.new(student, Stock.all).resolve
    assert_includes student_scope, active1
    assert_includes student_scope, active2
    assert_not_includes student_scope, archived

    guest_scope = StockPolicy::Scope.new(nil, Stock.all).resolve
    assert_includes guest_scope, active1
    assert_includes guest_scope, active2
    assert_not_includes guest_scope, archived
  end
end

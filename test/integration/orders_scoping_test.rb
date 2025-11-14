# frozen_string_literal: true

require "test_helper"

class OrdersScopingTest < ActionDispatch::IntegrationTest
  test "student sees only their own orders" do
    stock = create(:stock, price_cents: 1_000)
    classroom = create(:classroom, :with_trading)
    student1, order1 = create_student_and_order(stock, classroom)
    _student2, order2 = create_student_and_order(stock, classroom)
    sign_in(student1)

    get orders_path

    assert_response :success
    assert_select "tr##{dom_id(order1)}"
    assert_select "tr##{dom_id(order2)}", count: 0
  end

  test "teacher sees orders from students in their classrooms" do
    stock = create(:stock, price_cents: 1_000)
    classroom1, order1 = create_classroom_and_student_order(stock)
    _classroom2, order2 = create_classroom_and_student_order(stock)
    classroom3, order3 = create_classroom_and_student_order(stock)
    teacher = create(:teacher, classrooms: [classroom1, classroom3])
    sign_in(teacher)

    get orders_path

    assert_response :success
    assert_select "tr##{dom_id(order1)}"
    assert_select "tr##{dom_id(order3)}"
    assert_select "tr##{dom_id(order2)}", count: 0
  end

  test "admin sees all orders" do
    admin = create(:admin)
    stock = create(:stock, price_cents: 1_000)
    _classroom1, order1 = create_classroom_and_student_order(stock)
    _classroom2, order2 = create_classroom_and_student_order(stock)
    sign_in(admin)

    get orders_path

    assert_response :success
    assert_select "tr##{dom_id(order1)}"
    assert_select "tr##{dom_id(order2)}"
  end

  test "user with no orders sees empty list" do
    stock = create(:stock, price_cents: 1_000)
    create_classroom_and_student_order(stock)
    student = create(:student)
    sign_in(student)

    get orders_path

    assert_response :success
    assert_select "tr[data-testid='no-orders']"
  end

  test "teacher with no classrooms sees no orders" do
    stock = create(:stock, price_cents: 1_000)
    create_classroom_and_student_order(stock)
    teacher = create(:teacher, classrooms: [])
    sign_in(teacher)

    get orders_path

    assert_response :success
    assert_select "tr[data-testid='no-orders']"
  end

  private

  def create_classroom_and_student_order(stock)
    classroom = create(:classroom, :with_trading)
    _student, order = create_student_and_order(stock, classroom)

    [classroom, order]
  end

  def create_student_and_order(stock, classroom)
    student = create(:student, classroom:)
    portfolio = create(:portfolio, user: student)
    create(:portfolio_transaction, :deposit, portfolio:, amount_cents: 10_000)
    order = create(:order, :buy, user: student, stock:)

    [student, order]
  end
end

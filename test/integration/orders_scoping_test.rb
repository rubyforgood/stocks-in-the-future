# frozen_string_literal: true

require "test_helper"

class OrdersScopingTest < ActionDispatch::IntegrationTest
  test "student sees only their own orders" do
    stock = create(:stock)
    classroom = create(:classroom)
    student1 = create(:student, classroom: classroom)
    portfolio1 = create(:portfolio, user: student1)
    create(
      :portfolio_transaction,
      :deposit,
      portfolio: portfolio1,
      amount_cents: 50_000
    )
    order1 = create(:order, :buy, user: student1, stock:)
    student2 = create(:student, classroom: classroom)
    portfolio2 = create(:portfolio, user: student2)
    create(
      :portfolio_transaction,
      :deposit,
      portfolio: portfolio2,
      amount_cents: 50_000
    )
    order2 = create(:order, :buy, user: student2, stock:)
    sign_in(student1)

    get orders_path

    assert_response :success
    assert_select "tr##{dom_id(order1)}"
    assert_select "tr##{dom_id(order2)}", count: 0
  end

  test "teacher sees orders from students in their classrooms" do
    stock = create(:stock)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)
    classroom3 = create(:classroom)
    teacher = create(:teacher, classrooms: [classroom1, classroom3])
    student1 = create(:student, classroom: classroom1)
    portfolio1 = create(:portfolio, user: student1)
    create(
      :portfolio_transaction,
      :deposit,
      portfolio: portfolio1,
      amount_cents: 50_000
    )
    order1 = create(:order, :buy, user: student1, stock:)
    student2 = create(:student, classroom: classroom2)
    portfolio2 = create(:portfolio, user: student2)
    create(
      :portfolio_transaction,
      :deposit,
      portfolio: portfolio2,
      amount_cents: 50_000
    )
    order2 = create(:order, :buy, user: student2, stock:)
    student3 = create(:student, classroom: classroom3)
    portfolio3 = create(:portfolio, user: student3)
    create(
      :portfolio_transaction,
      :deposit,
      portfolio: portfolio3,
      amount_cents: 50_000
    )
    order3 = create(:order, :buy, user: student3, stock:)
    sign_in(teacher)

    get orders_path

    assert_response :success
    assert_select "tr##{dom_id(order1)}"
    assert_select "tr##{dom_id(order3)}"
    assert_select "tr##{dom_id(order2)}", count: 0
  end

  test "admin sees all orders" do
    admin = create(:admin)
    stock = create(:stock)
    classroom1 = create(:classroom)
    student1 = create(:student, classroom: classroom1)
    portfolio1 = create(:portfolio, user: student1)
    create(
      :portfolio_transaction,
      :deposit,
      portfolio: portfolio1,
      amount_cents: 50_000
    )
    order1 = create(:order, :buy, user: student1, stock:)
    classroom2 = create(:classroom)
    student2 = create(:student, classroom: classroom2)
    portfolio2 = create(:portfolio, user: student2)
    create(
      :portfolio_transaction,
      :deposit,
      portfolio: portfolio2,
      amount_cents: 50_000
    )
    order2 = create(:order, :buy, user: student2, stock:)
    sign_in(admin)

    get orders_path

    assert_response :success
    assert_select "tr##{dom_id(order1)}"
    assert_select "tr##{dom_id(order2)}"
  end

  test "user with no orders sees empty list" do
    student = create(:student)
    sign_in(student)

    get orders_path

    assert_response :success
    assert_select "tr[data-testid='no-orders']"
  end

  test "teacher with no classrooms sees no orders" do
    teacher = create(:teacher, classrooms: [])
    sign_in(teacher)

    get orders_path

    assert_response :success
    assert_select "tr[data-testid='no-orders']"
  end
end
